package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// Simple in-memory token-bucket rate limiter, keyed by client IP.
// Suitable for MVP. For production behind a load balancer, replace with
// a distributed limiter (Redis) and trust X-Forwarded-For carefully.

type bucket struct {
	tokens     float64
	lastRefill time.Time
}

type RateLimiter struct {
	mu       sync.Mutex
	buckets  map[string]*bucket
	rate     float64 // tokens per second
	capacity float64 // max tokens
}

func NewRateLimiter(requestsPerMinute int) *RateLimiter {
	cap := float64(requestsPerMinute)
	return &RateLimiter{
		buckets:  make(map[string]*bucket),
		rate:     cap / 60.0,
		capacity: cap,
	}
}

func (rl *RateLimiter) allow(key string) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()
	now := time.Now()
	b, ok := rl.buckets[key]
	if !ok {
		rl.buckets[key] = &bucket{tokens: rl.capacity - 1, lastRefill: now}
		return true
	}
	elapsed := now.Sub(b.lastRefill).Seconds()
	b.tokens += elapsed * rl.rate
	if b.tokens > rl.capacity {
		b.tokens = rl.capacity
	}
	b.lastRefill = now
	if b.tokens < 1 {
		return false
	}
	b.tokens--
	return true
}

// Cleanup removes stale buckets that haven't been touched in `idle`.
// Call periodically from a goroutine if memory growth is a concern.
func (rl *RateLimiter) Cleanup(idle time.Duration) {
	rl.mu.Lock()
	defer rl.mu.Unlock()
	now := time.Now()
	for k, b := range rl.buckets {
		if now.Sub(b.lastRefill) > idle {
			delete(rl.buckets, k)
		}
	}
}

// Middleware returns a gin middleware that limits requests per IP.
func (rl *RateLimiter) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()
		if !rl.allow(ip) {
			c.Header("Retry-After", "60")
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"error": "too_many_requests",
			})
			return
		}
		c.Next()
	}
}
