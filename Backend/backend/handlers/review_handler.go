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
