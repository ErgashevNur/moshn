package handlers

import (
	"moshn/backend/models"
	"moshn/backend/services"
	"moshn/backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AdminHandler struct {
	db           *gorm.DB
	notifService *services.NotificationService
	warrantySvc  *services.WarrantyService
	authSvc      *services.AuthService
}

func NewAdminHandler(db *gorm.DB, notifSvc *services.NotificationService, warrantySvc *services.WarrantyService, authSvc *services.AuthService) *AdminHandler {
	return &AdminHandler{db: db, notifService: notifSvc, warrantySvc: warrantySvc, authSvc: authSvc}
}

// CreateMechanic — admin panel orqali yangi usta qo'shadi.
func (h *AdminHandler) CreateMechanic(c *gin.Context) {
	var input services.AdminCreateMechanicInput
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	mechanic, err := h.authSvc.AdminCreateMechanic(input)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Created(c, mechanic)
}

func (h *AdminHandler) GetStats(c *gin.Context) {
	var stats struct {
		Users    int64 `json:"users"`
		Vehicles int64 `json:"vehicles"`
		Services int64 `json:"services"`
		Mechanics int64 `json:"mechanics"`
	}
	h.db.Model(&models.User{}).Count(&stats.Users)
	h.db.Model(&models.Vehicle{}).Count(&stats.Vehicles)
	h.db.Model(&models.ServiceRecord{}).Count(&stats.Services)
	h.db.Model(&models.Mechanic{}).Where("verification_status = 'verified'").Count(&stats.Mechanics)
	utils.Success(c, stats)
}

func (h *AdminHandler) ListMechanics(c *gin.Context) {
	status := c.DefaultQuery("status", "")
	p := utils.GetPagination(c)

	query := h.db.Model(&models.Mechanic{}).Preload("User")
	if status != "" {
		query = query.Where("verification_status = ?", status)
	}

	var total int64
	query.Count(&total)

	var mechanics []models.Mechanic
	query.Limit(p.Limit).Offset(p.Offset).Find(&mechanics)
	utils.Success(c, gin.H{"mechanics": mechanics, "total": total})
}

func (h *AdminHandler) VerifyMechanic(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))

	var input struct {
		Status    string `json:"status" binding:"required,oneof=verified rejected"`
		StarLevel int    `json:"star_level"`
		Notes     string `json:"notes"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	updates := map[string]interface{}{
		"verification_status": input.Status,
		"verification_notes":  input.Notes,
	}
	if input.StarLevel > 0 {
		updates["star_level"] = input.StarLevel
	}

	h.db.Model(&models.Mechanic{}).Where("id = ?", id).Updates(updates)

	var mechanic models.Mechanic
	h.db.Preload("User").First(&mechanic, "id = ?", id)

	msg := "Profilingiz tasdiqlandi"
	if input.Status == "rejected" {
		msg = "Profilingiz rad etildi"
	}
	h.notifService.SendToUser(mechanic.UserID, "Verifikatsiya", msg, "verification", id.String())

	utils.Success(c, mechanic)
}

func (h *AdminHandler) ListServices(c *gin.Context) {
	status := c.DefaultQuery("status", "")
	p := utils.GetPagination(c)

	query := h.db.Model(&models.ServiceRecord{}).Preload("Vehicle").Preload("Mechanic.User").Preload("Owner")
	if status != "" {
		query = query.Where("status = ?", status)
	}

	var total int64
	query.Count(&total)

	var records []models.ServiceRecord
	query.Order("created_at DESC").Limit(p.Limit).Offset(p.Offset).Find(&records)
	utils.Success(c, gin.H{"records": records, "total": total})
}

func (h *AdminHandler) ListUsers(c *gin.Context) {
	search := c.Query("search")
	p := utils.GetPagination(c)

	query := h.db.Model(&models.User{})
	if search != "" {
		query = query.Where("full_name ILIKE ? OR phone ILIKE ?", "%"+search+"%", "%"+search+"%")
	}

	var total int64
	query.Count(&total)

	var users []models.User
	query.Limit(p.Limit).Offset(p.Offset).Find(&users)
	utils.Success(c, gin.H{"users": users, "total": total})
}

func (h *AdminHandler) ListVehicles(c *gin.Context) {
	search := c.Query("search")
	p := utils.GetPagination(c)

	query := h.db.Model(&models.Vehicle{}).Preload("Owner")
	if search != "" {
		query = query.Where("vin ILIKE ? OR current_plate ILIKE ?", "%"+search+"%", "%"+search+"%")
	}

	var total int64
	query.Count(&total)

	var vehicles []models.Vehicle
	query.Limit(p.Limit).Offset(p.Offset).Find(&vehicles)
	utils.Success(c, gin.H{"vehicles": vehicles, "total": total})
}

func (h *AdminHandler) ListReviews(c *gin.Context) {
	p := utils.GetPagination(c)
	isModerated := c.DefaultQuery("moderated", "false")

	query := h.db.Model(&models.Review{}).Preload("Owner").Preload("Mechanic.User")
	if isModerated == "false" {
		query = query.Where("is_moderated = false")
	}

	var total int64
	query.Count(&total)

	var reviews []models.Review
	query.Order("created_at DESC").Limit(p.Limit).Offset(p.Offset).Find(&reviews)
	utils.Success(c, gin.H{"reviews": reviews, "total": total})
}

func (h *AdminHandler) ModerateReview(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	var input struct {
		Approve bool `json:"approve"`
	}
	c.ShouldBindJSON(&input)

	if input.Approve {
		h.db.Model(&models.Review{}).Where("id = ?", id).Update("is_moderated", true)
	} else {
		h.db.Where("id = ?", id).Delete(&models.Review{})
	}
	utils.Success(c, gin.H{"message": "Sharh moderatsiya qilindi"})
}

func (h *AdminHandler) ListWarrantyClaims(c *gin.Context) {
	status := c.DefaultQuery("status", "open")
	p := utils.GetPagination(c)

	var claims []models.WarrantyClaim
	var total int64
	h.db.Model(&models.WarrantyClaim{}).Where("status = ?", status).Count(&total)
	h.db.Where("status = ?", status).
		Preload("Owner").Preload("Mechanic.User").
		Limit(p.Limit).Offset(p.Offset).
		Find(&claims)
	utils.Success(c, gin.H{"claims": claims, "total": total})
}

func (h *AdminHandler) ResolveWarrantyClaim(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	var input struct {
		Status     string `json:"status" binding:"required,oneof=approved rejected"`
		AdminNotes string `json:"admin_notes"`
		AmountUZS  *int64 `json:"amount_uzs"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	claim, err := h.warrantySvc.ResolveClaim(id, input.Status, input.AdminNotes, input.AmountUZS)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, claim)
}

func (h *AdminHandler) SendBroadcastNotification(c *gin.Context) {
	var input struct {
		Target string `json:"target"` // "all" or phone number
		Title  string `json:"title" binding:"required"`
		Body   string `json:"body" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	if input.Target == "all" || input.Target == "" {
		h.notifService.BroadcastToAll(input.Title, input.Body)
	} else {
		h.notifService.BroadcastToPhone(input.Target, input.Title, input.Body)
	}
	utils.Success(c, gin.H{"message": "Bildirishnoma yuborildi"})
}
