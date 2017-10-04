// Copyright 2017 Ralf Hofmann. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

package handlers

import (
	"net/http"

	"github.com/elvido/k8s-service/pkg/router"
)

// Health returns "OK" if service is alive
func (h *Handler) Health(c router.Control) {
	c.Code(http.StatusOK)
	c.Body(http.StatusText(http.StatusOK))
}
