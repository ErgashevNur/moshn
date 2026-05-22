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
	"github.com/robfig/cron/v3"
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
		&models.Mechanic{},
		&models.Vehicle{},
		&models.PlateHistory{},
		&models.OwnershipHistory{},
		&models.ServiceRecord{},
		&models.Review{},
		&models.WarrantyClaim{},
		&models.Notification{},
		&models.FCMToken{},
		&models.SosRequest{},
		&models.RepairRequest{},
	); err != nil {
		log.Fatalf("AutoMigrate xatosi: %v", err)
	}

	log.Println("Database migratsiya muvaffaqiyatli")

	// Services
	wsHub := services.NewWSHub()
	notifSvc := services.NewNotificationService(db, cfg.FCMServerKey)
	emailSvc := services.NewEmailService(cfg.SMTPHost, cfg.SMTPPort, cfg.SMTPUser, cfg.SMTPPassword, cfg.SMTPFrom)
	authSvc := services.NewAuthService(db, emailSvc)
	vehicleSvc := services.NewVehicleService(db, cfg.ClaudeAPIKey)
	serviceRecordSvc := services.NewServiceRecordService(db, cfg.ClaudeAPIKey, cfg.UzbekVoiceAPIKey, notifSvc)
	mechanicSvc := services.NewMechanicService(db)
	reviewSvc := services.NewReviewService(db)
	warrantySvc := services.NewWarrantyService(db)
	searchSvc := services.NewSearchService(db)
	sosSvc := services.NewSosService(db, notifSvc, wsHub)
	repairSvc := services.NewRepairService(db, notifSvc)

	// Handlers
	h := routes.Handlers{
		Auth:         handlers.NewAuthHandler(authSvc),
		Profile:      handlers.NewProfileHandler(db),
		Vehicle:      handlers.NewVehicleHandler(vehicleSvc),
		Service:      handlers.NewServiceHandler(serviceRecordSvc, db),
		Mechanic:     handlers.NewMechanicHandler(mechanicSvc, reviewSvc),
		Review:       handlers.NewReviewHandler(reviewSvc),
		Warranty:     handlers.NewWarrantyHandler(warrantySvc),
		Notification: handlers.NewNotificationHandler(notifSvc),
		Search:       handlers.NewSearchHandler(searchSvc),
		Admin:        handlers.NewAdminHandler(db, notifSvc, warrantySvc, authSvc),
		Sos:          handlers.NewSosHandler(sosSvc),
		Repair:       handlers.NewRepairHandler(repairSvc),
		Assignment:   handlers.NewAssignmentHandler(sosSvc, repairSvc, mechanicSvc),
		WS:           handlers.NewWSHandler(wsHub),
	}

	// Cron: har soatda 48 soat o'tgan yozuvlarni auto-confirm
	c := cron.New()
	c.AddFunc("@hourly", func() {
		serviceRecordSvc.AutoConfirmExpired()
		log.Println("Auto-confirm cron ishladi")
	})
	c.Start()
	defer c.Stop()

	r := gin.Default()
	routes.Setup(r, h, routes.Options{AllowedOrigins: cfg.AllowedOrigins})

	addr := fmt.Sprintf(":%s", cfg.Port)
	log.Printf("Server %s portida ishga tushdi", cfg.Port)
	if err := r.Run(addr); err != nil {
		log.Fatalf("Server xatosi: %v", err)
	}
}
