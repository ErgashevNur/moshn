package handlers

import (
	"moshn/backend/services"
	"moshn/backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type WarrantyHandler struct {
	svc *services.WarrantyService
}

func NewWarrantyHandler(svc *services.WarrantyService) *WarrantyHandler {
	return &WarrantyHandler{svc: svc}
}

func (h *WarrantyHandler) CreateClaim(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	var input services.CreateWarrantyInput
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	claim, err := h.svc.CreateClaim(userID, input)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Created(c, claim)
}

func (h *WarrantyHandler) GetClaims(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	claims, err := h.svc.GetClaims(userID)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, claims)
}

func (h *WarrantyHandler) GetClaim(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	id, _ := uuid.Parse(c.Param("id"))

	claim, err := h.svc.GetClaim(id, userID)
	if err != nil {
		utils.NotFound(c, err.Error())
		return
	}
	utils.Success(c, claim)
}
