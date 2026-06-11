package handlers

import (
	"moshn/backend/models"
	"moshn/backend/services"
	"moshn/backend/utils"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type AdminHandler struct {
	db          *gorm.DB
	notifSvc    *services.NotificationService
	authSvc     *services.AuthService
}

func NewAdminHandler(db *gorm.DB, notifSvc *services.NotificationService, authSvc *services.AuthService) *AdminHandler {
	return &AdminHandler{db: db, notifSvc: notifSvc, authSvc: authSvc}
}

func (h *AdminHandler) GetStats(c *gin.Context) {
	var stats struct {
		Users        int64 `json:"users"`
		Vehicles     int64 `json:"vehicles"`
		Bookings     int64 `json:"bookings"`
		Shops        int64 `json:"shops"`
		ActiveShops  int64 `json:"active_shops"`
	}
	h.db.Model(&models.User{}).Where("role = 'owner'").Count(&stats.Users)
	h.db.Model(&models.Vehicle{}).Count(&stats.Vehicles)
	h.db.Model(&models.Booking{}).Count(&stats.Bookings)
	h.db.Model(&models.ShopProfile{}).Count(&stats.Shops)
	h.db.Model(&models.ShopProfile{}).Where("verification_status = 'verified'").Count(&stats.ActiveShops)
	utils.Success(c, stats)
}

func (h *AdminHandler) CreateShop(c *gin.Context) {
	var input services.AdminCreateShopInput
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	shop, err := h.authSvc.AdminCreateShop(input)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Created(c, shop)
}

func (h *AdminHandler) ListShops(c *gin.Context) {
	status := c.DefaultQuery("status", "")
	p := utils.GetPagination(c)

	query := h.db.Model(&models.ShopProfile{}).Preload("User")
	if status != "" {
		query = query.Where("verification_status = ?", status)
	}

	var total int64
	query.Count(&total)

	var shops []models.ShopProfile
	query.Order("created_at DESC").Limit(p.Limit).Offset(p.Offset).Find(&shops)
	utils.Success(c, gin.H{"shops": shops, "total": total})
}

func (h *AdminHandler) VerifyShop(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))

	var input struct {
		Status string `json:"status" binding:"required,oneof=verified rejected"`
		Notes  string `json:"notes"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	h.db.Model(&models.ShopProfile{}).Where("id = ?", id).Updates(map[string]interface{}{
		"verification_status": input.Status,
		"verification_notes":  input.Notes,
	})

	var shop models.ShopProfile
	h.db.Preload("User").First(&shop, "id = ?", id)

	msg := "Profilingiz tasdiqlandi"
	if input.Status == "rejected" {
		msg = "Profilingiz rad etildi"
	}
	h.notifSvc.SendToUser(shop.UserID, "Verifikatsiya", msg, "verification", id.String())

	utils.Success(c, shop)
}

func (h *AdminHandler) ListBookings(c *gin.Context) {
	status := c.DefaultQuery("status", "")
	p := utils.GetPagination(c)

	query := h.db.Model(&models.Booking{}).
		Preload("Customer").Preload("Shop.User").
		Preload("Vehicle").Preload("ServiceType")
	if status != "" {
		query = query.Where("status = ?", status)
	}

	var total int64
	query.Count(&total)

	var bookings []models.Booking
	query.Order("created_at DESC").Limit(p.Limit).Offset(p.Offset).Find(&bookings)
	utils.Success(c, gin.H{"bookings": bookings, "total": total})
}

func (h *AdminHandler) ListUsers(c *gin.Context) {
	search := c.Query("search")
	role := c.Query("role")
	p := utils.GetPagination(c)

	query := h.db.Model(&models.User{})
	if search != "" {
		query = query.Where("full_name ILIKE ? OR phone ILIKE ?", "%"+search+"%", "%"+search+"%")
	}
	if role != "" {
		query = query.Where("role = ?", role)
	}

	var total int64
	query.Count(&total)

	var users []models.User
	query.Order("created_at DESC").Limit(p.Limit).Offset(p.Offset).Find(&users)
	utils.Success(c, gin.H{"users": users, "total": total})
}

func (h *AdminHandler) ListVehicles(c *gin.Context) {
	search := c.Query("search")
	p := utils.GetPagination(c)

	query := h.db.Model(&models.Vehicle{}).Preload("Owner")
	if search != "" {
		query = query.Where("plate ILIKE ?", "%"+search+"%")
	}

	var total int64
	query.Count(&total)

	var vehicles []models.Vehicle
	query.Order("created_at DESC").Limit(p.Limit).Offset(p.Offset).Find(&vehicles)
	utils.Success(c, gin.H{"vehicles": vehicles, "total": total})
}

func (h *AdminHandler) ListReviews(c *gin.Context) {
	p := utils.GetPagination(c)
	reviewType := c.DefaultQuery("type", "")

	query := h.db.Model(&models.Review{}).Preload("Author")
	if reviewType != "" {
		query = query.Where("review_type = ?", reviewType)
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

func (h *AdminHandler) SendBroadcastNotification(c *gin.Context) {
	var input struct {
		Title string `json:"title" binding:"required"`
		Body  string `json:"body" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	h.notifSvc.BroadcastToAll(input.Title, input.Body)
	utils.Success(c, gin.H{"message": "Bildirishnoma yuborildi"})
}

// --- Mavsum bildirshnomalar ---

func (h *AdminHandler) ListSeasonalRules(c *gin.Context) {
	var rules []models.SeasonalRule
	h.db.Order("send_month ASC, send_day ASC").Find(&rules)
	utils.Success(c, rules)
}

func (h *AdminHandler) CreateSeasonalRule(c *gin.Context) {
	var input struct {
		Name      string `json:"name" binding:"required"`
		SendMonth int    `json:"send_month" binding:"required,min=1,max=12"`
		SendDay   int    `json:"send_day" binding:"required,min=1,max=31"`
		MessageUz string `json:"message_uz" binding:"required"`
		MessageRu string `json:"message_ru" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	rule := &models.SeasonalRule{
		Name:      input.Name,
		SendMonth: input.SendMonth,
		SendDay:   input.SendDay,
		MessageUz: input.MessageUz,
		MessageRu: input.MessageRu,
		IsActive:  true,
	}
	h.db.Create(rule)
	utils.Created(c, rule)
}

func (h *AdminHandler) UpdateSeasonalRule(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))

	var input map[string]interface{}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	h.db.Model(&models.SeasonalRule{}).Where("id = ?", id).Updates(input)

	var rule models.SeasonalRule
	h.db.First(&rule, "id = ?", id)
	utils.Success(c, rule)
}

func (h *AdminHandler) SendSeasonalNow(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))

	var rule models.SeasonalRule
	if err := h.db.First(&rule, "id = ?", id).Error; err != nil {
		utils.NotFound(c, "Qoida topilmadi")
		return
	}

	h.notifSvc.BroadcastSeasonal(&rule)

	now := time.Now()
	h.db.Model(&rule).Update("last_sent_at", &now)
	utils.Success(c, gin.H{"message": "Mavsum bildirshnomalari yuborildi"})
}

// ListServiceTypes — xizmat turlari katalogi
func (h *AdminHandler) ListServiceTypes(c *gin.Context) {
	var types []models.ServiceType
	h.db.Where("is_active = true").Order("name_uz ASC").Find(&types)
	utils.Success(c, types)
}

func (h *AdminHandler) CreateServiceType(c *gin.Context) {
	var input struct {
		Slug      string `json:"slug" binding:"required"`
		NameUz    string `json:"name_uz" binding:"required"`
		NameRu    string `json:"name_ru" binding:"required"`
		Icon      string `json:"icon"`
		BasePrice int    `json:"base_price"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	st := &models.ServiceType{
		Slug:      input.Slug,
		NameUz:    input.NameUz,
		NameRu:    input.NameRu,
		Icon:      input.Icon,
		BasePrice: input.BasePrice,
		IsActive:  true,
	}
	h.db.Create(st)
	utils.Created(c, st)
}
