// Copyright 2017 Ralf Hofmann. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

package handlers

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
	"path/filepath"

	"github.com/ghodss/yaml"

	"github.com/elvido/k8s-service/pkg/config"
	"github.com/elvido/k8s-service/pkg/logger"
	"github.com/elvido/k8s-service/pkg/router"
)

// EventsDefinition of data
type EventsDefinition struct {
	MetaData Metadata `json:"@metadata"`
	Events   []Event  `json:"events"`
}

// Metadata header of Json file
type Metadata struct {
	Authors      []string `json:"authors"`
	LastModified string   `json:"last-modified"`
	Version      string   `json:"version"`
}

// Event defintion of one event
type Event struct {
	ID          int    `json:"id"`
	Name        string `json:"name"`
	Source      string `json:"source"`
	Description string `json:"description"`
	Payload     string `json:"payload"`
}

var eventsDefinition interface{}

// LoadEvents load the events from file
func LoadEvents(cfg *config.Config, log logger.Logger) {
	file, e := ioutil.ReadFile(cfg.EventsDefinition)
	if e != nil {
		log.Errorf("File error: %v\n", e)
		return
	}

	if filepath.Ext(cfg.EventsDefinition) == ".yaml" {
		y, _ := yaml.YAMLToJSON(file)
		json.Unmarshal(y, &eventsDefinition)
	} else {
		json.Unmarshal(file, &eventsDefinition)
	}
}

// Events returns detailed info about the service
func (h *Handler) Events(c router.Control) {
	c.Code(http.StatusOK)
	c.Body(eventsDefinition)
}
