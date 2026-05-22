package config

import (
	"os"
	"strings"

	"github.com/joho/godotenv"
)

type Config struct {
	DatabaseURL      string
	JWTSecret        string
	ClaudeAPIKey     string
	UzbekVoiceAPIKey string
	FCMServerKey     string
	YandexMapsKey    string
	Port             string
	GinMode          string
	AllowedOrigins   []string

	SMTPHost     string
	SMTPPort     string
	SMTPUser     string
	SMTPPassword string
	SMTPFrom     string
}

func Load() *Config {
	_ = godotenv.Load()

	originsRaw := getEnv("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:8080")
	var origins []string
	for _, o := range strings.Split(originsRaw, ",") {
		o = strings.TrimSpace(o)
		if o != "" {
			origins = append(origins, o)
		}
	}

	return &Config{
		DatabaseURL:      getEnv("DATABASE_URL", "postgres://moshn:moshn_dev@localhost:5432/moshn?sslmode=disable"),
		JWTSecret:        getEnv("JWT_SECRET", "moshn-secret-key"),
		ClaudeAPIKey:     getEnv("CLAUDE_API_KEY", ""),
		UzbekVoiceAPIKey: getEnv("UZBEKVOICE_API_KEY", ""),
		FCMServerKey:     getEnv("FCM_SERVER_KEY", ""),
		YandexMapsKey:    getEnv("YANDEX_MAPS_API_KEY", ""),
		Port:             getEnv("PORT", "8080"),
		GinMode:          getEnv("GIN_MODE", "debug"),
		AllowedOrigins:   origins,
		SMTPHost:         getEnv("SMTP_HOST", "smtp.gmail.com"),
		SMTPPort:         getEnv("SMTP_PORT", "587"),
		SMTPUser:         getEnv("SMTP_USER", ""),
		SMTPPassword:     getEnv("SMTP_PASSWORD", ""),
		SMTPFrom:         getEnv("SMTP_FROM", ""),
	}
}

func getEnv(key, defaultVal string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return defaultVal
}
