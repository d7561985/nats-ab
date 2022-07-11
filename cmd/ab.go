package cmd

import (
	"time"

	"github.com/caarlos0/env/v6"
	"github.com/d7561985/nats-ab/internal/config"
	"github.com/d7561985/nats-ab/pkg/scenarios/basic"
	"github.com/pkg/errors"
	"github.com/urfave/cli/v2"
)

type ab struct{}

func newAB() *ab { return &ab{} }

const (
	count            = "count"
	threads          = "threads"
	drainTime        = "drainTime"
	addr             = "addr"
	replicas         = "replicas"
	accUser          = "accUser"
	accUserPassword  = "accUserPassword"
	accAdmin         = "accAdmin"
	accAdminPassword = "accAdminPassword"
	sysUser          = "sysUser"
	sysPassword      = "sysPassword"
	msgSize          = "msgSize"
	createStream     = "createStream"

	mode = "mode"
)

func (a *ab) Command() *cli.Command {
	return &cli.Command{
		Name:        "compliance",
		Aliases:     []string{"c"},
		Usage:       "run compliance scenario tests",
		UsageText:   "<usage text>",
		Description: "<description>",
		Action:      a.handler(),
		Flags: []cli.Flag{
			&cli.IntFlag{
				Name: "mode",
				Usage: "Some scenarios required 2 or more applications launches (between leaf nodes), " +
					"value: 0: send and receive, 1: only send, 2: only receive",
				Value:   0,
				EnvVars: []string{"MODE"},
			},
			&cli.IntFlag{
				Name:    count,
				Usage:   "messages to publish/receive",
				Value:   1000,
				EnvVars: []string{"MSG_NUM"},
			},
			&cli.IntFlag{
				Name:    msgSize,
				Usage:   "messages to publish/receive",
				Value:   128,
				EnvVars: []string{"MSG_SIZE"},
			},
			&cli.IntFlag{
				Name:    threads,
				Usage:   "consent execution",
				Value:   1,
				EnvVars: []string{"THREADS"},
			},
			&cli.DurationFlag{
				Name:    drainTime,
				Usage:   "wait before clean up after scenario",
				Value:   time.Second * 10,
				EnvVars: []string{"DRAIN_TIME"},
			},
			&cli.StringFlag{
				Name:    addr,
				Usage:   "NATS URI list",
				Value:   "nats://127.0.0.1:4222",
				EnvVars: []string{"NATS_ADDR"},
			},
			&cli.IntFlag{
				Name:    replicas,
				Usage:   "stream reapplication usage",
				Value:   1,
				EnvVars: []string{"REPLICAS"},
			},
			&cli.StringFlag{
				Name:    accUser,
				Usage:   "none sys account user who will send or read messages",
				EnvVars: []string{"ACC_USER"},
				Aliases: []string{"u"},
			},
			&cli.StringFlag{
				Name:        accUserPassword,
				Usage:       "password for accUser",
				DefaultText: "****",
				EnvVars:     []string{"ACC_USER_PASSWORD"},
				Aliases:     []string{"p"},
			},
			&cli.StringFlag{
				Name:    accAdmin,
				Usage:   "none sys account user admin with no restriction",
				Aliases: []string{"a"},
				EnvVars: []string{"ACC_ADMIN"},
			},
			&cli.StringFlag{
				Name:        accAdminPassword,
				Usage:       "password for accAdmin",
				DefaultText: "****",
				Aliases:     []string{"ap"},
				EnvVars:     []string{"ACC_ADMIN_PASSWORD"},
			},
			&cli.StringFlag{
				Name:    sysUser,
				Usage:   "sys account user",
				EnvVars: []string{"SYS_USER"},
			},
			&cli.StringFlag{
				Name:        sysPassword,
				DefaultText: "****",
				Usage:       "sysUser password",
				EnvVars:     []string{"SYS_USER_PASSWORD"},
			},
			&cli.BoolFlag{
				Name:    createStream,
				Value:   true,
				Usage:   "is not need to create stream",
				EnvVars: []string{"CREATE_STREAM"},
				Aliases: []string{"cs"},
			},
		},
		HelpName: "<help name>",
	}
}

func (a *ab) handler() func(c *cli.Context) error {
	return func(c *cli.Context) error {
		cfg := config.Nats{
			Addr:      c.String(addr),
			Threads:   c.Int(threads),
			Count:     c.Int(count),
			MsgSize:   c.Int(msgSize),
			DrainTime: c.Duration(drainTime),
			Replicas:  c.Int(replicas),
			Client: config.Cred{
				User:         c.String(accUser),
				UserPassword: c.String(accUserPassword),
			},
			StreamAdmin: config.Cred{
				User:         c.String(accAdmin),
				UserPassword: c.String(accAdminPassword),
			},
			SysAdmin: config.Cred{
				User:         c.String(sysUser),
				UserPassword: c.String(sysPassword),
			},
			Mode:         c.Int(mode),
			CreateStream: c.Bool(createStream),
		}

		if err := env.Parse(&cfg); err != nil {
			return errors.WithStack(err)
		}

		basic.Run(c.Context, cfg)
		return nil
	}
}
