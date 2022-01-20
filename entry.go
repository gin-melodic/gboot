package main

import (
	"fmt"
	"github.com/gin-melodic/gboot/environment"
	"github.com/gin-melodic/gboot/internal/config"
	"github.com/gin-melodic/gboot/internal/log"
	"github.com/gin-melodic/glog"
	"github.com/sirupsen/logrus"
	"io"
	"os"
	"time"
)

// GinBootEngine basic config
type GinBootEngine struct {
	Env environment.Environment
}

// Default create a GinBootEngine instance by common configuration.
//
// This instance contains 2 environment which is 'development' and 'production'.
// The server will automatically parse development.yml/production.yml from path in "./", "./config/" or "../config/"
// You can pass environment by cmd flag '-e' (use cmd flag '-v' get more description for binary exec command line).
//
// Default will also read the parameter values of "server" and "log" in the configuration file of the specified environment.
// Be careful, the server will automatically parse configuration file(.yml) by env name.
// you can find a config example in config/development.yml
func Default(baseEnv environment.Environment) *GinBootEngine {
	g := GinBootEngine{}
	incomeEnv := baseEnv
	if baseEnv == nil {
		incomeEnv = &environment.SimpleEnv{}
	}
	env, err := config.ParseFlag(incomeEnv)
	if err != nil {
		fmt.Printf("Default create engine error. %+v", err)
		os.Exit(1)
	}
	g.Env = env
	// Init logger
	level, err := logrus.ParseLevel(env.GetConfig().GetString("log.level"))
	if err != nil {
		level = logrus.InfoLevel
	}
	lc := &glog.LoggerOptions{
		MinAllowLevel:   level,
		HighPerformance: false,
		OutputDir:       env.GetConfig().GetString("log.path"),
		FilePrefix:      env.GetConfig().GetString("server.name"),
		SaveDay: 		 time.Duration(env.GetConfig().GetInt64("log.saveDay")),
		ExtLoggerWriter: []io.Writer{os.Stdout},
	}
	if env.CurrentEnv() != environment.Dev {
		lc.ExtLoggerWriter = nil
	}
	if err = log.InitLogger(lc); err != nil {
		fmt.Printf("Init logger error. %+v", err)
		os.Exit(1)
	}

	return &g
}

// main only for testing
func main() {
	Default(nil)
}
