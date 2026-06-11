package services

import (
	"errors"
	"fmt"
	"moshn/backend/models"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type PaymentService struct {
	db *gorm.DB
}

func NewPaymentService(db *gorm.DB) *PaymentService {
	return &PaymentService{db: db}
}

func (s *PaymentService) GetOrCreate(bookingID uuid.UUID, amount int, method string) (*models.Payment, error) {
	var payment models.Payment
	if err := s.db.Where("booking_id = ?", bookingID).First(&payment).Error; err == nil {
		return &payment, nil
	}

	payment = models.Payment{
		BookingID: bookingID,
		Amount:    amount,
		Method:    method,
		Status:    "pending",
	}

	if method == "card_qr" {
		payment.QRCode = fmt.Sprintf("shina24://pay/%s/%d", bookingID.String(), amount)
	}

	if err := s.db.Create(&payment).Error; err != nil {
		return nil, err
	}
	return &payment, nil
}

func (s *PaymentService) GenerateQR(bookingID uuid.UUID) (*models.Payment, error) {
	var booking models.Booking
	if err := s.db.First(&booking, "id = ?", bookingID).Error; err != nil {
		return nil, errors.New("bron topilmadi")
	}

	payment, err := s.GetOrCreate(bookingID, booking.TotalPrice, "card_qr")
	if err != nil {
		return nil, err
	}

	if payment.QRCode == "" {
		payment.QRCode = fmt.Sprintf("shina24://pay/%s/%d", bookingID.String(), payment.Amount)
		s.db.Save(payment)
	}

	return payment, nil
}

func (s *PaymentService) MarkPaid(bookingID uuid.UUID, method string) (*models.Payment, error) {
	var booking models.Booking
	if err := s.db.First(&booking, "id = ?", bookingID).Error; err != nil {
		return nil, errors.New("bron topilmadi")
	}

	payment, err := s.GetOrCreate(bookingID, booking.TotalPrice, method)
	if err != nil {
		return nil, err
	}
	if payment.Status == "paid" {
		return payment, nil
	}

	now := time.Now()
	s.db.Model(payment).Updates(map[string]interface{}{
		"status":  "paid",
		"paid_at": &now,
		"method":  method,
	})
	return payment, nil
}

func (s *PaymentService) GetByBooking(bookingID uuid.UUID) (*models.Payment, error) {
	var payment models.Payment
	err := s.db.Where("booking_id = ?", bookingID).First(&payment).Error
	return &payment, err
}

func (s *PaymentService) AddTip(bookingID uuid.UUID, amount int) (*models.Tip, error) {
	if amount <= 0 {
		return nil, errors.New("tip miqdori noto'g'ri")
	}
	var booking models.Booking
	if err := s.db.Where("id = ?", bookingID).First(&booking).Error; err != nil {
		return nil, errors.New("bron topilmadi")
	}

	tip := &models.Tip{
		BookingID: bookingID,
		Amount:    amount,
	}
	if err := s.db.Create(tip).Error; err != nil {
		return nil, err
	}
	return tip, nil
}
