package main

import (
	"fmt"
	"log"
	"math/rand"

	"moshn/backend/config"
	"moshn/backend/models"
	"moshn/backend/utils"

	"github.com/lib/pq"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type shopSeed struct {
	Name         string
	Phone        string
	Email        string
	ShopName     string
	Address      string
	ServiceTypes []string
	Lat          float64
	Lng          float64
	WorkingHours string
}

var shops = []shopSeed{
	{"Akmal Karimov", "+998901110001", "shop1@shina24.uz", "Shinmaster Pro", "Yunusobod t., Amir Temur 108", []string{"tire_change", "pumping", "balancing"}, 41.3500, 69.2890, "08:00-22:00"},
	{"Bobur Tursunov", "+998901110002", "shop2@shina24.uz", "Avto Shina 24/7", "Chilonzor t., Bunyodkor 12", []string{"tire_change", "patch", "pumping"}, 41.2756, 69.2034, "00:00-00:00"},
	{"Sardor Aliyev", "+998901110003", "shop3@shina24.uz", "Disk & Tire Center", "Mirzo Ulug'bek t., Buyuk Ipak Yo'li 45", []string{"rim_repair", "balancing", "tire_change"}, 41.3250, 69.3340, "09:00-20:00"},
	{"Jasur Rahimov", "+998901110004", "shop4@shina24.uz", "Tezkor Balon", "Sergeli t., Yangi Sergeli 7", []string{"tire_change", "pumping"}, 41.2230, 69.2210, "08:00-19:00"},
	{"Doniyor Yusupov", "+998901110005", "shop5@shina24.uz", "Premium Shina Markazi", "Olmazor t., Sebzor 21", []string{"tire_change", "rim_repair", "balancing", "storage"}, 41.3450, 69.2410, "09:00-19:00"},
}

type ownerSeed struct {
	Name  string
	Phone string
	Email string
}

var owners = []ownerSeed{
	{"Aziz Rashidov", "+998902220001", "owner1@shina24.uz"},
	{"Dilshod Komilov", "+998902220002", "owner2@shina24.uz"},
	{"Sanjar Yo'ldoshev", "+998902220003", "owner3@shina24.uz"},
	{"Rustam Bekov", "+998902220004", "owner4@shina24.uz"},
}

var comments = []struct {
	Rating int
	Text   string
}{
	{5, "Juda tez va sifatli xizmat. Tavsiya qilaman!"},
	{5, "Narxlari ham hamyonbop, ustalari professional."},
	{4, "Yaxshi shinomontaj, lekin biroz kutishga to'g'ri keldi."},
	{5, "Mashinamni mukammal tuzatdi, rahmat!"},
	{4, "Ishidan mamnunman, yana murojaat qilaman."},
	{5, "Ajoyib xizmat, vaqtida tugatdi."},
}

func main() {
	cfg := config.Load()
	db, err := gorm.Open(postgres.Open(cfg.DatabaseURL), &gorm.Config{})
	if err != nil {
		log.Fatalf("DB ulanish xatosi: %v", err)
	}

	pwHash, _ := utils.HashPassword("test123")

	// Egalarni yaratish
	ownerIDs := make([]interface{}, 0)
	for _, o := range owners {
		var u models.User
		if db.Where("email = ?", o.Email).First(&u).Error == nil {
			ownerIDs = append(ownerIDs, u.ID)
			continue
		}
		u = models.User{
			Phone: o.Phone, Email: o.Email, PasswordHash: pwHash,
			Role: "owner", FullName: o.Name, IsVerified: true, EmailVerified: true,
		}
		if err := db.Create(&u).Error; err != nil {
			log.Fatalf("owner yaratish xatosi: %v", err)
		}
		ownerIDs = append(ownerIDs, u.ID)
	}
	fmt.Printf("Owner foydalanuvchilar: %d ta tayyor\n", len(ownerIDs))

	// Shinomontajlarni yaratish
	created, skipped := 0, 0
	for _, ss := range shops {
		var existing models.User
		if db.Where("email = ?", ss.Email).First(&existing).Error == nil {
			skipped++
			continue
		}

		user := models.User{
			Phone: ss.Phone, Email: ss.Email, PasswordHash: pwHash,
			Role: "service", FullName: ss.Name, IsVerified: true, EmailVerified: true,
		}
		if err := db.Create(&user).Error; err != nil {
			log.Fatalf("servis user yaratish xatosi: %v", err)
		}

		shop := models.ShopProfile{
			UserID:             user.ID,
			ShopName:           ss.ShopName,
			Address:            ss.Address,
			Latitude:           ss.Lat,
			Longitude:          ss.Lng,
			Phone:              ss.Phone,
			WorkingHours:       ss.WorkingHours,
			ServiceTypes:       pq.StringArray(ss.ServiceTypes),
			VerificationStatus: "verified",
		}
		if err := db.Create(&shop).Error; err != nil {
			log.Fatalf("servis yaratish xatosi: %v", err)
		}

		n := 2 + rand.Intn(3)
		sum := 0
		for i := 0; i < n; i++ {
			cm := comments[rand.Intn(len(comments))]
			sum += cm.Rating
		}
		avg := float64(sum) / float64(n)
		db.Model(&shop).Updates(map[string]interface{}{
			"rating_avg":     avg,
			"rating_count":   n,
			"total_bookings": n + rand.Intn(30),
		})

		created++
		fmt.Printf("  ✓ %s (%s) — reyting %.1f\n", ss.Name, ss.ShopName, avg)
	}

	// Xizmat turlari
	serviceTypes := []models.ServiceType{
		{Slug: "tire_change", NameUz: "G'ildirak almashtirish", NameRu: "Переобувка", Icon: "snow", BasePrice: 80000},
		{Slug: "pumping", NameUz: "Havo to'ldirish", NameRu: "Подкачка", Icon: "gauge", BasePrice: 15000},
		{Slug: "patch", NameUz: "Teshik yamash", NameRu: "Ремонт прокола", Icon: "wrench", BasePrice: 35000},
		{Slug: "balancing", NameUz: "Balanslash", NameRu: "Балансировка", Icon: "disc", BasePrice: 60000},
		{Slug: "rim_repair", NameUz: "Disk ta'mirlash", NameRu: "Ремонт диска", Icon: "disc", BasePrice: 120000},
		{Slug: "storage", NameUz: "Mavsumiy saqlash", NameRu: "Хранение шин", Icon: "layers", BasePrice: 200000},
	}
	for _, st := range serviceTypes {
		var existing models.ServiceType
		if db.Where("slug = ?", st.Slug).First(&existing).Error != nil {
			db.Create(&st)
			fmt.Printf("  + Xizmat turi: %s\n", st.NameUz)
		}
	}

	fmt.Printf("\nTugadi: %d shinomontaj yaratildi, %d o'tkazib yuborildi\n", created, skipped)
}
