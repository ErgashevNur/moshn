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

// SendOTP requests a (re)send of the email verification code.
func (h *AuthHandler) SendOTP(c *gin.Context) {
	var input struct {
		Email string `json:"email" binding:"required,email"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	if err := h.svc.SendOTP(input.Email); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"message": "Kod yuborildi"})
}

// VerifyOTP confirms the email and returns auth tokens.
func (h *AuthHandler) VerifyOTP(c *gin.Context) {
	var input struct {
		Email string `json:"email" binding:"required,email"`
		Code  string `json:"code" binding:"required,len=6"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	tokens, err := h.svc.VerifyOTP(input.Email, input.Code)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, tokens)
}
