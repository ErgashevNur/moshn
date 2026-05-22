package handlers

import (
	"net/http"
	"time"

	"moshn/backend/services"
	"moshn/backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

type WSHandler struct {
	hub      *services.WSHub
	upgrader websocket.Upgrader
}

func NewWSHandler(hub *services.WSHub) *WSHandler {
	return &WSHandler{
		hub: hub,
		upgrader: websocket.Upgrader{
			ReadBufferSize:  1024,
			WriteBufferSize: 1024,
			// Dev: barcha originlarga ruxsat (admin :3000 -> backend :8080).
			CheckOrigin: func(r *http.Request) bool { return true },
		},
	}
}

// Connect — GET /v1/ws?token=<access_token>
// Brauzer WebSocket header yubora olmagani uchun token query orqali keladi.
func (h *WSHandler) Connect(c *gin.Context) {
	token := c.Query("token")
	if token == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "token required"})
		return
	}
	claims, err := utils.ValidateToken(token)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
		return
	}

	conn, err := h.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		return
	}

	client := &services.WSClient{
		Send:   make(chan []byte, 32),
		Role:   claims.Role,
		UserID: claims.UserID,
	}
	h.hub.Register(client)

	// Write pump — kanaldagi xabarlarni yuboradi + ping bilan tirik tutadi.
	go func() {
		ticker := time.NewTicker(45 * time.Second)
		defer func() {
			ticker.Stop()
			conn.Close()
		}()
		for {
			select {
			case msg, ok := <-client.Send:
				if !ok {
					conn.WriteMessage(websocket.CloseMessage, []byte{})
					return
				}
				if err := conn.WriteMessage(websocket.TextMessage, msg); err != nil {
					return
				}
			case <-ticker.C:
				if err := conn.WriteMessage(websocket.PingMessage, nil); err != nil {
					return
				}
			}
		}
	}()

	// Read pump — ulanish yopilishini kuzatadi (kiruvchi xabarlar e'tiborsiz).
	go func() {
		defer h.hub.Unregister(client)
		conn.SetReadLimit(4096)
		for {
			if _, _, err := conn.ReadMessage(); err != nil {
				return
			}
		}
	}()
}
