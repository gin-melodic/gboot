# gboot
🚀🚀🚀 Rush start a web project with gonic-gin/gin and other convenient tools!!! 🚀🚀🚀

Use this framework to quickly deploy a golang web service that includes:

- [gingonic/gin](https://github.com/gin-gonic/gin) web engine & graceful shutdown
- log system with rotation func by [gin-melodic/glog](https://github.com/gin-melodic/glog)
- configuration parsing func by [spf13/viper](https://github.com/spf13/viper)

## Install

```shell
go get github.com/gin-melodic/gboot
```

## Usage

Before launch `gboot`, you need create the configuration in `config/` dir.

Configuration files distinguish environments by filename, e.g. `development.yml`, `production.yml`.

A simple `development.yml` look like:

```yaml
server:
  name: app
  port: 8000

log:
  path: ./log/
  saveDay: 7
  # panic, fatal, error, warn, info, debug, trace
  level: info
```

**The key-value pairs in the sample configuration file must be included, otherwise the service cannot be started.**

Then you can start server in your `main.go`:

```go
package main

import (
	"github.com/gin-gonic/gin"
	"github.com/gin-melodic/gboot"
	"github.com/gin-melodic/glog"
	"net/http"
	"time"
)

// PingController test controller
type PingController struct {}

// Ping get ping request
func (p *PingController) Ping(c *gin.Context) {
	glog.ShareLogger().Infof("get 'ping' request.")
	c.JSON(200, map[string]interface{}{
		"result": "ok",
		"busCode": "1000",
	})
}

func main() {
  // Be careful! You can't use glog.shareLogger before gboot init, the app will panic!!!
  // init gboot instance
	g := gboot.Default(nil)
  // Note: now you can use glog.shareLogger after gboot init.

  // make server root
	r := g.Engine.Group("/api/v1")
	{
		tc := &PingController{}
    // listen 'ping' request
		r.GET("ping", tc.Ping)
	}

	// Test area
	go func() {
    // Wait 5 second, then send GET request
		time.Sleep(5 * time.Second)
		glog.ShareLogger().Infof("send test request")
    // The port of '8000' configured in config/development.yml
		resp, err := http.Get("http://127.0.0.1:8000/api/v1/ping")
		if err != nil {
			glog.ShareLogger().Error(err)
			return
		}
		glog.ShareLogger().Infof("get %+v", resp)
	}()
  // Test area end

  // Test log, now you can find log in stdout & ./log/
	glog.ShareLogger().Infof("test")

  // Start server
	if err := g.StartServer(nil); err != nil {
		glog.ShareLogger().Fatalf(err.Error())
	}
  // !!!!Dead zone, code in here won't execuate.
}
```

When the service is started, check the project's log folder or console, you will find something like below:

```
[GIN-debug] [WARNING] Running in "debug" mode. Switch to "release" mode in production.
 - using env:   export GIN_MODE=release
 - using code:  gin.SetMode(gin.ReleaseMode)

[GIN-debug] GET    /api/v1/ping              --> gboot-example/router.(*PingController).Ping-fm (3 handlers)
2022-01-20T23:52:36+08:00 [PID:1][main.go:31][INFO]test
2022-01-20T23:52:36+08:00 [PID:21][entry.go:94][INFO]server will startup on port 8000
2022-01-20T23:52:41+08:00 [PID:20][main.go:22][INFO]send test request
2022-01-20T23:52:41+08:00 [PID:50][gin-gonic.go:97][INFO]REQ -> |       127.0.0.1 | GET /api/v1/ping | [EMPTY QUERY] |  
2022-01-20T23:52:41+08:00 [PID:50][controller.go:11][INFO]get 'ping' request.
2022-01-20T23:52:41+08:00 [PID:50][gin-gonic.go:125][INFO]<- RESP |       127.0.0.1 | 200 |     508.811µs | GET /api/v1/ping |  {"busCode":"1000","result":"ok"}
2022-01-20T23:52:41+08:00 [PID:20][main.go:28][INFO]get &{Status:200 OK StatusCode:200 Proto:HTTP/1.1 ProtoMajor:1 ProtoMinor:1 Header:map[Content-Length:[32] Content-Type:[application/json; charset=utf-8] Date:[Thu, 20 Jan 2022 15:52:41 GMT]] Body:0xc00009e140 ContentLength:32 TransferEncoding:[] Close:false Uncompressed:false Trailer:map[] Request:0xc000242b00 TLS:<nil>}
```
