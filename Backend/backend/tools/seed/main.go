package main

import (
	"fmt"
	"log"
	"math/rand"

	"moshn/backend/config"
	"moshn/backend/models"
	"moshn/backend/utils"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type mechSeed struct {
	Name           string
	Phone          string
	Email          string
	Workshop       string
	Address        string
	Specialization []string
	Lat            float64
	Lng            float64
	WorkHours      string
}

var mechanics = []mechSeed{
	{"Akmal Karimov", "+998901110001", "mechanic1@moshn.uz", "Akmal Auto Service", "Chilonzor t., Bunyodkor ko'chasi 12", []string{"Dvigatel", "Moy almashtirish"}, 41.2756, 69.2034, "09:00 - 19:00"},
	{"Bobur Tursunov", "+998901110002", "mechanic2@moshn.uz", "Bobur Motors", "Yunusobod t., Amir Temur ko'chasi 88", []string{"Xodovoy", "Tormoz"}, 41.3500, 69.2890, "08:00 - 20:00"},
	{"Sardor Aliyev", "+998901110003", "mechanic3@moshn.uz", "Sardor Elektrik", "Mirzo Ulug'bek t., Buyuk Ipak Yo'li 45", []string{"Elektrika", "Diagnostika"}, 41.3250, 69.3340, "09:00 - 18:00"},
	{"Jasur Rahimov", "+998901110004", "mechanic4@moshn.uz", "Jasur Konditsioner", "Sergeli t., Yangi Sergeli 7", []string{"Konditsioner", "Elektrika"}, 41.2230, 69.2210, "10:00 - 19:00"},
	{"Doniyor Yusupov", "+998901110005", "mechanic5@moshn.uz", "Doniyor Kuzov", "Olmazor t., Sebzor 21", []string{"Kuzov", "Bo'yoq"}, 41.3450, 69.2410, "09:00 - 19:00"},
	{"Otabek Nazarov", "+998901110006", "mechanic6@moshn.uz", "Otabek Avtoservis", "Shayxontohur t., Navoiy ko'chasi 34", []string{"Dvigatel", "Xodovoy", "Tormoz"}, 41.3180, 69.2390, "08:30 - 19:30"},
	{"Sherzod Qodirov", "+998901110007", "mechanic7@moshn.uz", "Sherzod Shina", "Chilonzor t., Qatortol ko'chasi 56", []string{"Shina", "Balansirovka"}, 41.2840, 69.2050, "09:00 - 21:00"},
	{"Bekzod Ergashev", "+998901110008", "mechanic8@moshn.uz", "Bekzod Diagnostika", "Yashnobod t., Tuzel 3", []string{"Diagnostika", "Elektrika"}, 41.2900, 69.3500, "09:00 - 18:00"},
	{"Farrux Mahmudov", "+998901110009", "mechanic9@moshn.uz", "Farrux Transmissiya", "Bektemir t., Bektemir ko'chasi 9", []string{"Transmissiya", "Dvigatel"}, 41.2050, 69.3340, "09:00 - 19:00"},
	{"Ulug'bek Sobirov", "+998901110010", "mechanic10@moshn.uz", "Ulug'bek Auto", "Mirobod t., Oybek ko'chasi 14", []string{"Moy almashtirish", "Diagnostika", "Konditsioner"}, 41.2980, 69.2700, "08:00 - 20:00"},
}

type ownerSeed struct {
	Name  string
	Phone string
	Email string
}

var owners = []ownerSeed{
	{"Aziz Rashidov", "+998902220001", "owner1@moshn.uz"},
	{"Dilshod Komilov", "+998902220002", "owner2@moshn.uz"},
	{"Sanjar Yo'ldoshev", "+998902220003", "owner3@moshn.uz"},
	{"Rustam Bekov", "+998902220004", "owner4@moshn.uz"},
	{"Javohir Islomov", "+998902220005", "owner5@moshn.uz"},
	{"Kamol Toshpo'latov", "+998902220006", "owner6@moshn.uz"},
}

var comments = []struct {
	Rating int
	Text   string
}{
	{5, "Juda professional usta, ishini a'lo darajada bajardi. Tavsiya qilaman!"},
	{5, "Tez va sifatli xizmat. Narxlari ham hamyonbop."},
	{4, "Yaxshi mutaxassis, lekin biroz kutishga to'g'ri keldi."},
	{5, "Mashinamni mukammal tuzatdi, rahmat!"},
	{4, "Ishidan mamnunman, yana murojaat qilaman."},
	{3, "O'rtacha, ish bajarildi lekin narx biroz qimmat."},
	{5, "Halol va vijdonli usta. Hammaga tavsiya qilaman."},
	{4, "Diagnostikani aniq qildi, muammoni topdi."},
	{5, "Ajoyib xizmat, vaqtida tugatdi va kafolat berdi."},
	{4, "Yaxshi munosabat, ishni puxta bajaradi."},
}

func main() {
	cfg := config.Load()
	db, err := gorm.Open(postgres.Open(cfg.DatabaseURL), &gorm.Config{})
	if err != nil {
		log.Fatalf("DB ulanish xatosi: %v", err)
	}

	pwHash, _ := utils.HashPassword("test123")

	// Owner reviewer foydalanuvchilarni yaratish
	ownerIDs := make([]uuid.UUID, 0, len(owners))
	for _, o := range owners {
		var u models.User
		if err := db.Where("email = ?", o.Email).First(&u).Error; err == nil {
			ownerIDs = append(ownerIDs, u.ID)
			continue
		}
		u = models.User{
			Phone: o.Phone, Email: o.Email, PasswordHash: pwHash,
			Role: "owner", FullName: o.Name, IsVerified: true, EmailVerified: true,
		}
		if err := db.Create(&u).Error; err != nil {
			log.Fatalf("owner yaratish xatosi (%s): %v", o.Email, err)
		}
		ownerIDs = append(ownerIDs, u.ID)
	}
	fmt.Printf("Owner (reviewer) foydalanuvchilar: %d ta tayyor\n", len(ownerIDs))

	created, skipped := 0, 0
	for _, ms := range mechanics {
		var existing models.User
		if err := db.Where("email = ?", ms.Email).First(&existing).Error; err == nil {
			skipped++
			continue
		}

		user := models.User{
			Phone: ms.Phone, Email: ms.Email, PasswordHash: pwHash,
			Role: "mechanic", FullName: ms.Name, IsVerified: true, EmailVerified: true,
		}
		if err := db.Create(&user).Error; err != nil {
			log.Fatalf("usta user yaratish xatosi (%s): %v", ms.Email, err)
		}

		mech := models.Mechanic{
			UserID:             user.ID,
			Specialization:     pq.StringArray(ms.Specialization),
			WorkshopName:       ms.Workshop,
			WorkshopAddress:    ms.Address,
			Latitude:           ms.Lat,
			Longitude:          ms.Lng,
			WorkHours:          ms.WorkHours,
			VerificationStatus: "verified",
			StarLevel:          3 + rand.Intn(3), // 3..5
		}
		if err := db.Create(&mech).Error; err != nil {
			log.Fatalf("usta yaratish xatosi (%s): %v", ms.Email, err)
		}

		// Har bir ustaga 2..4 ta sharh
		n := 2 + rand.Intn(3)
		sum := 0
		used := map[int]bool{}
		for i := 0; i < n; i++ {
			ci := rand.Intn(len(comments))
			for used[ci] {
				ci = rand.Intn(len(comments))
			}
			used[ci] = true
			cm := comments[ci]
			ownerID := ownerIDs[rand.Intn(len(ownerIDs))]
			review := models.Review{
				ServiceRecordID: uuid.New(), // seed: haqiqiy service record yo'q, unique UUID
				MechanicID:      mech.ID,
				OwnerID:         ownerID,
				Rating:          cm.Rating,
				Comment:         cm.Text,
				IsModerated:     true,
			}
			if err := db.Create(&review).Error; err != nil {
				log.Fatalf("sharh yaratish xatosi: %v", err)
			}
			sum += cm.Rating
		}

		// Reyting va statistikani sharhlarga moslab yangilash
		avg := float64(sum) / float64(n)
		db.Model(&mech).Updates(map[string]interface{}{
			"rating_avg":     avg,
			"rating_count":   n,
			"total_services": n + rand.Intn(20),
		})

		created++
		fmt.Printf("  ✓ %s (%s) — %d sharh, reyting %.1f\n", ms.Name, ms.Workshop, n, avg)
	}

	fmt.Printf("\nTugadi: %d usta yaratildi, %d o'tkazib yuborildi (mavjud edi)\n", created, skipped)
}
