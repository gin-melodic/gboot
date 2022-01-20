/**
Copyright 2022 Gin Van
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package gboot

import (
	"context"
	"fmt"
	"github.com/gin-gonic/gin"
	"github.com/gin-melodic/gboot/environment"
	"github.com/gin-melodic/gboot/internal/config"
	"github.com/gin-melodic/gboot/internal/log"
	"github.com/gin-melodic/gboot/internal/router"
	"github.com/gin-melodic/glog"
	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"
	"io"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

// GinBootEngine basic config
type GinBootEngine struct {
	Env environment.Environment
	Engine *gin.Engine
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
		CustomTimeLayout: time.RFC3339,
	}
	if env.CurrentEnv() != environment.Dev {
		lc.ExtLoggerWriter = nil
	}
	if err = log.InitLogger(lc); err != nil {
		fmt.Printf("Init logger error. %+v", err)
		os.Exit(1)
	}
	r := router.NewRouter(env)
	g.Engine = r
	return &g
}

// HandleFunc use by param
type HandleFunc func()

// StartServer start gin server with graceful shutdown.
// The port of server is configured in xxx.yml
func (g *GinBootEngine) StartServer(termCrontabHandle HandleFunc) error {
	port := g.Env.GetConfig().GetString("server.port")
	if port == "" {
		println("[WARN]Use default port 8888")
		port = "8888"
	}
	if g.Engine == nil {
		return errors.New("must init engine first.")
	}
	srv := &http.Server{
		Addr: ":" + port,
		Handler: g.Engine,
	}
	go func() {
		glog.ShareLogger().Infof("server will startup on port %s", port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			glog.ShareLogger().Fatalf("listen serve error. %+v", err)
		}
	}()
	// graceful shutdown
	quit := make(chan os.Signal)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	ctx, cancel := context.WithTimeout(context.Background(), 5 * time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		glog.ShareLogger().Fatalf("server forced to shutdown: %s", err)
	}
	// stop crontab
	if termCrontabHandle != nil {
		termCrontabHandle()
	}
	glog.ShareLogger().Infof("server has stopped.")
	return nil
}
