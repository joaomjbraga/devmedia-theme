// Go example - URL shortener service
package main

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	"time"
)

// ---------- Types ----------

type URL struct {
	ID        string    `json:"id"`
	ShortURL  string    `json:"short_url"`
	LongURL   string    `json:"long_url"`
	CreatedAt time.Time `json:"created_at"`
	Clicks    int64     `json:"clicks"`
}

type CreateURLRequest struct {
	URL string `json:"url"`
}

type APIError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

// ---------- Store ----------

type URLStore struct {
	mu    sync.RWMutex
	urls  map[string]*URL
	stats map[string]int64
}

func NewURLStore() *URLStore {
	return &URLStore{
		urls:  make(map[string]*URL),
		stats: make(map[string]int64),
	}
}

func (s *URLStore) Create(longURL string) *URL {
	s.mu.Lock()
	defer s.mu.Unlock()

	id := generateID(longURL)
	now := time.Now().UTC()

	entry := &URL{
		ID:        id,
		ShortURL:  fmt.Sprintf("https://short.example/%s", id),
		LongURL:   longURL,
		CreatedAt: now,
		Clicks:    0,
	}

	s.urls[id] = entry
	return entry
}

func (s *URLStore) Get(id string) (*URL, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	entry, ok := s.urls[id]
	if !ok {
		return nil, false
	}

	// Increment clicks asynchronously
	go func() {
		s.mu.Lock()
		entry.Clicks++
		s.mu.Unlock()
	}()

	return entry, true
}

func (s *URLStore) GetAll() []*URL {
	s.mu.RLock()
	defer s.mu.RUnlock()

	result := make([]*URL, 0, len(s.urls))
	for _, entry := range s.urls {
		result = append(result, entry)
	}
	return result
}

// ---------- Helpers ----------

func generateID(longURL string) string {
	hash := sha256.Sum256([]byte(longURL + fmt.Sprint(time.Now().UnixNano())))
	encoded := base64.URLEncoding.EncodeToString(hash[:])
	return encoded[:8] // first 8 chars
}

func isValidURL(rawURL string) bool {
	return strings.HasPrefix(rawURL, "http://") || strings.HasPrefix(rawURL, "https://")
}

// ---------- Middleware ----------

type Middleware func(http.Handler) http.Handler

func Logger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		log.Printf("%s %s %s", r.Method, r.URL.Path, time.Since(start))
	})
}

func CORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func ChainMiddleware(h http.Handler, middlewares ...Middleware) http.Handler {
	for i := len(middlewares) - 1; i >= 0; i-- {
		h = middlewares[i](h)
	}
	return h
}

// ---------- Handlers ----------

type Handler struct {
	store *URLStore
}

func NewHandler(store *URLStore) *Handler {
	return &Handler{store: store}
}

func (h *Handler) CreateURL(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req CreateURLRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "Invalid JSON body")
		return
	}

	if !isValidURL(req.URL) {
		writeError(w, http.StatusBadRequest, "Invalid URL format")
		return
	}

	entry := h.store.Create(req.URL)
	writeJSON(w, http.StatusCreated, entry)
}

func (h *Handler) GetURL(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	id := strings.TrimPrefix(r.URL.Path, "/api/urls/")
	entry, ok := h.store.Get(id)
	if !ok {
		writeError(w, http.StatusNotFound, "URL not found")
		return
	}

	writeJSON(w, http.StatusOK, entry)
}

func (h *Handler) ListURLs(w http.ResponseWriter, r *http.Request) {
	entries := h.store.GetAll()
	writeJSON(w, http.StatusOK, entries)
}

func (h *Handler) Redirect(w http.ResponseWriter, r *http.Request) {
	id := strings.TrimPrefix(r.URL.Path, "/")
	entry, ok := h.store.Get(id)
	if !ok {
		writeError(w, http.StatusNotFound, "URL not found")
		return
	}
	http.Redirect(w, r, entry.LongURL, http.StatusMovedPermanently)
}

// ---------- Helpers ----------

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, APIError{Code: status, Message: message})
}

// ---------- Main ----------

func main() {
	store := NewURLStore()
	handler := NewHandler(store)

	mux := http.NewServeMux()
	mux.HandleFunc("/api/urls", handler.ListURLs)
	mux.HandleFunc("/api/urls/", handler.GetURL)
	mux.HandleFunc("/api/create", handler.CreateURL)
	mux.HandleFunc("/", handler.Redirect)

	server := &http.Server{
		Addr:         ":8080",
		Handler:      ChainMiddleware(mux, CORS, Logger),
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  30 * time.Second,
	}

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		log.Printf("Server starting on :8080")
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server error: %v", err)
		}
	}()

	<-quit
	log.Println("Shutting down...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	server.Shutdown(ctx)
}
