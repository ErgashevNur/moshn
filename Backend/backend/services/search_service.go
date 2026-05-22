package services

import (
	"moshn/backend/models"

	"gorm.io/gorm"
)

type SearchService struct {
	db *gorm.DB
}

func NewSearchService(db *gorm.DB) *SearchService {
	return &SearchService{db: db}
}

type SearchResult struct {
	Vehicles  []models.Vehicle  `json:"vehicles"`
	Mechanics []models.Mechanic `json:"mechanics"`
}

func (s *SearchService) Search(query string) (*SearchResult, error) {
	result := &SearchResult{}

	like := "%" + query + "%"

	s.db.Where("current_plate ILIKE ? OR vin ILIKE ?", like, like).
		Limit(10).Find(&result.Vehicles)

	s.db.Preload("User").
		Joins("JOIN users ON users.id = mechanics.user_id").
		Where("users.full_name ILIKE ? OR mechanics.workshop_name ILIKE ? OR mechanics.workshop_address ILIKE ?", like, like, like).
		Where("mechanics.verification_status = 'verified'").
		Limit(10).Find(&result.Mechanics)

	return result, nil
}
