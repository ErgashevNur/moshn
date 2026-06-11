package handlers

import (
	"moshn/backend/services"
	"moshn/backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type BookingHandler struct {
	svc     *services.BookingService
	shopSvc *services.ShopService
}

func NewBookingHandler(svc *services.BookingService, shopSvc *services.ShopService) *BookingHandler {
	return &BookingHandler{svc: svc, shopSvc: shopSvc}
}

func (h *BookingHandler) CreateBooking(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	var input services.CreateBookingInput
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	booking, err := h.svc.CreateBooking(userID, input)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Created(c, booking)
}

func (h *BookingHandler) GetMyBookings(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	p := utils.GetPagination(c)
	status := c.Query("status")

	bookings, total, err := h.svc.GetCustomerBookings(userID, status, p.Limit, p.Offset)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"bookings": bookings, "total": total, "page": p.Page})
}

func (h *BookingHandler) GetBooking(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequest(c, "Noto'g'ri ID")
		return
	}

	booking, err := h.svc.GetBooking(id)
	if err != nil {
		utils.NotFound(c, "Bron topilmadi")
		return
	}
	utils.Success(c, booking)
}

func (h *BookingHandler) CancelBooking(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	id, _ := uuid.Parse(c.Param("id"))

	var input struct {
		Reason string `json:"reason"`
	}
	c.ShouldBindJSON(&input)

	if err := h.svc.CancelByCustomer(id, userID, input.Reason); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"message": "Bron bekor qilindi"})
}

// --- Servis tomonidagi handlerlar ---

func (h *BookingHandler) GetShopBookings(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	p := utils.GetPagination(c)
	status := c.Query("status")

	shop, err := h.shopSvc.GetByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Servis profili topilmadi")
		return
	}

	bookings, total, err := h.svc.GetShopBookings(shop.ID, status, p.Limit, p.Offset)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"bookings": bookings, "total": total, "page": p.Page})
}

func (h *BookingHandler) ConfirmBooking(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	id, _ := uuid.Parse(c.Param("id"))

	shop, err := h.shopSvc.GetByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Servis profili topilmadi")
		return
	}

	booking, err := h.svc.ConfirmByShop(id, shop.ID)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, booking)
}

func (h *BookingHandler) StartBooking(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	id, _ := uuid.Parse(c.Param("id"))

	shop, err := h.shopSvc.GetByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Servis profili topilmadi")
		return
	}

	booking, err := h.svc.StartByShop(id, shop.ID)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, booking)
}

func (h *BookingHandler) CompleteBooking(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	id, _ := uuid.Parse(c.Param("id"))

	shop, err := h.shopSvc.GetByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Servis profili topilmadi")
		return
	}

	booking, err := h.svc.CompleteByShop(id, shop.ID)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, booking)
}

func (h *BookingHandler) ShopCancelBooking(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	id, _ := uuid.Parse(c.Param("id"))

	var input struct {
		Reason string `json:"reason"`
	}
	c.ShouldBindJSON(&input)

	shop, err := h.shopSvc.GetByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Servis profili topilmadi")
		return
	}

	if err := h.svc.CancelByShop(id, shop.ID, input.Reason); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"message": "Bron bekor qilindi"})
}
