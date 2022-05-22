package cmd

import (
	"context"
	"os"
	"os/signal"

	"github.com/d7561985/tel/v2"
	"github.com/urfave/cli/v2"
)

func Run() {
	ccx, cancel := context.WithCancel(context.Background())
	defer cancel()

	cfg := tel.GetConfigFromEnv()
	cfg.MonitorConfig.Enable = false
	cfg.OtelConfig.Enable = false
	cfg.LogEncode = "console"

	l, closer := tel.New(ccx, cfg)
	defer closer()

	go func() {
		c := make(chan os.Signal, 1)
		signal.Notify(c, os.Kill, os.Interrupt)
		<-c
		cancel()
	}()

	app := &cli.App{
		Name:     "ab",
		Usage:    "make an explosive entrance",
		Commands: []*cli.Command{newAB().Command()},
	}

	err := app.RunContext(tel.WithContext(ccx, l), os.Args)
	if err != nil {
		l.Fatal("run application", tel.Error(err))
	}
}
