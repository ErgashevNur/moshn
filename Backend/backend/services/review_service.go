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
	ServiceRecordID string `json:"service_record_id" binding:"required"`
	Rating          int    `json:"rating" binding:"required,min=1,max=5"`
	Comment         string `json:"comment"`
}

func (s *ReviewService) CreateReview(ownerID uuid.UUID, input CreateReviewInput) (*models.Review, error) {
	srID, err := uuid.Parse(input.ServiceRecordID)
	if err != nil {
		return nil, errors.New("noto'g'ri servis yozuv ID")
	}

	var record models.ServiceRecord
	if err := s.db.Where("id = ? AND owner_id = ? AND status IN ('confirmed','auto_confirmed')", srID, ownerID).
		First(&record).Error; err != nil {
		return nil, errors.New("tasdiqlangan servis yozuvi topilmadi")
	}

	var existing models.Review
	if s.db.Where("service_record_id = ?", srID).First(&existing).Error == nil {
		return nil, errors.New("bu servis uchun sharh allaqachon yozilgan")
	}

	review := &models.Review{
		ServiceRecordID: srID,
		MechanicID:      record.MechanicID,
		OwnerID:         ownerID,
		Rating:          input.Rating,
		Comment:         input.Comment,
	}

	if err := s.db.Create(review).Error; err != nil {
		return nil, err
	}

	s.updateMechanicRating(record.MechanicID)
	return review, nil
}

func (s *ReviewService) updateMechanicRating(mechanicID uuid.UUID) {
	var result struct {
		Avg   float64
		Count int
	}
	s.db.Model(&models.Review{}).
		Select("AVG(rating) as avg, COUNT(*) as count").
		Where("mechanic_id = ?", mechanicID).
		Scan(&result)

	s.db.Model(&models.Mechanic{}).Where("id = ?", mechanicID).
		Updates(map[string]interface{}{
			"rating_avg":   result.Avg,
			"rating_count": result.Count,
		})
}

func (s *ReviewService) GetReview(id uuid.UUID) (*models.Review, error) {
	var review models.Review
	err := s.db.Preload("Owner").Preload("Mechanic.User").First(&review, "id = ?", id).Error
	return &review, err
}

func (s *ReviewService) GetMechanicReviews(mechanicID uuid.UUID, page, limit, offset int) ([]models.Review, int64, error) {
	var reviews []models.Review
	var total int64

	s.db.Model(&models.Review{}).Where("mechanic_id = ?", mechanicID).Count(&total)
	err := s.db.Where("mechanic_id = ?", mechanicID).
		Preload("Owner").
		Order("created_at DESC").
		Limit(limit).Offset(offset).
		Find(&reviews).Error

	return reviews, total, err
}
