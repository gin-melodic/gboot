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

package log

import (
	"github.com/gin-melodic/glog"
	"github.com/sirupsen/logrus"
	"io"
	"os"
	"time"
)

func InitLogger(logConfig *glog.LoggerOptions) error {
	lc := &glog.LoggerOptions{}
	if logConfig == nil {
		lc.MinAllowLevel = logrus.InfoLevel
		lc.HighPerformance = false
		lc.OutputDir = "./log"
		lc.FilePrefix = "server"
		lc.SaveDay = 7
		lc.ExtLoggerWriter = []io.Writer{os.Stdout}
		lc.CustomTimeLayout = time.RFC3339
	} else {
		lc.MinAllowLevel = logConfig.MinAllowLevel
		lc.HighPerformance = logConfig.HighPerformance
		lc.OutputDir = logConfig.OutputDir
		lc.FilePrefix = logConfig.FilePrefix
		lc.SaveDay = logConfig.SaveDay
		lc.ExtLoggerWriter = logConfig.ExtLoggerWriter
		lc.CustomTimeLayout = logConfig.CustomTimeLayout
	}
	return glog.InitGlobalLogger(lc)
}
