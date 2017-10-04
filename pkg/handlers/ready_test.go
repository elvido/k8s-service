package handlers

import (
	"net/http"
	"testing"

	"github.com/elvido/k8s_service/pkg/config"
	"github.com/elvido/k8s_service/pkg/logger"
	"github.com/elvido/k8s_service/pkg/logger/standard"
	"github.com/elvido/k8s_service/pkg/router/bitroute"
)

func TestReady(t *testing.T) {
	h := New(standard.New(&logger.Config{}), new(config.Config))
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h.Base(h.Ready)(bitroute.NewControl(w, r))
	})

	testHandler(t, handler, http.StatusOK, http.StatusText(http.StatusOK))
}
