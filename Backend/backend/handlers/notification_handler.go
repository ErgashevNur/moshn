package handlers

import (
	"moshn/backend/services"
	"moshn/backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type NotificationHandler struct {
	svc *services.NotificationService
}

func NewNotificationHandler(svc *services.NotificationService) *NotificationHandler {
	return &NotificationHandler{svc: svc}
}

func (h *NotificationHandler) GetNotifications(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	p := utils.GetPagination(c)

	notifs, total, err := h.svc.GetNotifications(userID, p.Page, p.Limit, p.Offset)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"notifications": notifs, "total": total})
}

func (h *NotificationHandler) MarkAsRead(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	id, _ := uuid.Parse(c.Param("id"))

	if err := h.svc.MarkAsRead(id, userID); err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"message": "O'qildi"})
}

func (h *NotificationHandler) RegisterFCMToken(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	var input struct {
		Token    string `json:"token" binding:"required"`
		Platform string `json:"platform" binding:"required,oneof=ios android"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	h.svc.SaveFCMToken(userID, input.Token, input.Platform)
	utils.Success(c, gin.H{"message": "Token saqlandi"})
}
