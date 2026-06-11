package services

import (
	"errors"
	"moshn/backend/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type VehicleService struct {
	db *gorm.DB
}

func NewVehicleService(db *gorm.DB) *VehicleService {
	return &VehicleService{db: db}
}

type CreateVehicleInput struct {
	Plate    string `json:"plate" binding:"required"`
	Make     string `json:"make"`
	Model    string `json:"model"`
	Year     int    `json:"year"`
	Color    string `json:"color"`
	PhotoURL string `json:"photo_url"`
}

func (s *VehicleService) CreateVehicle(ownerID uuid.UUID, input CreateVehicleInput) (*models.Vehicle, error) {
	var count int64
	s.db.Model(&models.Vehicle{}).Where("owner_id = ?", ownerID).Count(&count)
	if count >= 5 {
		return nil, errors.New("maksimal 5 ta mashina ro'yxatga olish mumkin")
	}

	vehicle := &models.Vehicle{
		Plate:    input.Plate,
		OwnerID:  ownerID,
		Make:     input.Make,
		Model:    input.Model,
		Year:     input.Year,
		Color:    input.Color,
		PhotoURL: input.PhotoURL,
	}

	if err := s.db.Create(vehicle).Error; err != nil {
		return nil, err
	}

	return vehicle, nil
}

func (s *VehicleService) GetVehicles(ownerID uuid.UUID) ([]models.Vehicle, error) {
	var vehicles []models.Vehicle
	err := s.db.Where("owner_id = ?", ownerID).Find(&vehicles).Error
	return vehicles, err
}

func (s *VehicleService) GetVehicle(id, ownerID uuid.UUID) (*models.Vehicle, error) {
	var vehicle models.Vehicle
	err := s.db.Where("id = ? AND owner_id = ?", id, ownerID).First(&vehicle).Error
	if err != nil {
		return nil, errors.New("mashina topilmadi")
	}
	return &vehicle, nil
}

func (s *VehicleService) UpdateVehicle(id, ownerID uuid.UUID, input map[string]interface{}) (*models.Vehicle, error) {
	var vehicle models.Vehicle
	if err := s.db.Where("id = ? AND owner_id = ?", id, ownerID).First(&vehicle).Error; err != nil {
		return nil, errors.New("mashina topilmadi")
	}
	s.db.Model(&vehicle).Updates(input)
	return &vehicle, nil
}

func (s *VehicleService) DeleteVehicle(id, ownerID uuid.UUID) error {
	result := s.db.Where("id = ? AND owner_id = ?", id, ownerID).Delete(&models.Vehicle{})
	if result.RowsAffected == 0 {
		return errors.New("mashina topilmadi")
	}
	return result.Error
}

// LookupByPlate — plaka bo'yicha avtomobil va egasini topish (autosignal)
func (s *VehicleService) LookupByPlate(plate string) (*models.Vehicle, error) {
	var vehicle models.Vehicle
	if err := s.db.Where("plate = ?", plate).Preload("Owner").First(&vehicle).Error; err != nil {
		return nil, errors.New("bu plaka bilan mashina topilmadi")
	}
	return &vehicle, nil
}
