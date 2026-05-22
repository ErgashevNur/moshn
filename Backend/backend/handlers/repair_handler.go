package handlers

import (
	"moshn/backend/services"
	"moshn/backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type RepairHandler struct {
	svc *services.RepairService
}

func NewRepairHandler(svc *services.RepairService) *RepairHandler {
	return &RepairHandler{svc: svc}
}

// Create — mijoz tamirlash so'rovini yuboradi (ixtiyoriy usta tanlab).
func (h *RepairHandler) Create(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	var input services.CreateRepairInput
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	req, err := h.svc.Create(userID, input)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Created(c, req)
}

// ListMine — mijozning o'z tamirlash so'rovlari.
func (h *RepairHandler) ListMine(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	reqs, err := h.svc.ListMine(userID)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"requests": reqs})
}

// AdminList — operator tamirlash so'rovlari ro'yxatini ko'radi.
func (h *RepairHandler) AdminList(c *gin.Context) {
	status := c.DefaultQuery("status", "new")
	p := utils.GetPagination(c)

	reqs, total, err := h.svc.AdminList(status, p.Limit, p.Offset)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"requests": reqs, "total": total})
}

// AdminAssign — operator so'rovni ustaga yo'naltiradi.
func (h *RepairHandler) AdminAssign(c *gin.Context) {
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

// AdminUpdateStatus — operator so'rov holatini yangilaydi.
func (h *RepairHandler) AdminUpdateStatus(c *gin.Context) {
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
