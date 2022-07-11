package config

import (
	"time"

	"github.com/nats-io/nats.go"
)

type Nats struct {
	Mode int

	Addr string

	DrainTime time.Duration
	Count     int
	MsgSize   int
	Replicas  int
	Threads   int

	Client      Cred
	StreamAdmin Cred
	SysAdmin    Cred

	opts []nats.Option
}

type Option interface {
	apply(*Nats)
}

type XX func(*Nats)

func (x XX) apply(in *Nats) {
	x(in)
}

func newConfig(opts ...Option) *Nats {
	s := &Nats{}

	for _, opt := range opts {
		opt.apply(s)
	}

	return s
}

type Cred struct {
	User         string
	UserPassword string
}

func WithNatsOptions(opts ...nats.Option) Option {
	return XX(func(n *Nats) {
		n.opts = append(n.opts, opts...)
	})
}
