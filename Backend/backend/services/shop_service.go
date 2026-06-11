package services

import (
	"math"
	"moshn/backend/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ShopService struct {
	db *gorm.DB
}

func NewShopService(db *gorm.DB) *ShopService {
	return &ShopService{db: db}
}

type ShopFilter struct {
	ServiceType string
	Lat         float64
	Lng         float64
	Limit       int
	Offset      int
}

type ShopWithDistance struct {
	models.ShopProfile
	DistanceKm float64 `json:"distance_km"`
}

func haversine(lat1, lng1, lat2, lng2 float64) float64 {
	const R = 6371.0
	dLat := (lat2 - lat1) * math.Pi / 180
	dLng := (lng2 - lng1) * math.Pi / 180
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180)*math.Cos(lat2*math.Pi/180)*
			math.Sin(dLng/2)*math.Sin(dLng/2)
	return R * 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
}

func (s *ShopService) GetShops(f ShopFilter) ([]ShopWithDistance, int64, error) {
	query := s.db.Model(&models.ShopProfile{}).
		Preload("User").
		Where("verification_status = 'verified'")

	if f.ServiceType != "" {
		query = query.Where("? = ANY(service_types)", f.ServiceType)
	}

	var total int64
	query.Count(&total)

	var shops []models.ShopProfile
	if err := query.Limit(f.Limit).Offset(f.Offset).Find(&shops).Error; err != nil {
		return nil, 0, err
	}

	result := make([]ShopWithDistance, 0, len(shops))
	for _, sh := range shops {
		dist := 0.0
		if f.Lat != 0 && f.Lng != 0 {
			dist = haversine(f.Lat, f.Lng, sh.Latitude, sh.Longitude)
		}
		result = append(result, ShopWithDistance{
			ShopProfile: sh,
			DistanceKm:  math.Round(dist*10) / 10,
		})
	}

	return result, total, nil
}

func (s *ShopService) GetShop(id uuid.UUID) (*models.ShopProfile, error) {
	var shop models.ShopProfile
	err := s.db.Preload("User").First(&shop, "id = ?", id).Error
	return &shop, err
}

func (s *ShopService) GetByUserID(userID uuid.UUID) (*models.ShopProfile, error) {
	var shop models.ShopProfile
	err := s.db.Preload("User").First(&shop, "user_id = ?", userID).Error
	return &shop, err
}

func (s *ShopService) UpdateProfile(userID uuid.UUID, input map[string]interface{}) (*models.ShopProfile, error) {
	var shop models.ShopProfile
	if err := s.db.Where("user_id = ?", userID).First(&shop).Error; err != nil {
		return nil, err
	}
	s.db.Model(&shop).Updates(input)
	return &shop, nil
}

// GetCustomers — servisga tashrif buyurgan mijozlar CRM ro'yxati
func (s *ShopService) GetCustomers(shopID uuid.UUID, page, limit, offset int) ([]models.CustomerCard, int64, error) {
	var cards []models.CustomerCard
	var total int64

	s.db.Model(&models.CustomerCard{}).Where("shop_id = ?", shopID).Count(&total)
	err := s.db.Where("shop_id = ?", shopID).
		Preload("Customer").
		Order("is_vip DESC, last_visit_at DESC").
		Limit(limit).Offset(offset).
		Find(&cards).Error

	return cards, total, err
}

func (s *ShopService) GetCustomerCard(shopID, customerID uuid.UUID) (*models.CustomerCard, error) {
	var card models.CustomerCard
	err := s.db.Where("shop_id = ? AND customer_id = ?", shopID, customerID).
		Preload("Customer").First(&card).Error
	return &card, err
}

func (s *ShopService) UpsertCustomerCard(shopID, customerID uuid.UUID) (*models.CustomerCard, error) {
	var card models.CustomerCard
	err := s.db.Where("shop_id = ? AND customer_id = ?", shopID, customerID).First(&card).Error
	if err != nil {
		card = models.CustomerCard{
			ShopID:     shopID,
			CustomerID: customerID,
			VisitCount: 1,
		}
		if createErr := s.db.Create(&card).Error; createErr != nil {
			return nil, createErr
		}
	}
	s.db.Preload("Customer").First(&card, "id = ?", card.ID)
	return &card, nil
}

func (s *ShopService) UpdateCustomerCard(shopID, customerID uuid.UUID, input map[string]interface{}) (*models.CustomerCard, error) {
	var card models.CustomerCard
	if err := s.db.Where("shop_id = ? AND customer_id = ?", shopID, customerID).First(&card).Error; err != nil {
		return nil, err
	}
	s.db.Model(&card).Updates(input)
	s.db.Preload("Customer").First(&card, "id = ?", card.ID)
	return &card, nil
}

func (s *ShopService) SetVIP(shopID, customerID uuid.UUID, isVip bool) (*models.CustomerCard, error) {
	return s.UpdateCustomerCard(shopID, customerID, map[string]interface{}{"is_vip": isVip})
}
