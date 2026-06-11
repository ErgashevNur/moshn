package services

import (
	"errors"
	"moshn/backend/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ReviewService struct {
	db *gorm.DB
}

func NewReviewService(db *gorm.DB) *ReviewService {
	return &ReviewService{db: db}
}

type CreateReviewInput struct {
	BookingID  string `json:"booking_id" binding:"required"`
	Rating     int    `json:"rating" binding:"required,min=1,max=5"`
	Comment    string `json:"comment"`
	ReviewType string `json:"review_type" binding:"required,oneof=owner_to_shop shop_to_owner"`
}

func (s *ReviewService) CreateReview(authorID uuid.UUID, input CreateReviewInput) (*models.Review, error) {
	bookingID, err := uuid.Parse(input.BookingID)
	if err != nil {
		return nil, errors.New("noto'g'ri booking_id")
	}

	var booking models.Booking
	if err := s.db.Where("id = ? AND status = 'completed'", bookingID).First(&booking).Error; err != nil {
		return nil, errors.New("tugallangan bron topilmadi")
	}

	// Ruxsat tekshiruvi
	if input.ReviewType == "owner_to_shop" && booking.CustomerID != authorID {
		return nil, errors.New("faqat bron egasi sharh yoza oladi")
	}
	if input.ReviewType == "shop_to_owner" {
		var shop models.ShopProfile
		if err := s.db.Where("id = ? AND user_id = ?", booking.ShopID, authorID).First(&shop).Error; err != nil {
			return nil, errors.New("faqat servis egasi sharh yoza oladi")
		}
	}

	// Takroran sharh yozishni oldini olish
	var existing models.Review
	if s.db.Where("booking_id = ? AND review_type = ?", bookingID, input.ReviewType).First(&existing).Error == nil {
		return nil, errors.New("bu bron uchun sharh allaqachon yozilgan")
	}

	targetID := booking.ShopID
	if input.ReviewType == "shop_to_owner" {
		targetID = booking.CustomerID
	}

	review := &models.Review{
		BookingID:  bookingID,
		AuthorID:   authorID,
		TargetID:   targetID,
		ReviewType: input.ReviewType,
		Rating:     input.Rating,
		Comment:    input.Comment,
	}

	if err := s.db.Create(review).Error; err != nil {
		return nil, err
	}

	if input.ReviewType == "owner_to_shop" {
		s.updateShopRating(booking.ShopID)
	}

	s.db.Preload("Author").First(review, "id = ?", review.ID)
	return review, nil
}

func (s *ReviewService) updateShopRating(shopID uuid.UUID) {
	var result struct {
		Avg   float64
		Count int
	}
	s.db.Model(&models.Review{}).
		Select("AVG(rating) as avg, COUNT(*) as count").
		Where("target_id = ? AND review_type = 'owner_to_shop'", shopID).
		Scan(&result)

	s.db.Model(&models.ShopProfile{}).Where("id = ?", shopID).
		Updates(map[string]interface{}{
			"rating_avg":   result.Avg,
			"rating_count": result.Count,
		})
}

func (s *ReviewService) GetShopReviews(shopID uuid.UUID, limit, offset int) ([]models.Review, int64, error) {
	var reviews []models.Review
	var total int64

	s.db.Model(&models.Review{}).
		Where("target_id = ? AND review_type = 'owner_to_shop'", shopID).Count(&total)
	err := s.db.Where("target_id = ? AND review_type = 'owner_to_shop'", shopID).
		Preload("Author").
		Order("created_at DESC").
		Limit(limit).Offset(offset).
		Find(&reviews).Error

	return reviews, total, err
}

func (s *ReviewService) GetCustomerReviews(customerID uuid.UUID, limit, offset int) ([]models.Review, int64, error) {
	var reviews []models.Review
	var total int64

	s.db.Model(&models.Review{}).
		Where("target_id = ? AND review_type = 'shop_to_owner'", customerID).Count(&total)
	err := s.db.Where("target_id = ? AND review_type = 'shop_to_owner'", customerID).
		Preload("Author").
		Order("created_at DESC").
		Limit(limit).Offset(offset).
		Find(&reviews).Error

	return reviews, total, err
}

func (s *ReviewService) GetReview(id uuid.UUID) (*models.Review, error) {
	var review models.Review
	err := s.db.Preload("Author").First(&review, "id = ?", id).Error
	return &review, err
}
