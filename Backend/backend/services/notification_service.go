package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"moshn/backend/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type NotificationService struct {
	db           *gorm.DB
	fcmServerKey string
}

func NewNotificationService(db *gorm.DB, fcmServerKey string) *NotificationService {
	return &NotificationService{db: db, fcmServerKey: fcmServerKey}
}

func (s *NotificationService) SendToUser(userID uuid.UUID, title, body, notifType, referenceID string) {
	notif := &models.Notification{
		UserID:      userID,
		Title:       title,
		Body:        body,
		Type:        notifType,
		ReferenceID: referenceID,
	}
	s.db.Create(notif)

	var tokens []models.FCMToken
	s.db.Where("user_id = ?", userID).Find(&tokens)

	for _, t := range tokens {
		s.sendFCM(t.Token, title, body)
	}
}

func (s *NotificationService) SendToMechanic(mechanicID uuid.UUID, title, body, notifType, referenceID string) {
	var mechanic models.Mechanic
	if err := s.db.First(&mechanic, "id = ?", mechanicID).Error; err != nil {
		return
	}
	s.SendToUser(mechanic.UserID, title, body, notifType, referenceID)
}

func (s *NotificationService) sendFCM(token, title, body string) {
	if s.fcmServerKey == "" {
		return
	}

	payload := map[string]interface{}{
		"to": token,
		"notification": map[string]string{
			"title": title,
			"body":  body,
		},
	}

	data, _ := json.Marshal(payload)
	req, _ := http.NewRequest("POST", "https://fcm.googleapis.com/fcm/send", bytes.NewBuffer(data))
	req.Header.Set("Authorization", fmt.Sprintf("key=%s", s.fcmServerKey))
	req.Header.Set("Content-Type", "application/json")

	http.DefaultClient.Do(req)
}

func (s *NotificationService) GetNotifications(userID uuid.UUID, page, limit, offset int) ([]models.Notification, int64, error) {
	var notifs []models.Notification
	var total int64

	s.db.Model(&models.Notification{}).Where("user_id = ?", userID).Count(&total)
	err := s.db.Where("user_id = ?", userID).
		Order("created_at DESC").
		Limit(limit).Offset(offset).
		Find(&notifs).Error

	return notifs, total, err
}

func (s *NotificationService) MarkAsRead(id, userID uuid.UUID) error {
	return s.db.Model(&models.Notification{}).
		Where("id = ? AND user_id = ?", id, userID).
		Update("is_read", true).Error
}

func (s *NotificationService) BroadcastToAll(title, body string) {
	var users []models.User
	s.db.Find(&users)
	for _, u := range users {
		s.SendToUser(u.ID, title, body, "broadcast", "")
	}
}

func (s *NotificationService) BroadcastToPhone(phone, title, body string) {
	var user models.User
	if err := s.db.Where("phone = ?", phone).First(&user).Error; err != nil {
		return
	}
	s.SendToUser(user.ID, title, body, "broadcast", "")
}

func (s *NotificationService) SaveFCMToken(userID uuid.UUID, token, platform string) {
	var existing models.FCMToken
	if s.db.Where("token = ?", token).First(&existing).Error == nil {
		s.db.Model(&existing).Updates(map[string]interface{}{"user_id": userID, "platform": platform})
		return
	}
	s.db.Create(&models.FCMToken{
		UserID:   userID,
		Token:    token,
		Platform: platform,
	})
}
