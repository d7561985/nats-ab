package basic

import (
	"context"
	"fmt"
	"io/ioutil"
	"os"
	"sync"
	"sync/atomic"
	"text/tabwriter"
	"time"

	"github.com/d7561985/nats-ab/internal/config"
	"github.com/d7561985/tel/v2"
	"github.com/nats-io/nats.go"
	"github.com/nats-io/nats.go/bench"
	"github.com/pkg/errors"
	"golang.org/x/text/language"
	"golang.org/x/text/message"
)

const (
	DrainTimeOut = time.Minute * 2
)

const (
	STREAM                 = "ORDERS"
	CONSUMER               = "MONITOR"
	SystemPhaserPubSubject = "COMPLIANCE_PHASE_PUB"
	SystemPhaserSubSubject = "COMPLIANCE_PHASE_SUB"
)

func Run(ctx context.Context, cfg config.Nats) {
	closer := createStream(ctx, cfg)
	defer closer()

	Create(cfg).performTest(ctx)
}

func createStream(ctx context.Context, cfg config.Nats) func() {
	l := tel.FromCtx(ctx).With(
		tel.String("context", "admin"),
		tel.String("stream", STREAM),
		tel.String("consumer", CONSUMER),
	)

	// Connect Options.
	opts := []nats.Option{
		nats.Name("NATS Benchmark"),
		nats.DrainTimeout(DrainTimeOut),
	}

	if len(cfg.StreamAdmin.User) > 0 {
		opts = append(opts, nats.UserInfo(cfg.StreamAdmin.User, cfg.StreamAdmin.UserPassword))
	}

	nc, err := nats.Connect(cfg.Addr, opts...)

	if err != nil {
		l.Fatal("connect", tel.String("context", "nats connection"), tel.Error(err))
	}

	js, err := nc.JetStream(nats.PublishAsyncMaxPending(256))
	if err != nil {
		l.Fatal("JS", tel.String("context", "js context creation"), tel.Error(err))
	}

	cb := func() {}

	if cfg.CreateStream {
		// Create a Stream
		_, err = js.AddStream(&nats.StreamConfig{
			Name:     STREAM,
			Subjects: []string{STREAM + ".*"},
			Replicas: cfg.Replicas,
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

		cb = func() {
			l.Info("drain begin")
			<-time.After(cfg.DrainTime)

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

	return cb
}

type basic struct {
	cfg config.Nats

	benchmark *bench.Benchmark
	numSubs   int
	numPubs   int

	subTotalMsg uint64
	pubTotalMsg uint64
}

func Create(cfg config.Nats) *basic {
	var numSubs, numPubs int
	switch cfg.Mode {
	case 1:
		numPubs = cfg.Threads
	case 2:
		numSubs = cfg.Threads
	case 0:
		numSubs = cfg.Threads
		numPubs = cfg.Threads
	default:
		panic(fmt.Sprintf("mode %d not supported", cfg.Mode))
	}

	benchmark := bench.NewBenchmark("NATS", numSubs, numPubs)

	return &basic{
		cfg:       cfg,
		benchmark: benchmark,
		numPubs:   numPubs,
		numSubs:   numSubs,
	}
}

func (b *basic) performTest(ctx context.Context) {
	l := tel.FromCtx(ctx).With(
		tel.String("context", "client"),
		tel.String("stream", STREAM),
		tel.String("consumer", CONSUMER),
	)

	// Connect Options.
	opts := []nats.Option{
		nats.Name("NATS Benchmark"),
		nats.DrainTimeout(DrainTimeOut),
	}

	if len(b.cfg.Client.User) > 0 {
		opts = append(opts, nats.UserInfo(b.cfg.Client.User, b.cfg.Client.UserPassword))
	}

	var startwg sync.WaitGroup
	var donewg sync.WaitGroup

	donewg.Add(b.numSubs + b.numPubs)

	// Run Subscribers first
	startwg.Add(b.numSubs)

	for i := 0; i < b.numSubs; i++ {
		nc, err := nats.Connect(b.cfg.Addr, opts...)
		if err != nil {
			l.Fatal("connect", tel.String("context", "nats connection"), tel.Error(err))
		}

		go b.runSubscriber(ctx, nc, STREAM+".received",
			&startwg, &donewg, b.cfg.Count, b.cfg.MsgSize)
	}

	// Now Publishers
	startwg.Add(b.numPubs)
	//pubCounts := bench.MsgsPerClient(b.cfg.Count, b.numPubs)

	for i := 0; i < b.numPubs; i++ {
		nc, err := nats.Connect(b.cfg.Addr, opts...)
		if err != nil {
			l.Fatal("connect", tel.String("context", "nats connection"), tel.Error(err))
		}

		go b.runPublisher(ctx, nc, STREAM+".received",
			&startwg, &donewg, b.cfg.Count, b.cfg.MsgSize)
	}

	startwg.Wait()

	done := make(chan struct{}, 1)
	msg := message.NewPrinter(language.AmericanEnglish)

	go func() {
		l.Info("in progress")

		x := time.After(time.Second * 30)

		for {
			select {
			case <-ctx.Done():
				l.Info("worker exit")
				return
			case <-done:
				return
			case <-time.After(time.Second * 5):
				fmt.Printf(".")
			case <-x:
				x = time.After(time.Second * 30)

				print(msg.Sprintf("sub: %d, pub: %d", b.subTotalMsg, b.pubTotalMsg))

				if b.benchmark.Pubs.HasSamples() {
					fmt.Println(b.benchmark.Pubs.Statistics())
				}
				if b.benchmark.Subs.HasSamples() {
					fmt.Println(b.benchmark.Subs.Statistics())
				}
			}
		}
	}()

	donewg.Wait()
	done <- struct{}{}
	b.benchmark.Close()

	println()

	host, _ := os.Hostname()

	tb := tabwriter.NewWriter(os.Stdout, 0, 8, 2, ' ', 0)
	_, _ = msg.Fprintf(tb, "\nREPORT\n\nhost:\t%s\n", host)
	_, _ = msg.Fprintf(tb, "mode:\t%d\n", b.cfg.Mode)
	_, _ = msg.Fprintf(tb, "replicas\tmsg\tmsgSize\tpubs\tsubs\tcreateStream\n")
	_, _ = msg.Fprintf(tb, "%s\t%s\t%s\t%s\t%s\t%s\n", "-----", "-----", "-----", "-----", "-----", "-----")
	_, _ = msg.Fprintf(tb, "%d\t%d\t%d\t%d\t%d\t%t\n", b.cfg.Replicas, b.cfg.Count, b.cfg.MsgSize, b.numPubs, b.numSubs, b.cfg.CreateStream)
	_, _ = msg.Fprintf(tb, "%s\t%s\t%s\t%s\t%s\t%s\n", "-----", "-----", "-----", "-----", "-----", "-----")

	_, _ = msg.Fprintf(tb, b.benchmark.Report())
	_ = tb.Flush()

	// save file
	b.saveCSV()
}

func (b *basic) saveCSV() {
	csv := b.benchmark.CSV()
	_ = ioutil.WriteFile("report.csv", []byte(csv), 0644)
	fmt.Printf("Saved metric data in csv file %s\n", "report.csv")
}

func (b *basic) runPublisher(ctx context.Context, nc *nats.Conn, subj string, startwg, donewg *sync.WaitGroup, numMsgs int, msgSize int) {
	l := tel.FromCtx(ctx).Copy()

	if err := getLock(ctx, nc, SystemPhaserSubSubject, SystemPhaserPubSubject); err != nil {
		l.Fatal("lock error", tel.String("sub", SystemPhaserSubSubject), tel.Error(err))
	}

	l.Info("done", tel.String("sub", SystemPhaserSubSubject), tel.String("send", SystemPhaserPubSubject))

	startwg.Done()

	var msg []byte
	if msgSize > 0 {
		msg = make([]byte, msgSize)
	}

	start := time.Now()

	js, err := nc.JetStream(nats.PublishAsyncMaxPending(256))
	if err != nil {
		l.Fatal("JS", tel.String("context", "js context creation"), tel.Error(err))
	}

	for i := 0; i < numMsgs; i++ {
		// or via js explicitly publish to stream
		_, err = js.Publish(subj, msg, nats.ExpectStream(STREAM))
		if err != nil {
			l.Fatal("publish", tel.Error(err))
		}
	}

	atomic.AddUint64(&b.pubTotalMsg, uint64(numMsgs))

	_ = nc.Flush()
	b.benchmark.AddPubSample(bench.NewSample(numMsgs, msgSize, start, time.Now(), nc))
	nc.Close()

	donewg.Done()
}

func (b *basic) runSubscriber(ctx context.Context, nc *nats.Conn, subj string, startwg, donewg *sync.WaitGroup, numMsgs int, msgSize int) {
	l := tel.FromCtx(ctx)

	js, err := nc.JetStream(nats.PublishAsyncMaxPending(256))
	if err != nil {
		l.Fatal("JS", tel.String("context", "js context creation"), tel.Error(err))
	}

	// Simple Pull Consumer
	sub, err := js.PullSubscribe(subj, CONSUMER, nats.Bind(STREAM, CONSUMER))
	if err != nil {
		l.Fatal("pull", tel.Error(err))
	}

	if err = getLock(ctx, nc, SystemPhaserPubSubject, SystemPhaserSubSubject); err != nil {
		l.Fatal("lock error", tel.String("sub", SystemPhaserPubSubject), tel.Error(err))
	}

	l.Info("done", tel.String("sub", SystemPhaserPubSubject), tel.String("send", SystemPhaserSubSubject))

	defer func() {
		// Drain
		_ = sub.Drain()

		// Unsubscribe
		_ = sub.Unsubscribe()
	}()

	var (
		start, end time.Time
		received   int
	)

	//sub.SetPendingLimits(-1, -1)
	//nc.Flush()
	startwg.Done()
	defer nc.Close()
	defer donewg.Done()

	for {
		select {
		case <-ctx.Done():
			l.Info("worker exit")
			return
		default:
		}

		if received >= numMsgs || uint64(b.cfg.Threads*b.cfg.Count) <= atomic.LoadUint64(&b.subTotalMsg) {
			end = time.Now()
			break
		}

		msgs, err := sub.Fetch(100, nats.MaxWait(time.Second*30))
		if err != nil {
			if err != nats.ErrTimeout {
				l.Error("fetch", tel.Error(err))
			}

			continue
		}

		if len(msgs) == 0 {
			l.Fatal("not fetched msgs")
		}

		for _, msg := range msgs {
			received++
			if received == 1 {
				start = time.Now()
			}

			//l.Info(string(msg.Data))
			if err = msg.Ack(); err != nil {
				l.Fatal("ack", tel.Error(err))
			}
		}

		atomic.AddUint64(&b.subTotalMsg, uint64(len(msgs)))
	}

	//println("EXIT", received, uint64(b.cfg.Threads*b.cfg.Count), atomic.LoadUint64(&b.subTotalMsg))

	b.benchmark.AddSubSample(bench.NewSample(received, msgSize, start, end, nc))

}

// getLock check if something come on provided subject, only 1 message
func getLock(ctx context.Context, nc *nats.Conn, sub, pub string) error {
	tel.FromCtx(ctx).Info("enter distributed lock stage")

	done := make(chan struct{}, 1)
	go func() {
		for {
			select {
			case <-ctx.Done():
				return
			case <-done:
				if err := nc.Publish(pub, nil); err != nil {
					tel.FromCtx(ctx).Warn("pub", tel.Error(err), tel.String("subject", pub))
				}
				return
			case <-time.After(time.Second):
				if err := nc.Publish(pub, nil); err != nil {
					tel.FromCtx(ctx).Warn("pub", tel.Error(err), tel.String("subject", pub))
				}
			}
		}
	}()

	cn := make(chan *nats.Msg, 1)
	subscribe, err := nc.ChanSubscribe(sub, cn)
	if err != nil {
		return errors.WithStack(err)
	}

	defer func() {
		_ = subscribe.Drain()
		_ = subscribe.Unsubscribe()
		done <- struct{}{}
	}()

	select {
	case <-cn:
		return nil
	case <-ctx.Done():
		return errors.WithStack(fmt.Errorf("ctx timeout"))
	}
}
