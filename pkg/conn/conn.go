package conn

import (
	"time"

	"github.com/d7561985/nats-ab/internal/config"
	"github.com/nats-io/nats.go"
	"github.com/pkg/errors"
)

const (
	DrainTimeOut = time.Minute * 2
)

type NATS struct {
	client nats.JetStreamContext
	admin  nats.JetStreamContext
}

func New(cfg config.Nats) (*NATS, error) {
	admin, err := create(cfg.Addr, cfg.StreamAdmin.User, cfg.StreamAdmin.UserPassword)
	if err != nil {
		return nil, err
	}

	client, err := create(cfg.Addr, cfg.Client.User, cfg.Client.UserPassword)
	if err != nil {
		return nil, err
	}

	return &NATS{admin: admin, client: client}, nil
}

func (n *NATS) Client() nats.JetStreamContext {
	return n.client
}

func (n *NATS) Admin() nats.JetStreamContext {
	return n.admin
}

func create(addr, user, psw string) (nats.JetStreamContext, error) {
	nc, err := nats.Connect(addr,
		nats.DrainTimeout(DrainTimeOut),
		nats.UserInfo(user, psw))

	if err != nil {
		return nil, errors.WithMessagef(err, "%q: connection", user)
	}

	js, err := nc.JetStream(nats.PublishAsyncMaxPending(256))
	if err != nil {
		return nil, errors.WithMessagef(err, "%q: jetstream creation", user)
	}

	return js, nil
}
