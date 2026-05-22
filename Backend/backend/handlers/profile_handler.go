package handlers

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"moshn/backend/models"
	"moshn/backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ProfileHandler struct {
	db *gorm.DB
}

func NewProfileHandler(db *gorm.DB) *ProfileHandler {
	return &ProfileHandler{db: db}
}

func (h *ProfileHandler) GetProfile(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	var user models.User
	if err := h.db.First(&user, "id = ?", userID).Error; err != nil {
		utils.NotFound(c, "Foydalanuvchi topilmadi")
		return
	}

	role, _ := c.Get("role")
	result := gin.H{"user": user}

	if role == "mechanic" {
		var mechanic models.Mechanic
		if h.db.Where("user_id = ?", userID).First(&mechanic).Error == nil {
			result["mechanic"] = mechanic
		}
	}

	utils.Success(c, result)
}

func (h *ProfileHandler) UpdateProfile(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	var input struct {
		FullName string `json:"full_name"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	var user models.User
	h.db.First(&user, "id = ?", userID)
	h.db.Model(&user).Updates(map[string]interface{}{"full_name": input.FullName})
	utils.Success(c, user)
}

func (h *ProfileHandler) UpdateLanguage(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	var input struct {
		Language string `json:"language" binding:"required,oneof=uz ru"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	h.db.Model(&models.User{}).Where("id = ?", userID).Update("language", input.Language)
	utils.Success(c, gin.H{"message": "Til o'zgartirildi"})
}

func (h *ProfileHandler) UploadAvatar(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	file, header, err := c.Request.FormFile("avatar")
	if err != nil {
		utils.BadRequest(c, "Rasm topilmadi")
		return
	}
	defer file.Close()

	ext := filepath.Ext(header.Filename)
	filename := fmt.Sprintf("avatars/%s%s", uuid.New().String(), ext)
	fullPath := filepath.Join("/app/uploads", filename)

	os.MkdirAll(filepath.Dir(fullPath), 0755)
	dst, err := os.Create(fullPath)
	if err != nil {
		utils.InternalError(c, "Rasm saqlashda xato")
		return
	}
	defer dst.Close()
	io.Copy(dst, file)

	avatarURL := fmt.Sprintf("/uploads/%s", filename)
	h.db.Model(&models.User{}).Where("id = ?", userID).Update("avatar_url", avatarURL)

	c.JSON(http.StatusOK, gin.H{"data": gin.H{"avatar_url": avatarURL}})
}
