package services

import (
	"errors"
	"moshn/backend/models"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type BookingService struct {
	db       *gorm.DB
	notifSvc *NotificationService
	wsHub    *WSHub
	shopSvc  *ShopService
}

func NewBookingService(db *gorm.DB, notifSvc *NotificationService, wsHub *WSHub, shopSvc *ShopService) *BookingService {
	return &BookingService{db: db, notifSvc: notifSvc, wsHub: wsHub, shopSvc: shopSvc}
}

type CreateBookingInput struct {
	ShopID        string `json:"shop_id" binding:"required"`
	VehicleID     string `json:"vehicle_id" binding:"required"`
	ServiceTypeID string `json:"service_type_id" binding:"required"`
	ScheduledAt   string `json:"scheduled_at" binding:"required"` // RFC3339
	Notes         string `json:"notes"`
	TotalPrice    int    `json:"total_price"`
}

func (s *BookingService) CreateBooking(customerID uuid.UUID, input CreateBookingInput) (*models.Booking, error) {
	shopID, err := uuid.Parse(input.ShopID)
	if err != nil {
		return nil, errors.New("noto'g'ri shop_id")
	}
	vehicleID, err := uuid.Parse(input.VehicleID)
	if err != nil {
		return nil, errors.New("noto'g'ri vehicle_id")
	}
	serviceTypeID, err := uuid.Parse(input.ServiceTypeID)
	if err != nil {
		return nil, errors.New("noto'g'ri service_type_id")
	}
	scheduledAt, err := time.Parse(time.RFC3339, input.ScheduledAt)
	if err != nil {
		return nil, errors.New("noto'g'ri sana formati (RFC3339 kerak)")
	}

	// Mashina egaga tegishli ekanligini tekshirish
	var vehicle models.Vehicle
	if err := s.db.Where("id = ? AND owner_id = ?", vehicleID, customerID).First(&vehicle).Error; err != nil {
		return nil, errors.New("mashina topilmadi")
	}

	var shop models.ShopProfile
	if err := s.db.Where("id = ? AND verification_status = 'verified'", shopID).First(&shop).Error; err != nil {
		return nil, errors.New("servis topilmadi")
	}

	booking := &models.Booking{
		CustomerID:    customerID,
		ShopID:        shopID,
		VehicleID:     vehicleID,
		ServiceTypeID: serviceTypeID,
		ScheduledAt:   scheduledAt,
		Notes:         input.Notes,
		TotalPrice:    input.TotalPrice,
		Status:        "pending",
	}

	if err := s.db.Create(booking).Error; err != nil {
		return nil, err
	}

	s.db.Preload("Customer").Preload("Shop.User").
		Preload("Vehicle").Preload("ServiceType").
		First(booking, "id = ?", booking.ID)

	// Servisga WebSocket orqali real-vaqt bildirishnoma
	s.wsHub.BroadcastToUser(shop.UserID.String(), "new_booking", booking)

	// Servis foydalanuvchisiga push
	s.notifSvc.SendToUser(shop.UserID,
		"Yangi bron!", "Yangi mijoz bron qildi", "new_booking", booking.ID.String())

	// CRM yangilash
	go s.shopSvc.UpsertCustomerCard(shopID, customerID)

	return booking, nil
}

func (s *BookingService) GetCustomerBookings(customerID uuid.UUID, status string, limit, offset int) ([]models.Booking, int64, error) {
	query := s.db.Model(&models.Booking{}).Where("customer_id = ?", customerID)
	if status != "" {
		query = query.Where("status = ?", status)
	}

	var total int64
	query.Count(&total)

	var bookings []models.Booking
	err := query.Preload("Shop.User").Preload("Vehicle").Preload("ServiceType").
		Order("created_at DESC").Limit(limit).Offset(offset).Find(&bookings).Error

	return bookings, total, err
}

func (s *BookingService) GetShopBookings(shopID uuid.UUID, status string, limit, offset int) ([]models.Booking, int64, error) {
	query := s.db.Model(&models.Booking{}).Where("shop_id = ?", shopID)
	if status != "" {
		query = query.Where("status = ?", status)
	}

	var total int64
	query.Count(&total)

	var bookings []models.Booking
	err := query.Preload("Customer").Preload("Vehicle").Preload("ServiceType").
		Order("scheduled_at ASC").Limit(limit).Offset(offset).Find(&bookings).Error

	return bookings, total, err
}

func (s *BookingService) GetBooking(id uuid.UUID) (*models.Booking, error) {
	var booking models.Booking
	err := s.db.Preload("Customer").Preload("Shop.User").
		Preload("Vehicle").Preload("ServiceType").
		First(&booking, "id = ?", id).Error
	return &booking, err
}

func (s *BookingService) CancelByCustomer(bookingID, customerID uuid.UUID, reason string) error {
	var booking models.Booking
	if err := s.db.Where("id = ? AND customer_id = ? AND status IN ('pending','confirmed')", bookingID, customerID).
		First(&booking).Error; err != nil {
		return errors.New("bron topilmadi yoki bekor qilib bo'lmaydi")
	}
	now := time.Now()
	_ = now
	return s.db.Model(&booking).Updates(map[string]interface{}{
		"status":        "cancelled",
		"cancel_reason": reason,
	}).Error
}

func (s *BookingService) ConfirmByShop(bookingID, shopID uuid.UUID) (*models.Booking, error) {
	var booking models.Booking
	if err := s.db.Where("id = ? AND shop_id = ? AND status = 'pending'", bookingID, shopID).
		First(&booking).Error; err != nil {
		return nil, errors.New("bron topilmadi")
	}
	s.db.Model(&booking).Update("status", "confirmed")
	s.notifSvc.SendToUser(booking.CustomerID,
		"Bron tasdiqlandi", "Servis broningizni tasdiqladi", "booking_confirmed", booking.ID.String())
	s.db.Preload("Customer").Preload("Shop.User").Preload("Vehicle").Preload("ServiceType").
		First(&booking, "id = ?", booking.ID)
	return &booking, nil
}

func (s *BookingService) StartByShop(bookingID, shopID uuid.UUID) (*models.Booking, error) {
	var booking models.Booking
	if err := s.db.Where("id = ? AND shop_id = ? AND status = 'confirmed'", bookingID, shopID).
		First(&booking).Error; err != nil {
		return nil, errors.New("bron topilmadi")
	}
	s.db.Model(&booking).Update("status", "in_progress")
	s.notifSvc.SendToUser(booking.CustomerID,
		"Xizmat boshlandi", "Mashinangizga xizmat ko'rsatilmoqda", "booking_started", booking.ID.String())
	s.db.Preload("Customer").Preload("Shop.User").Preload("Vehicle").Preload("ServiceType").
		First(&booking, "id = ?", booking.ID)
	return &booking, nil
}

func (s *BookingService) CompleteByShop(bookingID, shopID uuid.UUID) (*models.Booking, error) {
	var booking models.Booking
	if err := s.db.Where("id = ? AND shop_id = ? AND status = 'in_progress'", bookingID, shopID).
		First(&booking).Error; err != nil {
		return nil, errors.New("bron topilmadi")
	}
	now := time.Now()
	s.db.Model(&booking).Updates(map[string]interface{}{
		"status":       "completed",
		"completed_at": &now,
	})

	// TotalBookings hisoblagichini yangilash
	s.db.Model(&models.ShopProfile{}).Where("id = ?", shopID).
		UpdateColumn("total_bookings", gorm.Expr("total_bookings + 1"))

	// CRM: tashrif sonini yangilash
	s.db.Model(&models.CustomerCard{}).
		Where("shop_id = ? AND customer_id = ?", shopID, booking.CustomerID).
		Updates(map[string]interface{}{
			"visit_count":   gorm.Expr("visit_count + 1"),
			"last_visit_at": &now,
		})

	s.notifSvc.SendToUser(booking.CustomerID,
		"Xizmat tugadi", "Mashinangizga xizmat ko'rsatildi. Baholang!", "booking_completed", booking.ID.String())

	s.db.Preload("Customer").Preload("Shop.User").Preload("Vehicle").Preload("ServiceType").
		First(&booking, "id = ?", booking.ID)
	return &booking, nil
}

func (s *BookingService) CancelByShop(bookingID, shopID uuid.UUID, reason string) error {
	var booking models.Booking
	if err := s.db.Where("id = ? AND shop_id = ? AND status IN ('pending','confirmed')", bookingID, shopID).
		First(&booking).Error; err != nil {
		return errors.New("bron topilmadi")
	}
	s.db.Model(&booking).Updates(map[string]interface{}{
		"status":        "cancelled",
		"cancel_reason": reason,
	})
	s.notifSvc.SendToUser(booking.CustomerID,
		"Bron bekor qilindi", "Servis broningizni bekor qildi", "booking_cancelled", booking.ID.String())
	return nil
}
