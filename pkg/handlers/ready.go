// Copyright 2017 Ralf Hofmann. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

package handlers

import (
	"net/http"

	"github.com/elvido/k8s_service/pkg/router"
)

// Ready returns "OK" if service is ready to serve traffic
func (h *Handler) Ready(c router.Control) {
	// TODO: possible use cases:
	// load data from a database, a message broker, any external services, etc

	c.Code(http.StatusOK)
	c.Body(http.StatusText(http.StatusOK))
}
