package services

import (
	"errors"
	"strings"
	"moshn/backend/models"
	"moshn/backend/utils"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AuthService struct {
	db    *gorm.DB
	email *EmailService
}

func NewAuthService(db *gorm.DB, email *EmailService) *AuthService {
	return &AuthService{db: db, email: email}
}

type RegisterInput struct {
	Phone           string   `json:"phone" binding:"required"`
	Email           string   `json:"email" binding:"required,email"`
	Password        string   `json:"password" binding:"required,min=6"`
	Role            string   `json:"role" binding:"required,oneof=owner mechanic"`
	FullName        string   `json:"full_name" binding:"required"`
	WorkshopName    string   `json:"workshop_name"`
	WorkshopAddress string   `json:"workshop_address"`
	Latitude        float64  `json:"latitude"`
	Longitude       float64  `json:"longitude"`
	WorkHours       string   `json:"work_hours"`
	Specialization  []string `json:"specialization"`
}

type TokenResponse struct {
	AccessToken  string      `json:"access_token"`
	RefreshToken string      `json:"refresh_token"`
	User         models.User `json:"user"`
}

// otpTTL is how long a generated OTP code remains valid.
const otpTTL = 10 * time.Minute

// otpResendCooldown prevents spamming; user must wait this long between requests.
const otpResendCooldown = 60 * time.Second

// Register creates a new user (auto-verified for MVP) and returns auth tokens.
// Why auto-verify: the MVP scope (see CLAUDE.md) excludes OTP/SMS — users should
// land in the app immediately after sign-up. Re-introduce email verification when
// SMTP is wired up in production.
func (s *AuthService) Register(input RegisterInput) (*TokenResponse, error) {
	email := strings.ToLower(strings.TrimSpace(input.Email))

	var existing models.User
	if err := s.db.Where("phone = ? OR email = ?", input.Phone, email).First(&existing).Error; err == nil {
		if existing.Phone == input.Phone {
			return nil, errors.New("bu telefon raqami allaqachon ro'yxatdan o'tgan")
		}
		return nil, errors.New("bu email allaqachon ro'yxatdan o'tgan")
	}

	hash, err := utils.HashPassword(input.Password)
	if err != nil {
		return nil, err
	}

	user := &models.User{
		Phone:         input.Phone,
		Email:         email,
		PasswordHash:  hash,
		Role:          input.Role,
		FullName:      input.FullName,
		Language:      "uz",
		EmailVerified: true,
	}

	if err := s.db.Create(user).Error; err != nil {
		return nil, err
	}

	if input.Role == "mechanic" {
		if input.WorkshopAddress == "" {
			input.WorkshopAddress = "Ko'rsatilmagan"
		}
		mechanic := &models.Mechanic{
			UserID:             user.ID,
			WorkshopName:       input.WorkshopName,
			WorkshopAddress:    input.WorkshopAddress,
			Latitude:           input.Latitude,
			Longitude:          input.Longitude,
			WorkHours:          input.WorkHours,
			Specialization:     input.Specialization,
			VerificationStatus: "pending",
		}
		if err := s.db.Create(mechanic).Error; err != nil {
			return nil, err
		}
	}

	accessToken, refreshToken, err := utils.GenerateTokenPair(user.ID, user.Role)
	if err != nil {
		return nil, err
	}
	return &TokenResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         *user,
	}, nil
}

type AdminCreateMechanicInput struct {
	Phone           string   `json:"phone" binding:"required"`
	Email           string   `json:"email" binding:"required,email"`
	Password        string   `json:"password" binding:"required,min=6"`
	FullName        string   `json:"full_name" binding:"required"`
	WorkshopName    string   `json:"workshop_name"`
	WorkshopAddress string   `json:"workshop_address"`
	Latitude        float64  `json:"latitude"`
	Longitude       float64  `json:"longitude"`
	WorkHours       string   `json:"work_hours"`
	Specialization  []string `json:"specialization"`
}

// AdminCreateMechanic — admin panel orqali usta qo'shadi. Register'dan farqi:
// token qaytarmaydi va admin qo'shgani uchun darhol "verified" qilinadi.
func (s *AuthService) AdminCreateMechanic(input AdminCreateMechanicInput) (*models.Mechanic, error) {
	email := strings.ToLower(strings.TrimSpace(input.Email))

	var existing models.User
	if err := s.db.Where("phone = ? OR email = ?", input.Phone, email).First(&existing).Error; err == nil {
		if existing.Phone == input.Phone {
			return nil, errors.New("bu telefon raqami allaqachon ro'yxatdan o'tgan")
		}
		return nil, errors.New("bu email allaqachon ro'yxatdan o'tgan")
	}

	hash, err := utils.HashPassword(input.Password)
	if err != nil {
		return nil, err
	}

	user := &models.User{
		Phone:         input.Phone,
		Email:         email,
		PasswordHash:  hash,
		Role:          "mechanic",
		FullName:      input.FullName,
		Language:      "uz",
		EmailVerified: true,
		IsVerified:    true,
	}
	if err := s.db.Create(user).Error; err != nil {
		return nil, err
	}

	if input.WorkshopAddress == "" {
		input.WorkshopAddress = "Ko'rsatilmagan"
	}
	mechanic := &models.Mechanic{
		UserID:             user.ID,
		WorkshopName:       input.WorkshopName,
		WorkshopAddress:    input.WorkshopAddress,
		Latitude:           input.Latitude,
		Longitude:          input.Longitude,
		WorkHours:          input.WorkHours,
		Specialization:     input.Specialization,
		VerificationStatus: "verified",
	}
	if err := s.db.Create(mechanic).Error; err != nil {
		return nil, err
	}

	s.db.Preload("User").First(mechanic, "id = ?", mechanic.ID)
	return mechanic, nil
}

// SendOTP regenerates and sends a fresh OTP. Use case: user lost the first one
// or it expired. Rate-limited by otpResendCooldown.
func (s *AuthService) SendOTP(email string) error {
	email = strings.ToLower(strings.TrimSpace(email))
	var user models.User
	if err := s.db.Where("email = ?", email).First(&user).Error; err != nil {
		// Don't reveal whether the email exists — return generic OK.
		return nil
	}
	if user.EmailOTPLastSentAt != nil && time.Since(*user.EmailOTPLastSentAt) < otpResendCooldown {
		return errors.New("iltimos, kod yuborishdan oldin biroz kuting")
	}
	return s.issueOTP(&user)
}

// VerifyOTP marks the user's email as verified and returns auth tokens on success.
func (s *AuthService) VerifyOTP(email, code string) (*TokenResponse, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	code = strings.TrimSpace(code)

	var user models.User
	if err := s.db.Where("email = ?", email).First(&user).Error; err != nil {
		return nil, errors.New("foydalanuvchi topilmadi")
	}
	if user.EmailVerified {
		return nil, errors.New("email allaqachon tasdiqlangan")
	}
	if user.EmailOTPCode == "" || user.EmailOTPExpiresAt == nil {
		return nil, errors.New("kod topilmadi, qaytadan so'rang")
	}
	if time.Now().After(*user.EmailOTPExpiresAt) {
		return nil, errors.New("kodning muddati o'tdi")
	}
	if user.EmailOTPCode != code {
		return nil, errors.New("kod noto'g'ri")
	}

	user.EmailVerified = true
	user.EmailOTPCode = ""
	user.EmailOTPExpiresAt = nil
	if err := s.db.Save(&user).Error; err != nil {
		return nil, err
	}

	accessToken, refreshToken, err := utils.GenerateTokenPair(user.ID, user.Role)
	if err != nil {
		return nil, err
	}
	return &TokenResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         user,
	}, nil
}

func (s *AuthService) Login(identifier, password string) (*TokenResponse, error) {
	var user models.User
	// Accept either phone or email in the same field for UX.
	id := strings.TrimSpace(identifier)
	if err := s.db.Where("phone = ? OR email = ?", id, strings.ToLower(id)).First(&user).Error; err != nil {
		return nil, errors.New("email yoki parol noto'g'ri")
	}

	if !utils.CheckPassword(password, user.PasswordHash) {
		return nil, errors.New("email yoki parol noto'g'ri")
	}

	accessToken, refreshToken, err := utils.GenerateTokenPair(user.ID, user.Role)
	if err != nil {
		return nil, err
	}

	return &TokenResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         user,
	}, nil
}

func (s *AuthService) RefreshToken(refreshToken string) (*TokenResponse, error) {
	claims, err := utils.ValidateToken(refreshToken)
	if err != nil {
		return nil, errors.New("invalid refresh token")
	}

	userID, err := uuid.Parse(claims.UserID)
	if err != nil {
		return nil, errors.New("invalid user id")
	}

	var user models.User
	if err := s.db.First(&user, "id = ?", userID).Error; err != nil {
		return nil, errors.New("user not found")
	}

	accessToken, newRefreshToken, err := utils.GenerateTokenPair(user.ID, user.Role)
	if err != nil {
		return nil, err
	}

	return &TokenResponse{
		AccessToken:  accessToken,
		RefreshToken: newRefreshToken,
		User:         user,
	}, nil
}

// issueOTP generates, persists, and emails a fresh OTP to the user.
func (s *AuthService) issueOTP(user *models.User) error {
	code := GenerateOTP()
	expiresAt := time.Now().Add(otpTTL)
	sentAt := time.Now()
	user.EmailOTPCode = code
	user.EmailOTPExpiresAt = &expiresAt
	user.EmailOTPLastSentAt = &sentAt
	if err := s.db.Save(user).Error; err != nil {
		return err
	}
	lang := user.Language
	if lang == "" {
		lang = "uz"
	}
	return s.email.SendOTP(user.Email, code, lang)
}
