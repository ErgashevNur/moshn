package handlers

import (
	"moshn/backend/services"
	"moshn/backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type ReviewHandler struct {
	svc *services.ReviewService
}

func NewReviewHandler(svc *services.ReviewService) *ReviewHandler {
	return &ReviewHandler{svc: svc}
}

func (h *ReviewHandler) CreateReview(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	var input services.CreateReviewInput
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	review, err := h.svc.CreateReview(userID, input)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Created(c, review)
}

func (h *ReviewHandler) GetReview(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	review, err := h.svc.GetReview(id)
	if err != nil {
		utils.NotFound(c, "Sharh topilmadi")
		return
	}
	utils.Success(c, review)
}

func (h *ReviewHandler) GetShopReviews(c *gin.Context) {
	shopID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequest(c, "Noto'g'ri ID")
		return
	}
	p := utils.GetPagination(c)

	reviews, total, err := h.svc.GetShopReviews(shopID, p.Limit, p.Offset)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"reviews": reviews, "total": total})
}

func (h *ReviewHandler) GetCustomerReviews(c *gin.Context) {
	customerID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		utils.BadRequest(c, "Noto'g'ri ID")
		return
	}
	p := utils.GetPagination(c)

	reviews, total, err := h.svc.GetCustomerReviews(customerID, p.Limit, p.Offset)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, gin.H{"reviews": reviews, "total": total})
}
