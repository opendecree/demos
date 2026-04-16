// Payroll Service — a demo fintech microservice using OpenDecree for
// runtime configuration. Exposes REST endpoints for payroll values
// and a WebSocket for live config updates.
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"sync"
	"time"

	"github.com/coder/websocket"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	pb "github.com/opendecree/decree/api/centralconfig/v1"
	"github.com/opendecree/decree/sdk/configclient"
	"github.com/opendecree/decree/sdk/configwatcher"
)

func main() {
	if err := run(); err != nil {
		log.Fatal(err)
	}
}

func run() error {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()

	// Connect to decree server.
	addr := envOr("DECREE_ADDR", "localhost:9090")
	conn, err := grpc.NewClient(addr,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		return fmt.Errorf("connect to decree: %w", err)
	}
	defer conn.Close()

	tenantID, err := readTenantID()
	if err != nil {
		return fmt.Errorf("read tenant ID: %w", err)
	}
	log.Printf("Using tenant: %s", tenantID)

	// --- Config client for on-demand reads ---
	client := configclient.New(
		pb.NewConfigServiceClient(conn),
		configclient.WithSubject("payroll-service"),
	)

	// --- Config watcher for live values ---
	w := configwatcher.New(conn, tenantID,
		configwatcher.WithSubject("payroll-service"),
	)
	taxRate := w.Float("payroll.tax_rate", 0.025)
	overtimeMul := w.Float("payroll.overtime_multiplier", 1.5)
	processingFee := w.Float("payroll.processing_fee", 0.30)
	currency := w.String("payroll.currency", "USD")
	baseAmount := w.Float("payroll.base_amount", 5000)
	periodDays := w.Int("payroll.period_days", 30)

	if err := w.Start(ctx); err != nil {
		return fmt.Errorf("start watcher: %w", err)
	}
	defer w.Close()

	// --- WebSocket hub for broadcasting changes ---
	hub := newWSHub()

	// Fan config changes into the hub.
	go fanChanges(ctx, hub, "payroll.tax_rate", taxRate.Changes())
	go fanChanges(ctx, hub, "payroll.overtime_multiplier", overtimeMul.Changes())
	go fanChanges(ctx, hub, "payroll.processing_fee", processingFee.Changes())
	go fanChanges(ctx, hub, "payroll.currency", currency.Changes())
	go fanChanges(ctx, hub, "payroll.base_amount", baseAmount.Changes())
	go fanChanges(ctx, hub, "payroll.period_days", periodDays.Changes())

	// --- HTTP handlers ---
	mux := http.NewServeMux()

	// Serve the dashboard.
	mux.Handle("GET /", http.FileServer(http.Dir("/static")))

	// API: fetch payroll amount on demand.
	mux.HandleFunc("GET /api/payroll-amount", func(w http.ResponseWriter, r *http.Request) {
		amount, err := client.GetFloat(r.Context(), tenantID, "payroll.base_amount")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		cur, _ := client.GetString(r.Context(), tenantID, "payroll.currency")
		writeJSON(w, map[string]any{"amount": amount, "currency": cur})
	})

	// API: fetch period duration on demand.
	mux.HandleFunc("GET /api/period-duration", func(w http.ResponseWriter, r *http.Request) {
		days, err := client.GetInt(r.Context(), tenantID, "payroll.period_days")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		writeJSON(w, map[string]any{"days": days})
	})

	// API: all live values snapshot.
	mux.HandleFunc("GET /api/config", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, map[string]any{
			"tax_rate":            taxRate.Get(),
			"overtime_multiplier": overtimeMul.Get(),
			"processing_fee":     processingFee.Get(),
			"currency":           currency.Get(),
			"base_amount":        baseAmount.Get(),
			"period_days":        periodDays.Get(),
		})
	})

	// WebSocket: stream live config changes.
	mux.HandleFunc("GET /api/ws", func(w http.ResponseWriter, r *http.Request) {
		hub.serveWS(w, r)
	})

	port := envOr("PORT", "4000")
	srv := &http.Server{Addr: ":" + port, Handler: mux}
	go func() {
		<-ctx.Done()
		srv.Shutdown(context.Background())
	}()

	log.Printf("Payroll Service listening on http://localhost:%s", port)
	log.Printf("Admin panel at http://localhost:3000")
	if err := srv.ListenAndServe(); err != http.ErrServerClosed {
		return err
	}
	return nil
}

// --- WebSocket hub ---

type wsHub struct {
	mu      sync.RWMutex
	clients map[*websocket.Conn]struct{}
}

func newWSHub() *wsHub {
	return &wsHub{clients: make(map[*websocket.Conn]struct{})}
}

func (h *wsHub) serveWS(w http.ResponseWriter, r *http.Request) {
	c, err := websocket.Accept(w, r, &websocket.AcceptOptions{
		OriginPatterns: []string{"*"},
	})
	if err != nil {
		log.Printf("ws accept: %v", err)
		return
	}

	h.mu.Lock()
	h.clients[c] = struct{}{}
	h.mu.Unlock()

	// Keep connection alive until client disconnects.
	ctx := c.CloseRead(r.Context())
	<-ctx.Done()

	h.mu.Lock()
	delete(h.clients, c)
	h.mu.Unlock()
	c.CloseNow()
}

func (h *wsHub) broadcast(msg []byte) {
	h.mu.RLock()
	defer h.mu.RUnlock()
	for c := range h.clients {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		c.Write(ctx, websocket.MessageText, msg)
		cancel()
	}
}

// fanChanges reads from a configwatcher Changes channel and broadcasts to WebSocket clients.
func fanChanges[T any](ctx context.Context, hub *wsHub, field string, ch <-chan configwatcher.Change[T]) {
	for {
		select {
		case <-ctx.Done():
			return
		case change, ok := <-ch:
			if !ok {
				return
			}
			msg, _ := json.Marshal(map[string]any{
				"field": field,
				"old":   change.Old,
				"new":   change.New,
			})
			hub.broadcast(msg)
		}
	}
}

// --- Helpers ---

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(v)
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func readTenantID() (string, error) {
	// Try file first (set by seed container).
	if path := os.Getenv("TENANT_ID_FILE"); path != "" {
		data, err := os.ReadFile(path)
		if err == nil {
			id := strings.TrimSpace(string(data))
			if id != "" {
				return id, nil
			}
		}
	}
	// Fall back to env var.
	if id := os.Getenv("TENANT_ID"); id != "" {
		return id, nil
	}
	return "", fmt.Errorf("set TENANT_ID or TENANT_ID_FILE")
}
