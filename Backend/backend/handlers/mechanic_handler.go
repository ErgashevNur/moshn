package handlers

import (
	"strconv"
	"moshn/backend/services"
	"moshn/backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type MechanicHandler struct {
	svc    *services.MechanicService
	revSvc *services.ReviewService
}

func NewMechanicHandler(svc *services.MechanicService, revSvc *services.ReviewService) *MechanicHandler {
	return &MechanicHandler{svc: svc, revSvc: revSvc}
}

func (h *MechanicHandler) GetMechanics(c *gin.Context) {
	lat, _ := strconv.ParseFloat(c.Query("lat"), 64)
	lng, _ := strconv.ParseFloat(c.Query("lng"), 64)
	minStars, _ := strconv.Atoi(c.Query("min_stars"))
	p := utils.GetPagination(c)

	filter := services.MechanicFilter{
		Category: c.Query("category"),
		Lat:      lat,
		Lng:      lng,
		MinStars: minStars,
		Page:     p.Page,
		Limit:    p.Limit,
		Offset:   p.Offset,
	}

	mechanics, total, err := h.svc.GetMechanics(filter)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"mechanics": mechanics, "total": total, "page": p.Page, "limit": p.Limit})
}

func (h *MechanicHandler) GetMechanic(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequest(c, "Noto'g'ri ID")
		return
	}

	mechanic, err := h.svc.GetMechanic(id)
	if err != nil {
		utils.NotFound(c, "Usta topilmadi")
		return
	}
	utils.Success(c, mechanic)
}

func (h *MechanicHandler) GetMechanicReviews(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	p := utils.GetPagination(c)

	reviews, total, err := h.revSvc.GetMechanicReviews(id, p.Page, p.Limit, p.Offset)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"reviews": reviews, "total": total})
}

func (h *MechanicHandler) UpdateMechanicProfile(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	var input map[string]interface{}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	mechanic, err := h.svc.UpdateMechanicProfile(userID, input)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, mechanic)
}

func (h *MechanicHandler) GetMyServices(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	p := utils.GetPagination(c)

	var mechanic struct{ ID uuid.UUID }
	// Get mechanic ID from user ID via svc
	m, err := h.svc.UpdateMechanicProfile(userID, map[string]interface{}{})
	if err != nil {
		utils.NotFound(c, "Usta profili topilmadi")
		return
	}
	mechanic.ID = m.ID

	records, total, err := h.svc.GetMyServices(mechanic.ID, p.Page, p.Limit, p.Offset)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"records": records, "total": total})
}
