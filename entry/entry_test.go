package entry

import (
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestDefault(t *testing.T) {
	g := Default(nil)
	assert.NotNil(t, g)
}