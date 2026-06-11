package services

import (
	"errors"
	"moshn/backend/models"
	"moshn/backend/utils"
	"strings"
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
	Phone        string   `json:"phone" binding:"required"`
	Email        string   `json:"email" binding:"required,email"`
	Password     string   `json:"password" binding:"required,min=6"`
	Role         string   `json:"role" binding:"required,oneof=owner service"`
	FullName     string   `json:"full_name" binding:"required"`
	ShopName     string   `json:"shop_name"`
	Address      string   `json:"address"`
	Latitude     float64  `json:"latitude"`
	Longitude    float64  `json:"longitude"`
	WorkingHours string   `json:"working_hours"`
	ServiceTypes []string `json:"service_types"`
}

type TokenResponse struct {
	AccessToken  string      `json:"access_token"`
	RefreshToken string      `json:"refresh_token"`
	User         models.User `json:"user"`
}

const otpTTL = 10 * time.Minute
const otpResendCooldown = 60 * time.Second

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

	if input.Role == "service" {
		if input.Address == "" {
			input.Address = "Ko'rsatilmagan"
		}
		shop := &models.ShopProfile{
			UserID:             user.ID,
			ShopName:           input.ShopName,
			Address:            input.Address,
			Latitude:           input.Latitude,
			Longitude:          input.Longitude,
			WorkingHours:       input.WorkingHours,
			ServiceTypes:       input.ServiceTypes,
			VerificationStatus: "pending",
		}
		if err := s.db.Create(shop).Error; err != nil {
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

type AdminCreateShopInput struct {
	Phone        string   `json:"phone" binding:"required"`
	Email        string   `json:"email" binding:"required,email"`
	Password     string   `json:"password" binding:"required,min=6"`
	FullName     string   `json:"full_name" binding:"required"`
	ShopName     string   `json:"shop_name"`
	Address      string   `json:"address"`
	Latitude     float64  `json:"latitude"`
	Longitude    float64  `json:"longitude"`
	WorkingHours string   `json:"working_hours"`
	ServiceTypes []string `json:"service_types"`
}

func (s *AuthService) AdminCreateShop(input AdminCreateShopInput) (*models.ShopProfile, error) {
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
		Role:          "service",
		FullName:      input.FullName,
		Language:      "uz",
		EmailVerified: true,
		IsVerified:    true,
	}
	if err := s.db.Create(user).Error; err != nil {
		return nil, err
	}

	if input.Address == "" {
		input.Address = "Ko'rsatilmagan"
	}
	shop := &models.ShopProfile{
		UserID:             user.ID,
		ShopName:           input.ShopName,
		Address:            input.Address,
		Latitude:           input.Latitude,
		Longitude:          input.Longitude,
		WorkingHours:       input.WorkingHours,
		ServiceTypes:       input.ServiceTypes,
		VerificationStatus: "verified",
	}
	if err := s.db.Create(shop).Error; err != nil {
		return nil, err
	}

	s.db.Preload("User").First(shop, "id = ?", shop.ID)
	return shop, nil
}

func (s *AuthService) SendOTP(email string) error {
	email = strings.ToLower(strings.TrimSpace(email))
	var user models.User
	if err := s.db.Where("email = ?", email).First(&user).Error; err != nil {
		return nil
	}
	if user.EmailOTPLastSentAt != nil && time.Since(*user.EmailOTPLastSentAt) < otpResendCooldown {
		return errors.New("iltimos, kod yuborishdan oldin biroz kuting")
	}
	return s.issueOTP(&user)
}

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

// SendOTPByPhone finds-or-creates a user by phone, generates an OTP,
// stores it in the user record, and returns the code (for dev/SMS).
func (s *AuthService) SendOTPByPhone(phone string) (string, error) {
	phone = strings.TrimSpace(phone)
	if phone == "" {
		return "", errors.New("telefon raqamini kiriting")
	}

	var user models.User
	err := s.db.Where("phone = ?", phone).First(&user).Error
	if err == gorm.ErrRecordNotFound {
		// New user — create a stub account; role will be set after OTP
		user = models.User{
			Phone:    phone,
			Email:    phone + "@phone.shina24.uz",
			FullName: "Foydalanuvchi",
			Role:     "",
		}
		if err2 := s.db.Create(&user).Error; err2 != nil {
			return "", err2
		}
	} else if err != nil {
		return "", err
	}

	if user.EmailOTPLastSentAt != nil && time.Since(*user.EmailOTPLastSentAt) < otpResendCooldown {
		return "", errors.New("iltimos, 60 soniya kuting")
	}

	code := GenerateOTP()
	expiresAt := time.Now().Add(otpTTL)
	sentAt := time.Now()
	user.EmailOTPCode = code
	user.EmailOTPExpiresAt = &expiresAt
	user.EmailOTPLastSentAt = &sentAt
	if err := s.db.Save(&user).Error; err != nil {
		return "", err
	}
	// TODO: real SMS gateway integration
	return code, nil
}

// VerifyOTPByPhone checks the code and returns auth tokens.
// new_user=true means the user has no role yet → Flutter routes to role selection.
func (s *AuthService) VerifyOTPByPhone(phone, code string) (map[string]interface{}, error) {
	phone = strings.TrimSpace(phone)
	code = strings.TrimSpace(code)

	var user models.User
	if err := s.db.Where("phone = ?", phone).First(&user).Error; err != nil {
		return nil, errors.New("foydalanuvchi topilmadi")
	}

	// Dev bypass: 000000 always works (remove before production)
	if code != "000000" {
		if user.EmailOTPCode == "" || user.EmailOTPExpiresAt == nil {
			return nil, errors.New("kod topilmadi, qaytadan so'rang")
		}
		if time.Now().After(*user.EmailOTPExpiresAt) {
			return nil, errors.New("kodning muddati o'tdi")
		}
		if user.EmailOTPCode != code {
			return nil, errors.New("kod noto'g'ri")
		}
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

	isNewUser := user.Role == ""
	return map[string]interface{}{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"user":          user,
		"new_user":      isNewUser,
	}, nil
}
