package main

import (
	"fmt"
	"log"
	"moshn/backend/config"
	"moshn/backend/handlers"
	"moshn/backend/models"
	"moshn/backend/routes"
	"moshn/backend/services"
	"moshn/backend/utils"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func main() {
	cfg := config.Load()

	utils.SetJWTSecret(cfg.JWTSecret)

	gin.SetMode(cfg.GinMode)

	db, err := gorm.Open(postgres.Open(cfg.DatabaseURL), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Info),
	})
	if err != nil {
		log.Fatalf("Database ulanishda xato: %v", err)
	}

	if err := db.AutoMigrate(
		&models.User{},
		&models.ShopProfile{},
		&models.Vehicle{},
		&models.ServiceType{},
		&models.Booking{},
		&models.Payment{},
		&models.Tip{},
		&models.CustomerCard{},
		&models.Review{},
		&models.SeasonalRule{},
		&models.Notification{},
		&models.FCMToken{},
	); err != nil {
		log.Fatalf("AutoMigrate xatosi: %v", err)
	}

	log.Println("Database migratsiya muvaffaqiyatli")

	// Services
	wsHub := services.NewWSHub()
	notifSvc := services.NewNotificationService(db, cfg.FCMServerKey)
	emailSvc := services.NewEmailService(cfg.SMTPHost, cfg.SMTPPort, cfg.SMTPUser, cfg.SMTPPassword, cfg.SMTPFrom)
	authSvc := services.NewAuthService(db, emailSvc)
	vehicleSvc := services.NewVehicleService(db)
	shopSvc := services.NewShopService(db)
	reviewSvc := services.NewReviewService(db)
	paymentSvc := services.NewPaymentService(db)
	bookingSvc := services.NewBookingService(db, notifSvc, wsHub, shopSvc)

	// Handlers
	h := routes.Handlers{
		Auth:         handlers.NewAuthHandler(authSvc),
		Profile:      handlers.NewProfileHandler(db),
		Vehicle:      handlers.NewVehicleHandler(vehicleSvc),
		Shop:         handlers.NewShopHandler(shopSvc, reviewSvc),
		Booking:      handlers.NewBookingHandler(bookingSvc, shopSvc),
		Payment:      handlers.NewPaymentHandler(paymentSvc),
		Review:       handlers.NewReviewHandler(reviewSvc),
		Notification: handlers.NewNotificationHandler(notifSvc),
		Admin:        handlers.NewAdminHandler(db, notifSvc, authSvc),
		WS:           handlers.NewWSHandler(wsHub),
	}

	r := gin.Default()
	routes.Setup(r, h, routes.Options{AllowedOrigins: cfg.AllowedOrigins})

	addr := fmt.Sprintf(":%s", cfg.Port)
	log.Printf("Shina24 server %s portida ishga tushdi", cfg.Port)
	if err := r.Run(addr); err != nil {
		log.Fatalf("Server xatosi: %v", err)
	}
}
