package handlers

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"moshn/backend/services"
	"moshn/backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type VehicleHandler struct {
	svc *services.VehicleService
}

func NewVehicleHandler(svc *services.VehicleService) *VehicleHandler {
	return &VehicleHandler{svc: svc}
}

func (h *VehicleHandler) CreateVehicle(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	var input services.CreateVehicleInput
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	vehicle, err := h.svc.CreateVehicle(userID, input)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Created(c, vehicle)
}

func (h *VehicleHandler) GetVehicles(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	vehicles, err := h.svc.GetVehicles(userID)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, vehicles)
}

func (h *VehicleHandler) GetVehicle(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	id, _ := uuid.Parse(c.Param("id"))

	vehicle, err := h.svc.GetVehicle(id, userID)
	if err != nil {
		utils.NotFound(c, err.Error())
		return
	}
	utils.Success(c, vehicle)
}

func (h *VehicleHandler) UpdateVehicle(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	id, _ := uuid.Parse(c.Param("id"))

	var input map[string]interface{}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	vehicle, err := h.svc.UpdateVehicle(id, userID, input)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, vehicle)
}

func (h *VehicleHandler) DeleteVehicle(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	id, _ := uuid.Parse(c.Param("id"))

	if err := h.svc.DeleteVehicle(id, userID); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"message": "Mashina o'chirildi"})
}

func (h *VehicleHandler) OCRVehicle(c *gin.Context) {
	file, header, err := c.Request.FormFile("image")
	if err != nil {
		utils.BadRequest(c, "Rasm topilmadi")
		return
	}
	defer file.Close()

	tmpPath := filepath.Join(os.TempDir(), fmt.Sprintf("ocr_%s%s", uuid.New().String(), filepath.Ext(header.Filename)))
	dst, _ := os.Create(tmpPath)
	io.Copy(dst, file)
	dst.Close()
	defer os.Remove(tmpPath)

	result, err := h.svc.OCRTechpassport(tmpPath)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, result)
}

func (h *VehicleHandler) GetHistory(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	id, _ := uuid.Parse(c.Param("id"))
	p := utils.GetPagination(c)

	records, total, err := h.svc.GetServiceHistory(id, userID, p.Page, p.Limit, p.Offset)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"records": records, "total": total, "page": p.Page, "limit": p.Limit})
}

func (h *VehicleHandler) TransferOwnership(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	id, _ := uuid.Parse(c.Param("id"))

	var input struct {
		NewOwnerPhone string `json:"new_owner_phone" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	if err := h.svc.TransferOwnership(id, userID, input.NewOwnerPhone); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"message": "Egalik o'tkazildi"})
}
