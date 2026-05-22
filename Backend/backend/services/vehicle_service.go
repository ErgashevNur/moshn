package services

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"moshn/backend/models"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type VehicleService struct {
	db           *gorm.DB
	claudeAPIKey string
}

func NewVehicleService(db *gorm.DB, claudeAPIKey string) *VehicleService {
	return &VehicleService{db: db, claudeAPIKey: claudeAPIKey}
}

type CreateVehicleInput struct {
	VIN             string `json:"vin" binding:"required"`
	CurrentPlate    string `json:"current_plate" binding:"required"`
	Make            string `json:"make" binding:"required"`
	Model           string `json:"model" binding:"required"`
	Year            int    `json:"year" binding:"required"`
	Color           string `json:"color"`
	PhotoURL        string `json:"photo_url"`
	TechpassportURL string `json:"techpassport_url"`
}

func (s *VehicleService) CreateVehicle(ownerID uuid.UUID, input CreateVehicleInput) (*models.Vehicle, error) {
	var count int64
	s.db.Model(&models.Vehicle{}).Where("owner_id = ?", ownerID).Count(&count)
	if count >= 3 {
		return nil, errors.New("maksimal 3 ta mashina ro'yxatga olish mumkin")
	}

	vehicle := &models.Vehicle{
		VIN:             input.VIN,
		CurrentPlate:    input.CurrentPlate,
		OwnerID:         ownerID,
		Make:            input.Make,
		Model:           input.Model,
		Year:            input.Year,
		Color:           input.Color,
		PhotoURL:        input.PhotoURL,
		TechpassportURL: input.TechpassportURL,
	}

	if err := s.db.Create(vehicle).Error; err != nil {
		return nil, err
	}

	s.db.Create(&models.PlateHistory{
		VehicleID:   vehicle.ID,
		PlateNumber: vehicle.CurrentPlate,
		StartedAt:   time.Now(),
	})

	s.db.Create(&models.OwnershipHistory{
		VehicleID: vehicle.ID,
		OwnerID:   ownerID,
		StartedAt: time.Now(),
	})

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

	if newPlate, ok := input["current_plate"].(string); ok && newPlate != vehicle.CurrentPlate {
		now := time.Now()
		s.db.Model(&models.PlateHistory{}).Where("vehicle_id = ? AND ended_at IS NULL", vehicle.ID).
			Update("ended_at", now)
		s.db.Create(&models.PlateHistory{
			VehicleID:   vehicle.ID,
			PlateNumber: newPlate,
			StartedAt:   now,
		})
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

func (s *VehicleService) GetServiceHistory(vehicleID uuid.UUID, ownerID uuid.UUID, page, limit, offset int) ([]models.ServiceRecord, int64, error) {
	var vehicle models.Vehicle
	if err := s.db.Where("id = ? AND owner_id = ?", vehicleID, ownerID).First(&vehicle).Error; err != nil {
		return nil, 0, errors.New("mashina topilmadi")
	}

	var records []models.ServiceRecord
	var total int64

	s.db.Model(&models.ServiceRecord{}).Where("vehicle_id = ?", vehicleID).Count(&total)
	err := s.db.Where("vehicle_id = ?", vehicleID).
		Preload("Mechanic.User").
		Order("service_date DESC").
		Limit(limit).Offset(offset).
		Find(&records).Error

	return records, total, err
}

func (s *VehicleService) TransferOwnership(vehicleID, currentOwnerID uuid.UUID, newOwnerPhone string) error {
	var vehicle models.Vehicle
	if err := s.db.Where("id = ? AND owner_id = ?", vehicleID, currentOwnerID).First(&vehicle).Error; err != nil {
		return errors.New("mashina topilmadi")
	}

	var newOwner models.User
	if err := s.db.Where("phone = ?", newOwnerPhone).First(&newOwner).Error; err != nil {
		return errors.New("yangi egasi topilmadi. Avval ro'yxatdan o'tishi kerak")
	}

	now := time.Now()
	s.db.Model(&models.OwnershipHistory{}).
		Where("vehicle_id = ? AND ended_at IS NULL", vehicleID).
		Update("ended_at", now)

	s.db.Create(&models.OwnershipHistory{
		VehicleID: vehicleID,
		OwnerID:   newOwner.ID,
		StartedAt: now,
	})

	s.db.Model(&vehicle).Update("owner_id", newOwner.ID)
	return nil
}

type OCRResult struct {
	VIN          string `json:"vin"`
	CurrentPlate string `json:"current_plate"`
	Make         string `json:"make"`
	Model        string `json:"model"`
	Year         int    `json:"year"`
}

func (s *VehicleService) OCRTechpassport(imagePath string) (*OCRResult, error) {
	if s.claudeAPIKey == "" {
		return nil, errors.New("Claude API key sozlanmagan")
	}

	imageData, err := os.ReadFile(imagePath)
	if err != nil {
		return nil, fmt.Errorf("rasm o'qib bo'lmadi: %w", err)
	}

	base64Image := base64.StdEncoding.EncodeToString(imageData)

	payload := map[string]interface{}{
		"model": "claude-opus-4-5",
		"max_tokens": 1024,
		"messages": []map[string]interface{}{
			{
				"role": "user",
				"content": []map[string]interface{}{
					{
						"type": "image",
						"source": map[string]interface{}{
							"type":       "base64",
							"media_type": "image/jpeg",
							"data":       base64Image,
						},
					},
					{
						"type": "text",
						"text": `Bu O'zbekiston texnik pasport rasmi. Quyidagi ma'lumotlarni JSON formatda ajrat:
{"vin": "...", "current_plate": "...", "make": "...", "model": "...", "year": 0}
Faqat JSON qaytар, boshqa hech narsa yo'q.`,
					},
				},
			},
		},
	}

	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "https://api.anthropic.com/v1/messages", bytes.NewBuffer(body))
	req.Header.Set("x-api-key", s.claudeAPIKey)
	req.Header.Set("anthropic-version", "2023-06-01")
	req.Header.Set("content-type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("Claude API xatosi: %w", err)
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)

	var claudeResp struct {
		Content []struct {
			Text string `json:"text"`
		} `json:"content"`
	}
	if err := json.Unmarshal(respBody, &claudeResp); err != nil || len(claudeResp.Content) == 0 {
		return nil, errors.New("Claude API javobini o'qib bo'lmadi")
	}

	var result OCRResult
	if err := json.Unmarshal([]byte(claudeResp.Content[0].Text), &result); err != nil {
		return nil, fmt.Errorf("JSON parse xatosi: %w", err)
	}

	return &result, nil
}
