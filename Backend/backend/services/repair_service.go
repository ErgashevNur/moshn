package services

import (
	"errors"
	"moshn/backend/models"
	"strings"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type RepairService struct {
	db    *gorm.DB
	notif *NotificationService
}

func NewRepairService(db *gorm.DB, notif *NotificationService) *RepairService {
	return &RepairService{db: db, notif: notif}
}

type CreateRepairInput struct {
	PreferredMechanicID string `json:"preferred_mechanic_id"`
	Phone               string `json:"phone" binding:"required"`
	CarInfo             string `json:"car_info"`
	Description         string `json:"description" binding:"required"`
}

// Create — mijoz tamirlash so'rovini (ixtiyoriy tanlangan usta bilan) yuboradi.
func (s *RepairService) Create(userID uuid.UUID, in CreateRepairInput) (*models.RepairRequest, error) {
	phone := strings.TrimSpace(in.Phone)
	desc := strings.TrimSpace(in.Description)
	if phone == "" || desc == "" {
		return nil, errors.New("telefon va muammo tavsifi kiritilishi shart")
	}

	req := &models.RepairRequest{
		UserID:      userID,
		Phone:       phone,
		CarInfo:     strings.TrimSpace(in.CarInfo),
		Description: desc,
		Status:      "new",
	}
	if in.PreferredMechanicID != "" {
		if mid, err := uuid.Parse(in.PreferredMechanicID); err == nil {
			req.PreferredMechanicID = &mid
		}
	}

	if err := s.db.Create(req).Error; err != nil {
		return nil, err
	}
	s.db.Preload("PreferredMechanic.User").First(req, "id = ?", req.ID)
	return req, nil
}

// ListMine — mijozning o'z so'rovlari.
func (s *RepairService) ListMine(userID uuid.UUID) ([]models.RepairRequest, error) {
	var reqs []models.RepairRequest
	err := s.db.Where("user_id = ?", userID).
		Preload("PreferredMechanic.User").
		Preload("AssignedMechanic.User").
		Order("created_at DESC").Find(&reqs).Error
	return reqs, err
}

// AdminList — operator uchun statusga ko'ra ro'yxat (mijoz + ustalar bilan).
func (s *RepairService) AdminList(status string, limit, offset int) ([]models.RepairRequest, int64, error) {
	var reqs []models.RepairRequest
	var total int64

	q := s.db.Model(&models.RepairRequest{})
	if status != "" {
		q = q.Where("status = ?", status)
	}
	q.Count(&total)

	err := q.Preload("User").
		Preload("PreferredMechanic.User").
		Preload("AssignedMechanic.User").
		Order("created_at DESC").
		Limit(limit).Offset(offset).Find(&reqs).Error
	return reqs, total, err
}

// AssignMechanic — operator so'rovni ustaga yo'naltiradi (in_progress).
func (s *RepairService) AssignMechanic(id, mechanicID uuid.UUID, notes string) (*models.RepairRequest, error) {
	var req models.RepairRequest
	if err := s.db.First(&req, "id = ?", id).Error; err != nil {
		return nil, errors.New("so'rov topilmadi")
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
		s.notif.SendToMechanic(mechanicID, "Yangi tamirlash so'rovi",
			"Sizga tamirlash so'rovi yo'naltirildi. Mijoz ma'lumotlarini ko'ring.",
			"repair_assigned", req.ID.String())
		s.notif.SendToUser(req.UserID, "So'rovingiz yo'naltirildi",
			mech.User.FullName+" sizning tamirlash so'rovingizga biriktirildi.",
			"repair_assigned", req.ID.String())
	}

	s.db.Preload("User").Preload("PreferredMechanic.User").Preload("AssignedMechanic.User").First(&req, "id = ?", req.ID)
	return &req, nil
}

// UpdateStatus — operator so'rov holatini yangilaydi.
func (s *RepairService) UpdateStatus(id uuid.UUID, status, notes string) (*models.RepairRequest, error) {
	var req models.RepairRequest
	if err := s.db.First(&req, "id = ?", id).Error; err != nil {
		return nil, errors.New("so'rov topilmadi")
	}
	updates := map[string]interface{}{"status": status, "admin_notes": notes}
	if status == "resolved" || status == "cancelled" {
		now := time.Now()
		updates["resolved_at"] = now
	}
	if err := s.db.Model(&req).Updates(updates).Error; err != nil {
		return nil, err
	}
	s.db.Preload("User").Preload("AssignedMechanic.User").First(&req, "id = ?", req.ID)
	return &req, nil
}

// ListForMechanic — ustaga yo'naltirilgan tamirlash so'rovlari (mijoz ma'lumotlari bilan).
func (s *RepairService) ListForMechanic(mechanicID uuid.UUID) ([]models.RepairRequest, error) {
	var reqs []models.RepairRequest
	err := s.db.Where("assigned_mechanic_id = ?", mechanicID).
		Preload("User").
		Order("created_at DESC").Find(&reqs).Error
	return reqs, err
}
