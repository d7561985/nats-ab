package config

import "time"

type Nats struct {
	Count     int           `env:"PUSH_NUM" envDefault:"1000"`
	DrainTime time.Duration `env:"DRAIN_TIME" envDefault:"10s"`

	Client struct {
		User         string `env:"NATS_USER,required"`
		UserPassword string `env:"NATS_PASSWORD,required"`
	}

	StreamAdmin struct {
		User         string `env:"NATS_STREAM_USER,required"`
		UserPassword string `env:"NATS_STREAM_PASSWORD,required"`
	}

	SysAdmin struct {
		User         string `env:"NATS_SYS_USER"`
		UserPassword string `env:"NATS_SYS_PASSWORD"`
	}

	Addr string `env:"NATS_ADDR,required"`
}
