package main

import (
	"github.com/d7561985/nats-ab/cmd"
	_ "github.com/joho/godotenv/autoload"
	_ "github.com/urfave/cli/v2"
)

func main() {
	cmd.Run()
}
