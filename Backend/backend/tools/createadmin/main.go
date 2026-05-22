package main

import (
	"flag"
	"fmt"
	"log"
	"strings"

	"moshn/backend/config"
	"moshn/backend/models"
	"moshn/backend/utils"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	phone := flag.String("phone", "+998901234567", "admin phone")
	email := flag.String("email", "admin@moshn.uz", "admin email")
	password := flag.String("password", "admin123", "admin password")
	name := flag.String("name", "Administrator", "full name")
	flag.Parse()

	cfg := config.Load()
	db, err := gorm.Open(postgres.Open(cfg.DatabaseURL), &gorm.Config{})
	if err != nil {
		log.Fatalf("DB ulanish xatosi: %v", err)
	}

	hash, err := utils.HashPassword(*password)
	if err != nil {
		log.Fatalf("hash xatosi: %v", err)
	}

	em := strings.ToLower(strings.TrimSpace(*email))
	var existing models.User
	if err := db.Where("phone = ? OR email = ?", *phone, em).First(&existing).Error; err == nil {
		// Mavjud foydalanuvchini admin qilamiz va parolini yangilaymiz
		existing.Role = "admin"
		existing.PasswordHash = hash
		existing.IsVerified = true
		existing.EmailVerified = true
		if err := db.Save(&existing).Error; err != nil {
			log.Fatalf("yangilash xatosi: %v", err)
		}
		fmt.Printf("Mavjud foydalanuvchi admin qilindi: %s\n", existing.Email)
		return
	}

	admin := models.User{
		Phone:         *phone,
		Email:         em,
		PasswordHash:  hash,
		Role:          "admin",
		FullName:      *name,
		IsVerified:    true,
		EmailVerified: true,
	}
	if err := db.Create(&admin).Error; err != nil {
		log.Fatalf("yaratish xatosi: %v", err)
	}
	fmt.Printf("Admin yaratildi!\n  Email: %s\n  Phone: %s\n  Parol: %s\n", admin.Email, admin.Phone, *password)
}
