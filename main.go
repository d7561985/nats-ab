package main

import (
	"context"
	"log"
	"time"

	"github.com/caarlos0/env/v6"
	"github.com/d7561985/nats-ab/internal/config"
	"github.com/d7561985/tel/v2"
	_ "github.com/joho/godotenv/autoload"
	"github.com/nats-io/nats.go"
)

const (
	DrainTimeOut = time.Minute * 2
)

func main() {
	cfg := config.Nats{}
	if err := env.Parse(&cfg); err != nil {
		log.Fatalf("config loading: %v", err)
	}

	l, exit := tel.New(context.Background(), tel.DefaultDebugConfig())
	defer exit()

	ctx := l.Ctx()

	closer := createStream(ctx, cfg)
	defer closer()

	performTest(ctx, cfg)
}

const (
	STREAM   = "ORDERS"
	CONSUMER = "MONITOR"
)

func createStream(ctx context.Context, cfg config.Nats) func() {
	l := tel.FromCtx(ctx).With(
		tel.String("context", "admin"),
		tel.String("stream", STREAM),
		tel.String("consumer", CONSUMER),
	)

	// Connect to NATS
	nc, err := nats.Connect(cfg.Addr,
		nats.UserInfo(cfg.StreamAdmin.User, cfg.StreamAdmin.UserPassword))

	if err != nil {
		l.Fatal("connect", tel.Error(err))
	}

	// Create JetStream Context
	js, err := nc.JetStream()
	if err != nil {
		l.Fatal("js", tel.Error(err))
	}

	// Create a Stream
	_, err = js.AddStream(&nats.StreamConfig{
		Name:     STREAM,
		Subjects: []string{STREAM + ".*"},
	})
	if err != nil {
		l.Fatal("create stream", tel.Error(err))
	}

	// Create a Consumer
	_, err = js.AddConsumer(STREAM, &nats.ConsumerConfig{
		Durable:   CONSUMER,
		AckPolicy: nats.AckExplicitPolicy,
	})

	if err != nil {
		l.Fatal("create consumer", tel.Error(err))
	}

	return func() {
		<-time.After(cfg.DrainTime)

		l.Info("drain begin")

		// Delete Consumer
		if err = js.DeleteConsumer(STREAM, CONSUMER); err != nil {
			l.Fatal("delete consumer", tel.Error(err))
		}

		// Delete Stream
		if err = js.DeleteStream(STREAM); err != nil {
			l.Fatal("delete stream", tel.Error(err))
		}
	}
}

func performTest(ctx context.Context, cfg config.Nats) {
	l := tel.FromCtx(ctx).With(
		tel.String("context", "client"),
		tel.String("stream", STREAM),
		tel.String("consumer", CONSUMER),
	)

	nc, err := nats.Connect(cfg.Addr,
		nats.DrainTimeout(DrainTimeOut),
		nats.UserInfo(cfg.Client.User, cfg.Client.UserPassword),
	)
	if err != nil {
		l.Fatal("nats connection", tel.Error(err))
	}

	// Create JetStream Context
	js, err := nc.JetStream(nats.PublishAsyncMaxPending(256))
	if err != nil {
		l.Fatal("js", tel.Error(err))
	}

	// Simple Async Stream Publisher
	for i := 0; i < cfg.Count; i++ {
		// or via js explicitly publish to stream
		_, err = js.PublishAsync(STREAM+".received", []byte("hello"), nats.ExpectStream("ORDERS"))
		if err != nil {
			l.Fatal("publish", tel.Error(err))
		}
	}

	select {
	case <-js.PublishAsyncComplete():
	case <-time.After(5 * time.Second):
		l.Fatal("Did not resolve in time")
	}

	// Simple Pull Consumer
	sub, err := js.PullSubscribe(STREAM+".received", CONSUMER,
		nats.Bind(STREAM, CONSUMER))
	if err != nil {
		l.Fatal("pull", tel.Error(err))
	}

	// Unsubscribe
	defer sub.Unsubscribe()

	// Drain
	defer sub.Drain()

	bs := cfg.Count / 100

	for i := 0; i < bs; i++ {
		l.Info("batch", tel.Int("n", i))

		msgs, err := sub.Fetch(100, nats.MaxWait(time.Second*30))
		if err != nil {
			l.Fatal("fetch", tel.Error(err))
		}

		if len(msgs) == 0 {
			l.Fatal("not fetched msgs")
		}

		for _, msg := range msgs {
			l.Info(string(msg.Data))
			if err = msg.Ack(); err != nil {
				l.Fatal("ack", tel.Error(err))
			}
		}
	}
}
