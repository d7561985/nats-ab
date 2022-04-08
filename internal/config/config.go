package config

type Nats struct {
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
