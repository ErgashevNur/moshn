package services

import (
	"encoding/json"
	"sync"
)

// WSHub — ulangan WebSocket mijozlarini boshqaradi va eventlarni tarqatadi.
// Bron bildirshnomalari real-time servis planshetiga yetkaziladi.
type WSHub struct {
	mu      sync.RWMutex
	clients map[*WSClient]bool
}

type WSClient struct {
	Send   chan []byte
	Role   string
	UserID string
}

func NewWSHub() *WSHub {
	return &WSHub{clients: make(map[*WSClient]bool)}
}

func (h *WSHub) Register(c *WSClient) {
	h.mu.Lock()
	h.clients[c] = true
	h.mu.Unlock()
}

func (h *WSHub) Unregister(c *WSClient) {
	h.mu.Lock()
	if h.clients[c] {
		delete(h.clients, c)
		close(c.Send)
	}
	h.mu.Unlock()
}

// BroadcastToUser — aniq user_id ga tegishli barcha ulanishlarga event yuboradi.
func (h *WSHub) BroadcastToUser(userID string, eventType string, payload interface{}) {
	msg, err := json.Marshal(map[string]interface{}{
		"type": eventType,
		"data": payload,
	})
	if err != nil {
		return
	}
	h.mu.RLock()
	defer h.mu.RUnlock()
	for c := range h.clients {
		if c.UserID != userID {
			continue
		}
		select {
		case c.Send <- msg:
		default:
		}
	}
}

// BroadcastToAdmins — admin rolidagi barcha ulanishlarga event yuboradi.
func (h *WSHub) BroadcastToAdmins(eventType string, payload interface{}) {
	msg, err := json.Marshal(map[string]interface{}{
		"type": eventType,
		"data": payload,
	})
	if err != nil {
		return
	}
	h.mu.RLock()
	defer h.mu.RUnlock()
	for c := range h.clients {
		if c.Role != "admin" {
			continue
		}
		select {
		case c.Send <- msg:
		default:
		}
	}
}
