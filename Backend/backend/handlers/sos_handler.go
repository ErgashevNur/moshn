package handlers

import (
	"moshn/backend/services"
	"moshn/backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type SosHandler struct {
	svc *services.SosService
}

func NewSosHandler(svc *services.SosService) *SosHandler {
	return &SosHandler{svc: svc}
}

// CreateRequest — mashina egasi favqulodda yordam so'rovini yuboradi.
func (h *SosHandler) CreateRequest(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	var input services.CreateSosInput
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	req, err := h.svc.CreateRequest(userID, input)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Created(c, req)
}

// ListMine — mijoz o'z SOS so'rovlari ro'yxati va holatini ko'radi.
func (h *SosHandler) ListMine(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	requests, err := h.svc.ListMine(userID)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"requests": requests})
}

// AdminList — admin/operator SOS so'rovlari ro'yxatini ko'radi.
func (h *SosHandler) AdminList(c *gin.Context) {
	status := c.DefaultQuery("status", "new")
	p := utils.GetPagination(c)

	requests, total, err := h.svc.ListRequests(status, p.Limit, p.Offset)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"requests": requests, "total": total})
}

// AdminUpdateStatus — admin SOS so'rovi holatini yangilaydi.
func (h *SosHandler) AdminUpdateStatus(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	var input struct {
		Status     string `json:"status" binding:"required,oneof=new in_progress resolved cancelled"`
		AdminNotes string `json:"admin_notes"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	req, err := h.svc.UpdateStatus(id, input.Status, input.AdminNotes)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, req)
}

// AdminAssign — admin SOS so'rovini ustaga yo'naltiradi.
func (h *SosHandler) AdminAssign(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	var input struct {
		MechanicID string `json:"mechanic_id" binding:"required"`
		AdminNotes string `json:"admin_notes"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	mechanicID, err := uuid.Parse(input.MechanicID)
	if err != nil {
		utils.BadRequest(c, "Noto'g'ri usta ID")
		return
	}

	req, err := h.svc.AssignMechanic(id, mechanicID, input.AdminNotes)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, req)
}
