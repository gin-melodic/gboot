package gboot

import (
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestDefault(t *testing.T) {
	g := Default(nil)
	assert.NotNil(t, g)
	err := g.StartServer(nil)
	assert.Nil(t, err)
}