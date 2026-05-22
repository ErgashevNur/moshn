package services

import (
	"crypto/rand"
	"fmt"
	"log"
	"math/big"
	"net/smtp"
	"strings"
)

// EmailService sends OTP and notification emails via SMTP.
//
// If SMTP credentials are not configured, falls back to logging the email
// content to stdout — useful for local development without a Gmail account.
type EmailService struct {
	host     string
	port     string
	username string
	password string
	from     string
}

func NewEmailService(host, port, username, password, from string) *EmailService {
	if from == "" {
		from = username
	}
	return &EmailService{
		host:     host,
		port:     port,
		username: username,
		password: password,
		from:     from,
	}
}

// GenerateOTP returns a 6-digit numeric one-time password.
func GenerateOTP() string {
	var sb strings.Builder
	for i := 0; i < 6; i++ {
		n, err := rand.Int(rand.Reader, big.NewInt(10))
		if err != nil {
			// extremely unlikely; pad with 0
			sb.WriteByte('0')
			continue
		}
		sb.WriteString(n.String())
	}
	return sb.String()
}

// SendOTP delivers a 6-digit OTP to `to`. Returns nil on success.
// If SMTP is not configured, prints to log and returns nil (dev fallback).
func (e *EmailService) SendOTP(to, code, lang string) error {
	subject, body := otpEmailContent(code, lang)
	return e.send(to, subject, body)
}

func (e *EmailService) send(to, subject, body string) error {
	if e.username == "" || e.password == "" {
		log.Printf("[email-dev] To: %s | Subject: %s\n%s", to, subject, body)
		return nil
	}
	addr := fmt.Sprintf("%s:%s", e.host, e.port)
	auth := smtp.PlainAuth("", e.username, e.password, e.host)
	msg := []byte(fmt.Sprintf(
		"From: %s\r\nTo: %s\r\nSubject: %s\r\nMIME-Version: 1.0\r\nContent-Type: text/plain; charset=\"utf-8\"\r\n\r\n%s",
		e.from, to, subject, body,
	))
	if err := smtp.SendMail(addr, auth, e.username, []string{to}, msg); err != nil {
		return fmt.Errorf("smtp send: %w", err)
	}
	return nil
}

func otpEmailContent(code, lang string) (subject, body string) {
	if lang == "ru" {
		return "Moshn — Код подтверждения",
			fmt.Sprintf("Здравствуйте!\n\nВаш код подтверждения: %s\n\nКод действителен 10 минут.\n\nЕсли вы не запрашивали этот код, проигнорируйте письмо.\n\n— Moshn", code)
	}
	return "Moshn — Tasdiqlash kodi",
		fmt.Sprintf("Salom!\n\nSizning tasdiqlash kodingiz: %s\n\nKod 10 daqiqa amal qiladi.\n\nAgar siz so'ramagan bo'lsangiz, ushbu xatni e'tiborsiz qoldiring.\n\n— Moshn", code)
}
