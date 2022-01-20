package log

import (
	"github.com/gin-melodic/glog"
	"github.com/sirupsen/logrus"
	"io"
	"os"
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
	} else {
		lc.MinAllowLevel = logConfig.MinAllowLevel
		lc.HighPerformance = logConfig.HighPerformance
		lc.OutputDir = logConfig.OutputDir
		lc.FilePrefix = logConfig.FilePrefix
		lc.SaveDay = logConfig.SaveDay
		lc.ExtLoggerWriter = logConfig.ExtLoggerWriter
	}
	return glog.InitGlobalLogger(lc)
}
