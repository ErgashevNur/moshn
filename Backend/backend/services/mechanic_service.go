package services

import (
	"math"
	"moshn/backend/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type MechanicService struct {
	db *gorm.DB
}

func NewMechanicService(db *gorm.DB) *MechanicService {
	return &MechanicService{db: db}
}

type MechanicFilter struct {
	Category string
	Lat      float64
	Lng      float64
	MinStars int
	Page     int
	Limit    int
	Offset   int
}

type MechanicWithDistance struct {
	models.Mechanic
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

func (s *MechanicService) GetMechanics(f MechanicFilter) ([]MechanicWithDistance, int64, error) {
	query := s.db.Model(&models.Mechanic{}).
		Preload("User").
		Where("verification_status = 'verified'")

	if f.MinStars > 0 {
		query = query.Where("star_level >= ?", f.MinStars)
	}

	if f.Category != "" {
		query = query.Where("? = ANY(specialization)", f.Category)
	}

	var total int64
	query.Count(&total)

	var mechanics []models.Mechanic
	if err := query.Limit(f.Limit).Offset(f.Offset).Find(&mechanics).Error; err != nil {
		return nil, 0, err
	}

	result := make([]MechanicWithDistance, 0, len(mechanics))
	for _, m := range mechanics {
		dist := 0.0
		if f.Lat != 0 && f.Lng != 0 {
			dist = haversine(f.Lat, f.Lng, m.Latitude, m.Longitude)
		}
		result = append(result, MechanicWithDistance{Mechanic: m, DistanceKm: math.Round(dist*10) / 10})
	}

	return result, total, nil
}

func (s *MechanicService) GetMechanic(id uuid.UUID) (*models.Mechanic, error) {
	var mechanic models.Mechanic
	err := s.db.Preload("User").First(&mechanic, "id = ?", id).Error
	return &mechanic, err
}

// GetByUserID — kirgan ustaning user_id si bo'yicha mechanic yozuvini topadi.
func (s *MechanicService) GetByUserID(userID uuid.UUID) (*models.Mechanic, error) {
	var mechanic models.Mechanic
	err := s.db.Preload("User").First(&mechanic, "user_id = ?", userID).Error
	return &mechanic, err
}

func (s *MechanicService) UpdateMechanicProfile(userID uuid.UUID, input map[string]interface{}) (*models.Mechanic, error) {
	var mechanic models.Mechanic
	if err := s.db.Where("user_id = ?", userID).First(&mechanic).Error; err != nil {
		return nil, err
	}
	s.db.Model(&mechanic).Updates(input)
	return &mechanic, nil
}

func (s *MechanicService) GetMyServices(mechanicID uuid.UUID, page, limit, offset int) ([]models.ServiceRecord, int64, error) {
	var records []models.ServiceRecord
	var total int64

	s.db.Model(&models.ServiceRecord{}).Where("mechanic_id = ?", mechanicID).Count(&total)
	err := s.db.Where("mechanic_id = ?", mechanicID).
		Preload("Vehicle").Preload("Owner").
		Order("created_at DESC").
		Limit(limit).Offset(offset).
		Find(&records).Error

	return records, total, err
}
