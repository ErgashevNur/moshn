package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"moshn/backend/models"
	"net/http"

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

func (s *NotificationService) SendToShop(shopID uuid.UUID, title, body, notifType, referenceID string) {
	var shop models.ShopProfile
	if err := s.db.First(&shop, "id = ?", shopID).Error; err != nil {
		return
	}
	s.SendToUser(shop.UserID, title, body, notifType, referenceID)
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

func (s *NotificationService) BroadcastSeasonal(rule *models.SeasonalRule) {
	var users []models.User
	s.db.Where("role = 'owner'").Find(&users)
	for _, u := range users {
		msg := rule.MessageUz
		if u.Language == "ru" {
			msg = rule.MessageRu
		}
		s.SendToUser(u.ID, rule.Name, msg, "seasonal", rule.ID.String())
	}
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
