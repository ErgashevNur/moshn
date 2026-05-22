package services

import (
	"errors"
	"moshn/backend/models"
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/gorm"
)

type WarrantyService struct {
	db *gorm.DB
}

func NewWarrantyService(db *gorm.DB) *WarrantyService {
	return &WarrantyService{db: db}
}

type CreateWarrantyInput struct {
	ServiceRecordID string   `json:"service_record_id" binding:"required"`
	Description     string   `json:"description" binding:"required"`
	EvidencePhotos  []string `json:"evidence_photos"`
}

func (s *WarrantyService) CreateClaim(ownerID uuid.UUID, input CreateWarrantyInput) (*models.WarrantyClaim, error) {
	srID, err := uuid.Parse(input.ServiceRecordID)
	if err != nil {
		return nil, errors.New("noto'g'ri servis yozuv ID")
	}

	var record models.ServiceRecord
	if err := s.db.Where("id = ? AND owner_id = ?", srID, ownerID).First(&record).Error; err != nil {
		return nil, errors.New("servis yozuvi topilmadi")
	}

	claim := &models.WarrantyClaim{
		ServiceRecordID: srID,
		OwnerID:         ownerID,
		MechanicID:      record.MechanicID,
		Description:     input.Description,
		EvidencePhotos:  pq.StringArray(input.EvidencePhotos),
		Status:          "open",
	}

	if err := s.db.Create(claim).Error; err != nil {
		return nil, err
	}
	return claim, nil
}

func (s *WarrantyService) GetClaims(ownerID uuid.UUID) ([]models.WarrantyClaim, error) {
	var claims []models.WarrantyClaim
	err := s.db.Where("owner_id = ?", ownerID).
		Preload("Mechanic.User").
		Order("created_at DESC").
		Find(&claims).Error
	return claims, err
}

func (s *WarrantyService) GetClaim(id, ownerID uuid.UUID) (*models.WarrantyClaim, error) {
	var claim models.WarrantyClaim
	err := s.db.Where("id = ? AND owner_id = ?", id, ownerID).
		Preload("Mechanic.User").
		First(&claim).Error
	if err != nil {
		return nil, errors.New("da'vo topilmadi")
	}
	return &claim, nil
}

func (s *WarrantyService) ResolveClaim(id uuid.UUID, status, adminNotes string, amountUZS *int64) (*models.WarrantyClaim, error) {
	var claim models.WarrantyClaim
	if err := s.db.First(&claim, "id = ?", id).Error; err != nil {
		return nil, errors.New("da'vo topilmadi")
	}

	now := time.Now()
	updates := map[string]interface{}{
		"status":      status,
		"admin_notes": adminNotes,
		"resolved_at": now,
	}
	if amountUZS != nil {
		updates["amount_uzs"] = *amountUZS
	}
	s.db.Model(&claim).Updates(updates)
	return &claim, nil
}
