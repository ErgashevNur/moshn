package services

import (
	"errors"
	"moshn/backend/models"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SosService struct {
	db    *gorm.DB
	notif *NotificationService
	hub   *WSHub
}

func NewSosService(db *gorm.DB, notif *NotificationService, hub *WSHub) *SosService {
	return &SosService{db: db, notif: notif, hub: hub}
}

type CreateSosInput struct {
	Phone     string  `json:"phone" binding:"required"`
	Latitude  float64 `json:"latitude" binding:"required"`
	Longitude float64 `json:"longitude" binding:"required"`
	Address   string  `json:"address"`
}

func (s *SosService) CreateRequest(userID uuid.UUID, input CreateSosInput) (*models.SosRequest, error) {
	phone := strings.TrimSpace(input.Phone)
	if phone == "" {
		return nil, errors.New("telefon raqami kiritilishi shart")
	}

	req := &models.SosRequest{
		UserID:    userID,
		Phone:     phone,
		Latitude:  input.Latitude,
		Longitude: input.Longitude,
		Address:   strings.TrimSpace(input.Address),
		Status:    "new",
	}

	if err := s.db.Create(req).Error; err != nil {
		return nil, err
	}

	// Real-time: admin panelga refreshsiz yetkazamiz.
	if s.hub != nil {
		var full models.SosRequest
		s.db.Preload("User").First(&full, "id = ?", req.ID)
		s.hub.BroadcastToAdmins("sos.created", full)
	}
	return req, nil
}

// ListMine — mijozning o'z SOS so'rovlari (yo'naltirilgan usta bilan).
func (s *SosService) ListMine(userID uuid.UUID) ([]models.SosRequest, error) {
	var requests []models.SosRequest
	err := s.db.Where("user_id = ?", userID).
		Preload("AssignedMechanic").
		Preload("AssignedMechanic.User").
		Order("created_at DESC").
		Find(&requests).Error
	return requests, err
}

// ListRequests — admin uchun statusga ko'ra ro'yxat.
func (s *SosService) ListRequests(status string, limit, offset int) ([]models.SosRequest, int64, error) {
	var requests []models.SosRequest
	var total int64

	q := s.db.Model(&models.SosRequest{})
	if status != "" {
		q = q.Where("status = ?", status)
	}
	q.Count(&total)

	err := q.Preload("User").
		Preload("AssignedMechanic").
		Preload("AssignedMechanic.User").
		Order("created_at DESC").
		Limit(limit).Offset(offset).
		Find(&requests).Error
	return requests, total, err
}

// UpdateStatus — admin so'rov holatini yangilaydi.
func (s *SosService) UpdateStatus(id uuid.UUID, status, adminNotes string) (*models.SosRequest, error) {
	var req models.SosRequest
	if err := s.db.First(&req, "id = ?", id).Error; err != nil {
		return nil, errors.New("SOS so'rovi topilmadi")
	}

	updates := map[string]interface{}{
		"status":      status,
		"admin_notes": adminNotes,
	}
	if status == "resolved" || status == "cancelled" {
		now := time.Now()
		updates["resolved_at"] = now
	}
	if err := s.db.Model(&req).Updates(updates).Error; err != nil {
		return nil, err
	}
	s.db.Preload("User").Preload("AssignedMechanic.User").First(&req, "id = ?", req.ID)
	if s.hub != nil {
		s.hub.BroadcastToAdmins("sos.updated", req)
	}
	return &req, nil
}

// AssignMechanic — operator SOS so'rovini ustaga yo'naltiradi va statusni
// in_progress qiladi. Usta va mijozga bildirishnoma yuboriladi.
func (s *SosService) AssignMechanic(id, mechanicID uuid.UUID, notes string) (*models.SosRequest, error) {
	var req models.SosRequest
	if err := s.db.First(&req, "id = ?", id).Error; err != nil {
		return nil, errors.New("SOS so'rovi topilmadi")
	}

	var mech models.Mechanic
	if err := s.db.Preload("User").First(&mech, "id = ?", mechanicID).Error; err != nil {
		return nil, errors.New("usta topilmadi")
	}

	updates := map[string]interface{}{
		"assigned_mechanic_id": mechanicID,
		"status":               "in_progress",
	}
	if strings.TrimSpace(notes) != "" {
		updates["admin_notes"] = notes
	}
	if err := s.db.Model(&req).Updates(updates).Error; err != nil {
		return nil, err
	}

	if s.notif != nil {
		s.notif.SendToMechanic(mechanicID, "Yangi SOS yo'naltirildi",
			"Sizga favqulodda yordam so'rovi biriktirildi. Mijoz ma'lumotlarini ko'ring.",
			"sos_assigned", req.ID.String())
		s.notif.SendToUser(req.UserID, "Usta yo'lda",
			mech.User.FullName+" sizning SOS so'rovingizga biriktirildi.",
			"sos_assigned", req.ID.String())
	}

	s.db.Preload("User").Preload("AssignedMechanic.User").First(&req, "id = ?", req.ID)
	if s.hub != nil {
		s.hub.BroadcastToAdmins("sos.updated", req)
	}
	return &req, nil
}

// ListForMechanic — ustaga yo'naltirilgan SOS so'rovlari (mijoz ma'lumotlari bilan).
func (s *SosService) ListForMechanic(mechanicID uuid.UUID) ([]models.SosRequest, error) {
	var requests []models.SosRequest
	err := s.db.Where("assigned_mechanic_id = ?", mechanicID).
		Preload("User").
		Order("created_at DESC").
		Find(&requests).Error
	return requests, err
}
