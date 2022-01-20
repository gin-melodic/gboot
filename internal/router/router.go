package router

import (
	"github.com/gin-gonic/gin"
	"github.com/gin-melodic/gboot/environment"
	"github.com/gin-melodic/glog/middleware/gingonic"
)

func NewRouter(env environment.Environment) *gin.Engine {
	if env.CurrentEnv() == environment.Prod {
		gin.SetMode(gin.ReleaseMode)
	}
	router := gin.New()
	router.Use(gingonic.InjectLogger(&gingonic.Options{
		BodyMaxSize: 2000,
	}))
	router.Use(gin.Recovery())
	return router
}
