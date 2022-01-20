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

package environment

import (
	"github.com/pkg/errors"
	"github.com/spf13/viper"
)

type EnvFlag = int

func Init(envDesc string, baseEnv Environment) (Environment, error) {
	env := baseEnv
	// if `env` is nil, use SimpleEnv
	if baseEnv == nil {
		env = &SimpleEnv{}
	}

	if err := env.SetEnv(envDesc); err != nil {
		return nil, errors.Wrap(err, "Unsupported environment string.")
	}

	c := viper.New()
	c.SetConfigType("yaml")

	c.SetConfigName(envDesc)
	c.AddConfigPath("../config/")
	c.AddConfigPath("config/")
	c.AddConfigPath("./")
	setDefaultVal(c)
	if err := c.ReadInConfig(); err != nil {
		return nil, errors.WithStack(err)
	}
	env.SetConfig(c)
	return env, nil
}

// Environment define environment interface
// You can create a special env object like SimpleEnv
type Environment interface {
	CurrentEnv() EnvFlag
	CurrentEnvDesc() string
	SetEnv(string) error

	SetConfig(*viper.Viper)
	GetConfig() *viper.Viper
}

func setDefaultVal(config *viper.Viper) {
	config.SetDefault("server.port", 8080)
	config.SetDefault("server.logFile.path", "./")
	config.SetDefault("server.logFile.name", "server.log")
}

const (
	Dev = iota
	Prod
)

type SimpleEnv struct {
	env    EnvFlag
	config *viper.Viper
}

func (s *SimpleEnv) CurrentEnv() EnvFlag {
	return s.env
}

func (s *SimpleEnv) CurrentEnvDesc() string {
	switch s.env {
	case Dev:
		return "development"
	case Prod:
		return "production"
	}
	return "development"
}

func (s *SimpleEnv) SetEnv(desc string) error {
	switch desc {
	case "development":
		s.env = Dev
		return nil
	case "production":
		s.env = Prod
		return nil
	}
	return errors.New("Unknown environment flag.")
}

func (s *SimpleEnv) SetConfig(viper *viper.Viper) {
	s.config = viper
}

func (s *SimpleEnv) GetConfig() *viper.Viper {
	return s.config
}
