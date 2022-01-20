package config

import (
	"flag"
	"github.com/gin-melodic/gboot/environment"
)

// ParseFlag parse command and out env flag.
func ParseFlag(env environment.Environment) (mergedEnv environment.Environment, err error) {
	var envString string
	flag.StringVar(&envString, "e", "development",
		"execute environment(development, production, test), default is 'development'")
	flag.Parse()
	mergedEnv, err = environment.Init(envString, env)
	return
}
