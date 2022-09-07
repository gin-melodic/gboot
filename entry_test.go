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
	"github.com/gin-gonic/gin"
	"github.com/gin-melodic/glog"
	"github.com/stretchr/testify/assert"
	"os"
	"testing"
	"time"
)

func TestDefault(t *testing.T) {
	g := Default(nil)
	assert.NotNil(t, g)

	g.Engine.Handle("GET", "/test", func(ctx *gin.Context) {
		ctx.String(200, "test")
	})

	go func() {
		time.Sleep(2 * time.Second)

		println("Stop server")
		g.QuitChan <- os.Interrupt
	}()

	err := g.StartServer(func() {
		glog.ShareLogger().Info("Start clear log")
		assert.NoErrorf(t, glog.ShareLogger().Close(), "close logger error")
		assert.NoErrorf(t, os.RemoveAll("./log"), "delete log files error")
	})
	assert.Nil(t, err)
}
