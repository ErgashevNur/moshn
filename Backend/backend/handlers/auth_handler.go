package handlers

import (
	"moshn/backend/services"
	"moshn/backend/utils"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	svc *services.AuthService
}

func NewAuthHandler(svc *services.AuthService) *AuthHandler {
	return &AuthHandler{svc: svc}
}

// Register creates a verified user and returns auth tokens immediately.
// MVP simplification: email OTP step is bypassed (see CLAUDE.md).
func (h *AuthHandler) Register(c *gin.Context) {
	var input services.RegisterInput
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	tokens, err := h.svc.Register(input)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	utils.Created(c, tokens)
}

func (h *AuthHandler) Login(c *gin.Context) {
	var input struct {
		Email    string `json:"email"`
		Phone    string `json:"phone"`
		Password string `json:"password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	identifier := input.Email
	if identifier == "" {
		identifier = input.Phone
	}
	if identifier == "" {
		utils.BadRequest(c, "email yoki telefon raqamini kiriting")
		return
	}

	tokens, err := h.svc.Login(identifier, input.Password)
	if err != nil {
		utils.Unauthorized(c, err.Error())
		return
	}

	utils.Success(c, tokens)
}

func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var input struct {
		RefreshToken string `json:"refresh_token" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	tokens, err := h.svc.RefreshToken(input.RefreshToken)
	if err != nil {
		utils.Unauthorized(c, err.Error())
		return
	}

	utils.Success(c, tokens)
}

// SendOTP sends a one-time code to the given phone number.
// MVP: code is also returned in the response for dev testing.
func (h *AuthHandler) SendOTP(c *gin.Context) {
	var input struct {
		Phone string `json:"phone" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	code, err := h.svc.SendOTPByPhone(input.Phone)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	// dev_code is included so testers can verify without real SMS
	utils.Success(c, gin.H{"message": "Kod yuborildi", "dev_code": code})
}

// VerifyOTP checks the one-time code and returns auth tokens.
func (h *AuthHandler) VerifyOTP(c *gin.Context) {
	var input struct {
		Phone string `json:"phone" binding:"required"`
		Code  string `json:"code" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	result, err := h.svc.VerifyOTPByPhone(input.Phone, input.Code)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, result)
}
