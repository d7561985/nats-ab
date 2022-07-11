package config

import (
	"time"
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

	CreateStream bool
}

type Cred struct {
	User         string
	UserPassword string
}
