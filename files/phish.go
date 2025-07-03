package controllers

import (
	"compress/gzip"
	"context"
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/NYTimes/gziphandler"
	"github.com/gophish/gophish/config"
	ctx "github.com/gophish/gophish/context"
	log "github.com/gophish/gophish/logger"
	"github.com/gophish/gophish/models"
	"github.com/gorilla/mux"
)

// PhishingServer is an HTTP server that implements the campaign functionality
type PhishingServer struct {
	server *http.Server
	config config.PhishServer
}

// NewPhishingServer returns a new instance of the phishing server
func NewPhishingServer(config config.PhishServer) *PhishingServer {
	defaultWorkerPool := 1
	if config.WorkerPoolSize == 0 {
		config.WorkerPoolSize = defaultWorkerPool
	}
	ps := &PhishingServer{
		config: config,
	}
	ps.server = &http.Server{
		Addr:         config.ListenURL,
		Handler:      ps.registerRoutes(),
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}
	return ps
}

// Start launches the phishing server, listening on the configured address
func (ps *PhishingServer) Start() {
	if ps.config.UseTLS {
		err := util.CheckAndCreateSSL(ps.config.CertPath, ps.config.KeyPath)
		if err != nil {
			log.Fatal(err)
		}
		log.Infof("Starting phishing server at https://%s", ps.config.ListenURL)
		log.Fatal(ps.server.ListenAndServeTLS(ps.config.CertPath, ps.config.KeyPath))
	}
	log.Infof("Starting phishing server at http://%s", ps.config.ListenURL)
	log.Fatal(ps.server.ListenAndServe())
}

// Shutdown attempts to gracefully shutdown the server
func (ps *PhishingServer) Shutdown() error {
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*10)
	defer cancel()
	return ps.server.Shutdown(ctx)
}

// registerRoutes registers the routes for the phishing server
func (ps *PhishingServer) registerRoutes() http.Handler {
	router := mux.NewRouter()
	router.PathPrefix("/static/").Handler(http.StripPrefix("/static/", http.FileServer(http.Dir("./static/"))))
	router.HandleFunc("/track", ps.TrackHandler)
	router.HandleFunc("/robots.txt", ps.RobotsHandler)
	router.HandleFunc("/", ps.PhishHandler)
	router.NotFoundHandler = http.HandlerFunc(ps.NotFoundHandler)
	
	// Enable gzip compression
	gzipWrapper, _ := gziphandler.NewGzipLevelHandler(gzip.DefaultCompression)
	return gzipWrapper(router)
}

// PhishHandler handles incoming client connections and serves the appropriate content
func (ps *PhishingServer) PhishHandler(w http.ResponseWriter, r *http.Request) {
	err := ps.handlePhishResponse(w, r)
	if err != nil {
		log.Error(err)
		http.NotFound(w, r)
	}
}

// NotFoundHandler handles 404 errors and returns a generic page
func (ps *PhishingServer) NotFoundHandler(w http.ResponseWriter, r *http.Request) {
	// Return a generic 404 page to avoid fingerprinting
	w.WriteHeader(http.StatusNotFound)
	fmt.Fprint(w, `<!DOCTYPE html>
<html>
<head>
    <title>404 Not Found</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 50px; }
        h1 { color: #333; }
    </style>
</head>
<body>
    <h1>404 - Not Found</h1>
    <p>The requested resource could not be found on this server.</p>
</body>
</html>`)
}

// TrackHandler handles tracking requests
func (ps *PhishingServer) TrackHandler(w http.ResponseWriter, r *http.Request) {
	err := ps.handleTrackResponse(w, r)
	if err != nil {
		log.Error(err)
		http.NotFound(w, r)
	}
}

// RobotsHandler handles requests to /robots.txt
func (ps *PhishingServer) RobotsHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/plain")
	fmt.Fprint(w, "User-agent: *\nDisallow: /")
}

// handlePhishResponse handles the main phishing logic
func (ps *PhishingServer) handlePhishResponse(w http.ResponseWriter, r *http.Request) error {
	// Implementation would go here
	// This is a simplified version
	return nil
}

// handleTrackResponse handles tracking pixel requests  
func (ps *PhishingServer) handleTrackResponse(w http.ResponseWriter, r *http.Request) error {
	// Implementation would go here
	// This is a simplified version
	return nil
}
