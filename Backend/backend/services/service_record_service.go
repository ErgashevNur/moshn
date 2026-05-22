package services

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"moshn/backend/models"
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

type ServiceRecordService struct {
	db               *gorm.DB
	claudeAPIKey     string
	uzbekVoiceAPIKey string
	notifService     *NotificationService
}

func NewServiceRecordService(db *gorm.DB, claudeAPIKey, uzbekVoiceAPIKey string, notifService *NotificationService) *ServiceRecordService {
	return &ServiceRecordService{
		db:               db,
		claudeAPIKey:     claudeAPIKey,
		uzbekVoiceAPIKey: uzbekVoiceAPIKey,
		notifService:     notifService,
	}
}

type CreateServiceInput struct {
	VehicleID   string         `json:"vehicle_id" binding:"required"`
	ServiceDate string         `json:"service_date" binding:"required"`
	MileageKm   *int           `json:"mileage_km"`
	ServiceType string         `json:"service_type" binding:"required"`
	Description string         `json:"description" binding:"required"`
	PartsUsed   datatypes.JSON `json:"parts_used"`
	PriceUZS    *int64         `json:"price_uzs"`
	Notes       string         `json:"notes"`
}

func (s *ServiceRecordService) CreateServiceRecord(mechanicUserID uuid.UUID, input CreateServiceInput) (*models.ServiceRecord, error) {
	var mechanic models.Mechanic
	if err := s.db.Where("user_id = ?", mechanicUserID).First(&mechanic).Error; err != nil {
		return nil, errors.New("usta profili topilmadi")
	}

	vehicleID, err := uuid.Parse(input.VehicleID)
	if err != nil {
		return nil, errors.New("noto'g'ri mashina ID")
	}

	var vehicle models.Vehicle
	if err := s.db.First(&vehicle, "id = ?", vehicleID).Error; err != nil {
		return nil, errors.New("mashina topilmadi")
	}

	serviceDate, err := time.Parse("2006-01-02", input.ServiceDate)
	if err != nil {
		serviceDate = time.Now()
	}

	record := &models.ServiceRecord{
		VehicleID:   vehicleID,
		MechanicID:  mechanic.ID,
		OwnerID:     vehicle.OwnerID,
		ServiceDate: serviceDate,
		MileageKm:   input.MileageKm,
		ServiceType: input.ServiceType,
		Description: input.Description,
		PartsUsed:   input.PartsUsed,
		PriceUZS:    input.PriceUZS,
		Notes:       input.Notes,
		Status:      "created",
	}

	if err := s.db.Create(record).Error; err != nil {
		return nil, err
	}

	s.db.Model(&mechanic).Update("total_services", gorm.Expr("total_services + 1"))

	go s.notifService.SendToUser(vehicle.OwnerID,
		"Yangi servis yozuvi",
		fmt.Sprintf("%s sizning mashinangizga xizmat ko'rsatdi. Tasdiqlang.", mechanic.WorkshopName),
		"service_created",
		record.ID.String(),
	)

	return record, nil
}

func (s *ServiceRecordService) GetServiceRecord(id uuid.UUID) (*models.ServiceRecord, error) {
	var record models.ServiceRecord
	err := s.db.Preload("Mechanic.User").Preload("Vehicle").Preload("Owner").
		First(&record, "id = ?", id).Error
	if err != nil {
		return nil, errors.New("yozuv topilmadi")
	}
	return &record, nil
}

func (s *ServiceRecordService) ConfirmRecord(id, ownerID uuid.UUID) (*models.ServiceRecord, error) {
	var record models.ServiceRecord
	if err := s.db.Where("id = ? AND owner_id = ? AND status = 'created'", id, ownerID).First(&record).Error; err != nil {
		return nil, errors.New("yozuv topilmadi yoki allaqachon tasdiqlangan")
	}

	now := time.Now()
	s.db.Model(&record).Updates(map[string]interface{}{
		"status":       "confirmed",
		"confirmed_at": now,
	})

	go s.notifService.SendToMechanic(record.MechanicID,
		"Servis tasdiqlandi",
		"Mijoz servis yozuvini tasdiqladi.",
		"service_confirmed",
		record.ID.String(),
	)

	return &record, nil
}

func (s *ServiceRecordService) RejectRecord(id, ownerID uuid.UUID, reason string) (*models.ServiceRecord, error) {
	var record models.ServiceRecord
	if err := s.db.Where("id = ? AND owner_id = ? AND status = 'created'", id, ownerID).First(&record).Error; err != nil {
		return nil, errors.New("yozuv topilmadi yoki allaqachon tasdiqlangan")
	}

	s.db.Model(&record).Updates(map[string]interface{}{
		"status": "rejected",
		"notes":  reason,
	})

	go s.notifService.SendToMechanic(record.MechanicID,
		"Servis rad etildi",
		fmt.Sprintf("Mijoz servis yozuvini rad etdi. Sabab: %s", reason),
		"service_rejected",
		record.ID.String(),
	)

	return &record, nil
}

func (s *ServiceRecordService) GetPendingRecords(ownerID uuid.UUID) ([]models.ServiceRecord, error) {
	var records []models.ServiceRecord
	err := s.db.Where("owner_id = ? AND status = 'created'", ownerID).
		Preload("Mechanic.User").Preload("Vehicle").
		Order("created_at DESC").
		Find(&records).Error
	return records, err
}

type ParsedServiceData struct {
	ServiceDate string        `json:"service_date"`
	MileageKm   *int          `json:"mileage_km"`
	ServiceType string        `json:"service_type"`
	Description string        `json:"description"`
	PartsUsed   []interface{} `json:"parts_used"`
	PriceUZS    *int64        `json:"price_uzs"`
	Notes       string        `json:"notes"`
}

func (s *ServiceRecordService) ProcessVoice(audioData []byte) (*ParsedServiceData, error) {
	voiceText, err := s.sttUzbekVoice(audioData)
	if err != nil {
		return nil, fmt.Errorf("STT xatosi: %w", err)
	}

	return s.parseWithClaude(voiceText)
}

func (s *ServiceRecordService) sttUzbekVoice(audioData []byte) (string, error) {
	if s.uzbekVoiceAPIKey == "" {
		return "ovoz matni (UzbekVoice API kalit yo'q)", nil
	}

	req, _ := http.NewRequest("POST", "https://back.aisha.group/api/v1/stt/", bytes.NewReader(audioData))
	req.Header.Set("key", s.uzbekVoiceAPIKey)
	req.Header.Set("Content-Type", "audio/wav")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	var result struct {
		Result string `json:"result"`
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return "", errors.New("STT javobini o'qib bo'lmadi")
	}
	return result.Result, nil
}

func (s *ServiceRecordService) parseWithClaude(voiceText string) (*ParsedServiceData, error) {
	if s.claudeAPIKey == "" {
		return &ParsedServiceData{
			ServiceDate: time.Now().Format("2006-01-02"),
			ServiceType: "Belgilanmagan",
			Description: voiceText,
			Notes:       "",
		}, nil
	}

	prompt := fmt.Sprintf(`O'zbek tilida yozilgan servis yozuvini tahlil qil va quyidagi JSON formatda qaytар:
{
  "service_date": "YYYY-MM-DD",
  "mileage_km": null,
  "service_type": "...",
  "description": "...",
  "parts_used": [{"name": "...", "brand": "...", "quantity": "..."}],
  "price_uzs": null,
  "notes": ""
}

Matn: %s

Faqat JSON qaytар.`, voiceText)

	payload := map[string]interface{}{
		"model":      "claude-sonnet-4-6",
		"max_tokens": 1024,
		"messages": []map[string]interface{}{
			{"role": "user", "content": prompt},
		},
	}

	body, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "https://api.anthropic.com/v1/messages", bytes.NewBuffer(body))
	req.Header.Set("x-api-key", s.claudeAPIKey)
	req.Header.Set("anthropic-version", "2023-06-01")
	req.Header.Set("content-type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)
	var claudeResp struct {
		Content []struct {
			Text string `json:"text"`
		} `json:"content"`
	}
	if err := json.Unmarshal(respBody, &claudeResp); err != nil || len(claudeResp.Content) == 0 {
		return nil, errors.New("Claude javobini o'qib bo'lmadi")
	}

	var parsed ParsedServiceData
	if err := json.Unmarshal([]byte(claudeResp.Content[0].Text), &parsed); err != nil {
		return nil, fmt.Errorf("JSON parse xatosi: %w", err)
	}
	return &parsed, nil
}

func (s *ServiceRecordService) AutoConfirmExpired() {
	cutoff := time.Now().Add(-48 * time.Hour)
	s.db.Model(&models.ServiceRecord{}).
		Where("status = 'created' AND created_at < ?", cutoff).
		Updates(map[string]interface{}{
			"status":        "auto_confirmed",
			"auto_confirmed": true,
			"confirmed_at":  time.Now(),
		})
}
