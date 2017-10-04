package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/elvido/k8s-service/pkg/config"
	"github.com/elvido/k8s-service/pkg/logger"
	"github.com/elvido/k8s-service/pkg/logger/standard"
	"github.com/elvido/k8s-service/pkg/router/bitroute"
)

func TestEvents(t *testing.T) {
	h := New(standard.New(&logger.Config{}), new(config.Config))
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h.Base(h.Info)(bitroute.NewControl(w, r))
	})

	req, err := http.NewRequest("GET", "/", nil)
	if err != nil {
		t.Error(err)
	}

	trw := httptest.NewRecorder()
	handler.ServeHTTP(trw, req)

	if trw.Code != http.StatusOK {
		t.Error("Expected status:", http.StatusOK, "got", trw.Code)
	}

	var s Status
	err = json.Unmarshal(trw.Body.Bytes(), &s)
	if err != nil {
		t.Fatal(err)
	}
}
