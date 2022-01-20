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
