package handlers

import (
	"moshn/backend/services"
	"moshn/backend/utils"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type ShopHandler struct {
	svc    *services.ShopService
	revSvc *services.ReviewService
}

func NewShopHandler(svc *services.ShopService, revSvc *services.ReviewService) *ShopHandler {
	return &ShopHandler{svc: svc, revSvc: revSvc}
}

func (h *ShopHandler) GetShops(c *gin.Context) {
	lat, _ := strconv.ParseFloat(c.Query("lat"), 64)
	lng, _ := strconv.ParseFloat(c.Query("lng"), 64)
	p := utils.GetPagination(c)

	filter := services.ShopFilter{
		ServiceType: c.Query("service_type"),
		Lat:         lat,
		Lng:         lng,
		Limit:       p.Limit,
		Offset:      p.Offset,
	}

	shops, total, err := h.svc.GetShops(filter)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"shops": shops, "total": total, "page": p.Page, "limit": p.Limit})
}

func (h *ShopHandler) GetShop(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequest(c, "Noto'g'ri ID")
		return
	}

	shop, err := h.svc.GetShop(id)
	if err != nil {
		utils.NotFound(c, "Servis topilmadi")
		return
	}
	utils.Success(c, shop)
}

func (h *ShopHandler) GetShopReviews(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	p := utils.GetPagination(c)

	reviews, total, err := h.revSvc.GetShopReviews(id, p.Limit, p.Offset)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"reviews": reviews, "total": total})
}

func (h *ShopHandler) GetMyShop(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	shop, err := h.svc.GetByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Servis profili topilmadi")
		return
	}
	utils.Success(c, shop)
}

func (h *ShopHandler) UpdateProfile(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	var input map[string]interface{}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	shop, err := h.svc.UpdateProfile(userID, input)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, shop)
}

func (h *ShopHandler) GetCustomers(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	p := utils.GetPagination(c)

	shop, err := h.svc.GetByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Servis profili topilmadi")
		return
	}

	cards, total, err := h.svc.GetCustomers(shop.ID, p.Page, p.Limit, p.Offset)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"customers": cards, "total": total, "page": p.Page})
}

func (h *ShopHandler) GetCustomerCard(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	customerID, err := uuid.Parse(c.Param("customer_id"))
	if err != nil {
		utils.BadRequest(c, "Noto'g'ri customer_id")
		return
	}

	shop, err := h.svc.GetByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Servis profili topilmadi")
		return
	}

	card, err := h.svc.GetCustomerCard(shop.ID, customerID)
	if err != nil {
		utils.NotFound(c, "Mijoz kartochkasi topilmadi")
		return
	}
	utils.Success(c, card)
}

func (h *ShopHandler) UpdateCustomerCard(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	customerID, _ := uuid.Parse(c.Param("customer_id"))

	var input map[string]interface{}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	shop, err := h.svc.GetByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Servis profili topilmadi")
		return
	}

	// Faqat ruxsat etilgan maydonlar
	allowed := map[string]interface{}{}
	if v, ok := input["is_vip"]; ok {
		allowed["is_vip"] = v
	}
	if v, ok := input["notes"]; ok {
		allowed["notes"] = v
	}

	card, err := h.svc.UpdateCustomerCard(shop.ID, customerID, allowed)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, card)
}
