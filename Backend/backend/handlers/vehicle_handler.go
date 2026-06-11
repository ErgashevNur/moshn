package handlers

import (
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

// LookupByPlate — plaka bo'yicha avtomobil egasini topish (autosignal funksiyasi)
func (h *VehicleHandler) LookupByPlate(c *gin.Context) {
	plate := c.Param("plate")
	if plate == "" {
		utils.BadRequest(c, "Plaka raqami kerak")
		return
	}

	vehicle, err := h.svc.LookupByPlate(plate)
	if err != nil {
		utils.NotFound(c, err.Error())
		return
	}
	utils.Success(c, vehicle)
}
