package models

import (
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/gorm"
)

type User struct {
	ID                 uuid.UUID  `gorm:"type:uuid;primaryKey" json:"id"`
	Phone              string     `gorm:"uniqueIndex;not null" json:"phone"`
	Email              string     `gorm:"uniqueIndex;not null" json:"email"`
	PasswordHash       string     `gorm:"not null" json:"-"`
	Role               string     `gorm:"type:varchar(20);not null" json:"role"` // owner, service, admin
	FullName           string     `gorm:"not null" json:"full_name"`
	AvatarURL          string     `json:"avatar_url"`
	Language           string     `gorm:"default:'uz'" json:"language"`
	IsVerified         bool       `gorm:"default:false" json:"is_verified"`
	EmailVerified      bool       `gorm:"default:false" json:"email_verified"`
	EmailOTPCode       string     `json:"-"`
	EmailOTPExpiresAt  *time.Time `json:"-"`
	EmailOTPLastSentAt *time.Time `json:"-"`
	CreatedAt          time.Time  `json:"created_at"`
	UpdatedAt          time.Time  `json:"updated_at"`
}

func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.ID == uuid.Nil {
		u.ID = uuid.New()
	}
	return nil
}

// ShopProfile — shinomontaj nuqtasi profili
type ShopProfile struct {
	ID                 uuid.UUID      `gorm:"type:uuid;primaryKey" json:"id"`
	UserID             uuid.UUID      `gorm:"type:uuid;uniqueIndex;not null" json:"user_id"`
	User               User           `gorm:"foreignKey:UserID" json:"user,omitempty"`
	ShopName           string         `json:"shop_name"`
	Address            string         `gorm:"not null" json:"address"`
	Latitude           float64        `json:"latitude"`
	Longitude          float64        `json:"longitude"`
	Phone              string         `json:"phone"`
	WorkingHours       string         `json:"working_hours"`
	ServiceTypes       pq.StringArray `gorm:"type:text[]" json:"service_types"`
	VerificationStatus string         `gorm:"type:varchar(20);default:'pending'" json:"verification_status"` // pending, verified, rejected
	VerificationNotes  string         `json:"verification_notes"`
	RatingAvg          float64        `gorm:"default:0" json:"rating_avg"`
	RatingCount        int            `gorm:"default:0" json:"rating_count"`
	TotalBookings      int            `gorm:"default:0" json:"total_bookings"`
	CreatedAt          time.Time      `json:"created_at"`
	UpdatedAt          time.Time      `json:"updated_at"`
}

func (s *ShopProfile) BeforeCreate(tx *gorm.DB) error {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return nil
}

// Vehicle — plaka raqami asosiy identifikator
type Vehicle struct {
	ID        uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
	Plate     string    `gorm:"uniqueIndex;not null" json:"plate"`
	OwnerID   uuid.UUID `gorm:"type:uuid;not null" json:"owner_id"`
	Owner     User      `gorm:"foreignKey:OwnerID" json:"owner,omitempty"`
	Make      string    `json:"make"`
	Model     string    `json:"model"`
	Year      int       `json:"year"`
	Color     string    `json:"color"`
	PhotoURL  string    `json:"photo_url"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

func (v *Vehicle) BeforeCreate(tx *gorm.DB) error {
	if v.ID == uuid.Nil {
		v.ID = uuid.New()
	}
	return nil
}

// ServiceType — xizmat turlari katalogi
type ServiceType struct {
	ID        uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
	Slug      string    `gorm:"uniqueIndex;not null" json:"slug"` // pumping, tire_change, rim_repair
	NameUz    string    `gorm:"not null" json:"name_uz"`
	NameRu    string    `gorm:"not null" json:"name_ru"`
	Icon      string    `json:"icon"`
	BasePrice int       `json:"base_price"` // UZS
	IsActive  bool      `gorm:"default:true" json:"is_active"`
}

func (s *ServiceType) BeforeCreate(tx *gorm.DB) error {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
	}
	return nil
}

// Booking — bron qilish
type Booking struct {
	ID            uuid.UUID   `gorm:"type:uuid;primaryKey" json:"id"`
	CustomerID    uuid.UUID   `gorm:"type:uuid;not null" json:"customer_id"`
	Customer      User        `gorm:"foreignKey:CustomerID" json:"customer,omitempty"`
	ShopID        uuid.UUID   `gorm:"type:uuid;not null" json:"shop_id"`
	Shop          ShopProfile `gorm:"foreignKey:ShopID" json:"shop,omitempty"`
	VehicleID     uuid.UUID   `gorm:"type:uuid;not null" json:"vehicle_id"`
	Vehicle       Vehicle     `gorm:"foreignKey:VehicleID" json:"vehicle,omitempty"`
	ServiceTypeID uuid.UUID   `gorm:"type:uuid;not null" json:"service_type_id"`
	ServiceType   ServiceType `gorm:"foreignKey:ServiceTypeID" json:"service_type,omitempty"`
	ScheduledAt   time.Time   `gorm:"not null" json:"scheduled_at"`
	Notes         string      `json:"notes"`
	Status        string      `gorm:"type:varchar(30);default:'pending'" json:"status"` // pending, confirmed, in_progress, completed, cancelled
	TotalPrice    int         `json:"total_price"`
	CancelReason  string      `json:"cancel_reason"`
	CompletedAt   *time.Time  `json:"completed_at"`
	CreatedAt     time.Time   `json:"created_at"`
	UpdatedAt     time.Time   `json:"updated_at"`
}

func (b *Booking) BeforeCreate(tx *gorm.DB) error {
	if b.ID == uuid.Nil {
		b.ID = uuid.New()
	}
	return nil
}

// Payment — to'lov tranzaksiyasi
type Payment struct {
	ID        uuid.UUID  `gorm:"type:uuid;primaryKey" json:"id"`
	BookingID uuid.UUID  `gorm:"type:uuid;uniqueIndex;not null" json:"booking_id"`
	Booking   Booking    `gorm:"foreignKey:BookingID" json:"booking,omitempty"`
	Amount    int        `gorm:"not null" json:"amount"` // UZS
	Method    string     `gorm:"type:varchar(30)" json:"method"` // cash, card_qr, installment
	Status    string     `gorm:"type:varchar(20);default:'pending'" json:"status"` // pending, paid, failed
	QRCode    string     `json:"qr_code"`
	PaidAt    *time.Time `json:"paid_at"`
	CreatedAt time.Time  `json:"created_at"`
}

func (p *Payment) BeforeCreate(tx *gorm.DB) error {
	if p.ID == uuid.Nil {
		p.ID = uuid.New()
	}
	return nil
}

// Tip — chayivoye
type Tip struct {
	ID        uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
	BookingID uuid.UUID `gorm:"type:uuid;not null" json:"booking_id"`
	Booking   Booking   `gorm:"foreignKey:BookingID" json:"booking,omitempty"`
	Amount    int       `gorm:"not null" json:"amount"` // UZS
	CreatedAt time.Time `json:"created_at"`
}

func (t *Tip) BeforeCreate(tx *gorm.DB) error {
	if t.ID == uuid.Nil {
		t.ID = uuid.New()
	}
	return nil
}

// CustomerCard — servisning mijoz CRM kartochkasi
type CustomerCard struct {
	ID          uuid.UUID  `gorm:"type:uuid;primaryKey;uniqueIndex:idx_shop_customer" json:"id"`
	ShopID      uuid.UUID  `gorm:"type:uuid;not null;uniqueIndex:idx_shop_customer" json:"shop_id"`
	CustomerID  uuid.UUID  `gorm:"type:uuid;not null;uniqueIndex:idx_shop_customer" json:"customer_id"`
	Customer    User       `gorm:"foreignKey:CustomerID" json:"customer,omitempty"`
	IsVip       bool       `gorm:"default:false" json:"is_vip"`
	Notes       string     `json:"notes"`
	VisitCount  int        `gorm:"default:0" json:"visit_count"`
	LastVisitAt *time.Time `json:"last_visit_at"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
}

func (c *CustomerCard) BeforeCreate(tx *gorm.DB) error {
	if c.ID == uuid.Nil {
		c.ID = uuid.New()
	}
	return nil
}

// Review — ikki tomonlama baholash: owner→shop va shop→owner
type Review struct {
	ID          uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
	BookingID   uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_booking_type" json:"booking_id"`
	Booking     Booking   `gorm:"foreignKey:BookingID" json:"booking,omitempty"`
	AuthorID    uuid.UUID `gorm:"type:uuid;not null" json:"author_id"`
	Author      User      `gorm:"foreignKey:AuthorID" json:"author,omitempty"`
	TargetID    uuid.UUID `gorm:"type:uuid;not null" json:"target_id"` // shop_id yoki customer_id
	ReviewType  string    `gorm:"type:varchar(20);not null;uniqueIndex:idx_booking_type" json:"review_type"` // owner_to_shop, shop_to_owner
	Rating      int       `gorm:"not null" json:"rating"` // 1-5
	Comment     string    `json:"comment"`
	IsModerated bool      `gorm:"default:false" json:"is_moderated"`
	CreatedAt   time.Time `json:"created_at"`
}

func (r *Review) BeforeCreate(tx *gorm.DB) error {
	if r.ID == uuid.Nil {
		r.ID = uuid.New()
	}
	return nil
}

// SeasonalRule — mavsum bildirshnomasi qoidasi
type SeasonalRule struct {
	ID         uuid.UUID  `gorm:"type:uuid;primaryKey" json:"id"`
	Name       string     `gorm:"not null" json:"name"`
	SendMonth  int        `gorm:"not null" json:"send_month"` // 1-12
	SendDay    int        `gorm:"not null" json:"send_day"`   // 1-31
	MessageUz  string     `gorm:"not null" json:"message_uz"`
	MessageRu  string     `gorm:"not null" json:"message_ru"`
	IsActive   bool       `gorm:"default:true" json:"is_active"`
	LastSentAt *time.Time `json:"last_sent_at"`
	CreatedAt  time.Time  `json:"created_at"`
	UpdatedAt  time.Time  `json:"updated_at"`
}

func (s *SeasonalRule) BeforeCreate(tx *gorm.DB) error {
	if s.ID == uuid.Nil {
		s.ID = uuid.New()
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
