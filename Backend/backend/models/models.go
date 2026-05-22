package models

import (
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

type User struct {
	ID                  uuid.UUID  `gorm:"type:uuid;primaryKey" json:"id"`
	Phone               string     `gorm:"uniqueIndex;not null" json:"phone"`
	Email               string     `gorm:"uniqueIndex;not null" json:"email"`
	PasswordHash        string     `gorm:"not null" json:"-"`
	Role                string     `gorm:"type:varchar(20);not null" json:"role"` // owner, mechanic
	FullName            string     `gorm:"not null" json:"full_name"`
	AvatarURL           string     `json:"avatar_url"`
	Language            string     `gorm:"default:'uz'" json:"language"`
	IsVerified          bool       `gorm:"default:false" json:"is_verified"`
	EmailVerified       bool       `gorm:"default:false" json:"email_verified"`
	EmailOTPCode        string     `json:"-"`
	EmailOTPExpiresAt   *time.Time `json:"-"`
	EmailOTPLastSentAt  *time.Time `json:"-"`
	CreatedAt           time.Time  `json:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at"`
}

func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.ID == uuid.Nil {
		u.ID = uuid.New()
	}
	return nil
}

type Mechanic struct {
	ID                 uuid.UUID      `gorm:"type:uuid;primaryKey" json:"id"`
	UserID             uuid.UUID      `gorm:"type:uuid;uniqueIndex;not null" json:"user_id"`
	User               User           `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Specialization     pq.StringArray `gorm:"type:text[]" json:"specialization"`
	WorkshopName       string         `json:"workshop_name"`
	WorkshopAddress    string         `gorm:"not null" json:"workshop_address"`
	Latitude           float64        `gorm:"not null" json:"latitude"`
	Longitude          float64        `gorm:"not null" json:"longitude"`
	WorkHours          string         `json:"work_hours"`
	StarLevel          int            `gorm:"default:0" json:"star_level"`
	VerificationStatus string         `gorm:"type:varchar(20);default:'pending'" json:"verification_status"`
	VerificationNotes  string         `json:"verification_notes"`
	TotalServices      int            `gorm:"default:0" json:"total_services"`
	RatingAvg          float64        `gorm:"default:0" json:"rating_avg"`
	RatingCount        int            `gorm:"default:0" json:"rating_count"`
	CreatedAt          time.Time      `json:"created_at"`
	UpdatedAt          time.Time      `json:"updated_at"`
}

func (m *Mechanic) BeforeCreate(tx *gorm.DB) error {
	if m.ID == uuid.Nil {
		m.ID = uuid.New()
	}
	return nil
}

type Vehicle struct {
	ID              uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
	VIN             string    `gorm:"uniqueIndex;size:17;not null" json:"vin"`
	CurrentPlate    string    `gorm:"not null" json:"current_plate"`
	OwnerID         uuid.UUID `gorm:"type:uuid;not null" json:"owner_id"`
	Owner           User      `gorm:"foreignKey:OwnerID" json:"owner,omitempty"`
	Make            string    `gorm:"not null" json:"make"`
	Model           string    `gorm:"not null" json:"model"`
	Year            int       `gorm:"not null" json:"year"`
	Color           string    `json:"color"`
	PhotoURL        string    `json:"photo_url"`
	TechpassportURL string    `json:"techpassport_url"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

func (v *Vehicle) BeforeCreate(tx *gorm.DB) error {
	if v.ID == uuid.Nil {
		v.ID = uuid.New()
	}
	return nil
}

type PlateHistory struct {
	ID          uuid.UUID  `gorm:"type:uuid;primaryKey" json:"id"`
	VehicleID   uuid.UUID  `gorm:"type:uuid;not null" json:"vehicle_id"`
	PlateNumber string     `gorm:"not null" json:"plate_number"`
	StartedAt   time.Time  `gorm:"not null" json:"started_at"`
	EndedAt     *time.Time `json:"ended_at"`
}

func (p *PlateHistory) BeforeCreate(tx *gorm.DB) error {
	if p.ID == uuid.Nil {
		p.ID = uuid.New()
	}
	return nil
}

type OwnershipHistory struct {
	ID        uuid.UUID  `gorm:"type:uuid;primaryKey" json:"id"`
	VehicleID uuid.UUID  `gorm:"type:uuid;not null" json:"vehicle_id"`
	OwnerID   uuid.UUID  `gorm:"type:uuid;not null" json:"owner_id"`
	Owner     User       `gorm:"foreignKey:OwnerID" json:"owner,omitempty"`
	StartedAt time.Time  `gorm:"not null" json:"started_at"`
	EndedAt   *time.Time `json:"ended_at"`
}

func (o *OwnershipHistory) BeforeCreate(tx *gorm.DB) error {
	if o.ID == uuid.Nil {
		o.ID = uuid.New()
	}
	return nil
}

type ServiceRecord struct {
	ID           uuid.UUID      `gorm:"type:uuid;primaryKey" json:"id"`
	VehicleID    uuid.UUID      `gorm:"type:uuid;not null" json:"vehicle_id"`
	Vehicle      Vehicle        `gorm:"foreignKey:VehicleID" json:"vehicle,omitempty"`
	MechanicID   uuid.UUID      `gorm:"type:uuid;not null" json:"mechanic_id"`
	Mechanic     Mechanic       `gorm:"foreignKey:MechanicID" json:"mechanic,omitempty"`
	OwnerID      uuid.UUID      `gorm:"type:uuid;not null" json:"owner_id"`
	Owner        User           `gorm:"foreignKey:OwnerID" json:"owner,omitempty"`
	ServiceDate  time.Time      `gorm:"not null" json:"service_date"`
	MileageKm    *int           `json:"mileage_km"`
	ServiceType  string         `gorm:"not null" json:"service_type"`
	Description  string         `gorm:"not null" json:"description"`
	PartsUsed    datatypes.JSON `gorm:"type:jsonb" json:"parts_used"`
	PriceUZS     *int64         `json:"price_uzs"`
	Notes        string         `json:"notes"`
	VoiceTextRaw string         `json:"voice_text_raw"`
	LLMParsed    datatypes.JSON `gorm:"type:jsonb" json:"llm_parsed"`
	PhotoBefore  pq.StringArray `gorm:"type:text[]" json:"photo_before"`
	PhotoAfter   pq.StringArray `gorm:"type:text[]" json:"photo_after"`
	Status       string         `gorm:"type:varchar(30);default:'created'" json:"status"`
	ConfirmedAt  *time.Time     `json:"confirmed_at"`
	AutoConfirmed bool          `gorm:"default:false" json:"auto_confirmed"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
}

func (s *ServiceRecord) BeforeCreate(tx *gorm.DB) error {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return nil
}

type Review struct {
	ID              uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
	ServiceRecordID uuid.UUID `gorm:"type:uuid;uniqueIndex;not null" json:"service_record_id"`
	MechanicID      uuid.UUID `gorm:"type:uuid;not null" json:"mechanic_id"`
	Mechanic        Mechanic  `gorm:"foreignKey:MechanicID" json:"mechanic,omitempty"`
	OwnerID         uuid.UUID `gorm:"type:uuid;not null" json:"owner_id"`
	Owner           User      `gorm:"foreignKey:OwnerID" json:"owner,omitempty"`
	Rating          int       `gorm:"not null" json:"rating"`
	Comment         string    `json:"comment"`
	IsModerated     bool      `gorm:"default:false" json:"is_moderated"`
	CreatedAt       time.Time `json:"created_at"`
}

func (r *Review) BeforeCreate(tx *gorm.DB) error {
	if r.ID == uuid.Nil {
		r.ID = uuid.New()
	}
	return nil
}

type WarrantyClaim struct {
	ID              uuid.UUID      `gorm:"type:uuid;primaryKey" json:"id"`
	ServiceRecordID uuid.UUID      `gorm:"type:uuid;not null" json:"service_record_id"`
	OwnerID         uuid.UUID      `gorm:"type:uuid;not null" json:"owner_id"`
	Owner           User           `gorm:"foreignKey:OwnerID" json:"owner,omitempty"`
	MechanicID      uuid.UUID      `gorm:"type:uuid;not null" json:"mechanic_id"`
	Mechanic        Mechanic       `gorm:"foreignKey:MechanicID" json:"mechanic,omitempty"`
	Description     string         `gorm:"not null" json:"description"`
	EvidencePhotos  pq.StringArray `gorm:"type:text[]" json:"evidence_photos"`
	Status          string         `gorm:"type:varchar(20);default:'open'" json:"status"`
	AdminNotes      string         `json:"admin_notes"`
	AmountUZS       *int64         `json:"amount_uzs"`
	CreatedAt       time.Time      `json:"created_at"`
	ResolvedAt      *time.Time     `json:"resolved_at"`
}

func (w *WarrantyClaim) BeforeCreate(tx *gorm.DB) error {
	if w.ID == uuid.Nil {
		w.ID = uuid.New()
	}
	return nil
}

type Notification struct {
	ID          uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
	UserID      uuid.UUID `gorm:"type:uuid;not null" json:"user_id"`
	Title       string    `gorm:"not null" json:"title"`
	Body        string    `gorm:"not null" json:"body"`
	Type        string    `json:"type"`
	ReferenceID string    `json:"reference_id"`
	IsRead      bool      `gorm:"default:false" json:"is_read"`
	CreatedAt   time.Time `json:"created_at"`
}

func (n *Notification) BeforeCreate(tx *gorm.DB) error {
	if n.ID == uuid.Nil {
		n.ID = uuid.New()
	}
	return nil
}

type FCMToken struct {
	ID        uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
	UserID    uuid.UUID `gorm:"type:uuid;not null" json:"user_id"`
	Token     string    `gorm:"not null" json:"token"`
	Platform  string    `gorm:"type:varchar(10)" json:"platform"` // ios, android
	CreatedAt time.Time `json:"created_at"`
}

func (f *FCMToken) BeforeCreate(tx *gorm.DB) error {
	if f.ID == uuid.Nil {
		f.ID = uuid.New()
	}
	return nil
}

// SosRequest — favqulodda yordam so'rovi. Mashina egasi yo'lda qolganda
// tasdiqlangan telefon raqami va joylashuvini operatorga yuboradi.
type SosRequest struct {
	ID        uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
	UserID    uuid.UUID `gorm:"type:uuid;not null" json:"user_id"`
	User      User      `gorm:"foreignKey:UserID" json:"user,omitempty"`
	// Phone — so'rov uchun tasdiqlangan aloqa raqami (akkaunt raqamidan farq qilishi mumkin).
	Phone     string    `gorm:"not null" json:"phone"`
	Latitude  float64   `gorm:"not null" json:"latitude"`
	Longitude float64   `gorm:"not null" json:"longitude"`
	// Address — teskari geokodlash yoki qo'lda tanlangan manzil izohi.
	Address string `json:"address"`
	// AssignedMechanicID — operator SOS so'rovini yo'naltirgan usta.
	AssignedMechanicID *uuid.UUID `gorm:"type:uuid" json:"assigned_mechanic_id"`
	AssignedMechanic   *Mechanic  `gorm:"foreignKey:AssignedMechanicID" json:"assigned_mechanic,omitempty"`
	Status             string     `gorm:"type:varchar(20);default:'new'" json:"status"` // new, in_progress, resolved, cancelled
	AdminNotes         string     `json:"admin_notes"`
	CreatedAt          time.Time  `json:"created_at"`
	ResolvedAt         *time.Time `json:"resolved_at"`
}

func (s *SosRequest) BeforeCreate(tx *gorm.DB) error {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return nil
}

// RepairRequest — mijoz tamirlash uchun usta tanlab, operatorga so'rov yuboradi.
// Operator usta bilan gaplashib so'rovni unga yo'naltiradi (assign); yo'naltirilgach
// usta mijoz ma'lumotlarini ko'radi.
type RepairRequest struct {
	ID     uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
	UserID uuid.UUID `gorm:"type:uuid;not null" json:"user_id"`
	User   User      `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Phone  string    `gorm:"not null" json:"phone"`
	// PreferredMechanicID — mijoz dastlab tanlagan usta.
	PreferredMechanicID *uuid.UUID `gorm:"type:uuid" json:"preferred_mechanic_id"`
	PreferredMechanic   *Mechanic  `gorm:"foreignKey:PreferredMechanicID" json:"preferred_mechanic,omitempty"`
	// AssignedMechanicID — operator yakuniy yo'naltirgan usta.
	AssignedMechanicID *uuid.UUID `gorm:"type:uuid" json:"assigned_mechanic_id"`
	AssignedMechanic   *Mechanic  `gorm:"foreignKey:AssignedMechanicID" json:"assigned_mechanic,omitempty"`
	CarInfo            string     `json:"car_info"`
	Description        string     `gorm:"not null" json:"description"`
	Status             string     `gorm:"type:varchar(20);default:'new'" json:"status"` // new, in_progress, resolved, cancelled
	AdminNotes         string     `json:"admin_notes"`
	CreatedAt          time.Time  `json:"created_at"`
	ResolvedAt         *time.Time `json:"resolved_at"`
}

func (r *RepairRequest) BeforeCreate(tx *gorm.DB) error {
	if r.ID == uuid.Nil {
		r.ID = uuid.New()
	}
	return nil
}
