package handlers

import (
	"moshn/backend/services"
	"moshn/backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type PaymentHandler struct {
	svc *services.PaymentService
}

func NewPaymentHandler(svc *services.PaymentService) *PaymentHandler {
	return &PaymentHandler{svc: svc}
}

func (h *PaymentHandler) GetPayment(c *gin.Context) {
	bookingID, err := uuid.Parse(c.Param("booking_id"))
	if err != nil {
		utils.BadRequest(c, "Noto'g'ri booking_id")
		return
	}

	payment, err := h.svc.GetByBooking(bookingID)
	if err != nil {
		utils.NotFound(c, "To'lov topilmadi")
		return
	}
	utils.Success(c, payment)
}

func (h *PaymentHandler) GenerateQR(c *gin.Context) {
	bookingID, err := uuid.Parse(c.Param("booking_id"))
	if err != nil {
		utils.BadRequest(c, "Noto'g'ri booking_id")
		return
	}

	payment, err := h.svc.GenerateQR(bookingID)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, payment)
}

func (h *PaymentHandler) MarkPaid(c *gin.Context) {
	bookingID, err := uuid.Parse(c.Param("booking_id"))
	if err != nil {
		utils.BadRequest(c, "Noto'g'ri booking_id")
		return
	}

	var input struct {
		Method string `json:"method" binding:"required,oneof=cash card_qr installment later"`
		Amount int    `json:"amount"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	payment, err := h.svc.MarkPaid(bookingID, input.Method)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, payment)
}

func (h *PaymentHandler) AddTip(c *gin.Context) {
	bookingID, err := uuid.Parse(c.Param("booking_id"))
	if err != nil {
		utils.BadRequest(c, "Noto'g'ri booking_id")
		return
	}

	var input struct {
		Amount int `json:"amount" binding:"required,min=1000"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	tip, err := h.svc.AddTip(bookingID, input.Amount)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Created(c, tip)
}
