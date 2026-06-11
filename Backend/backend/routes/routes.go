package routes

import (
	"net/http"
	"moshn/backend/handlers"
	"moshn/backend/middleware"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

type Handlers struct {
	Auth         *handlers.AuthHandler
	Profile      *handlers.ProfileHandler
	Vehicle      *handlers.VehicleHandler
	Shop         *handlers.ShopHandler
	Booking      *handlers.BookingHandler
	Payment      *handlers.PaymentHandler
	Review       *handlers.ReviewHandler
	Notification *handlers.NotificationHandler
	Admin        *handlers.AdminHandler
	WS           *handlers.WSHandler
}

type Options struct {
	AllowedOrigins []string
}

func Setup(r *gin.Engine, h Handlers, opts Options) {
	corsCfg := cors.Config{
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization", "Accept"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}
	if len(opts.AllowedOrigins) == 0 {
		corsCfg.AllowOrigins = []string{"http://localhost:3000", "http://localhost:8080"}
	} else {
		corsCfg.AllowOrigins = opts.AllowedOrigins
	}
	r.Use(cors.New(corsCfg))

	globalLimiter := middleware.NewRateLimiter(120)
	r.Use(globalLimiter.Middleware())

	r.Static("/uploads", "/app/uploads")
	r.GET("/health", func(c *gin.Context) { c.JSON(http.StatusOK, gin.H{"status": "ok"}) })

	v1 := r.Group("/v1")

	// Auth (public)
	authLimiter := middleware.NewRateLimiter(10)
	auth := v1.Group("/auth")
	auth.Use(authLimiter.Middleware())
	{
		auth.POST("/register", h.Auth.Register)
		auth.POST("/login", h.Auth.Login)
		auth.POST("/refresh", h.Auth.RefreshToken)
		auth.POST("/send-otp", h.Auth.SendOTP)
		auth.POST("/verify-otp", h.Auth.VerifyOTP)
	}

	// Shinomontajlar ommaviy qidiruvi (autentifikatsiyasiz)
	v1.GET("/shops", h.Shop.GetShops)
	v1.GET("/shops/:id", h.Shop.GetShop)
	v1.GET("/shops/:id/reviews", h.Shop.GetShopReviews)

	// Xizmat turlari katalogi (ommaviy)
	v1.GET("/service-types", h.Admin.ListServiceTypes)

	// Plaka bo'yicha qidiruv (autentifikatsiyasiz — autosignal)
	v1.GET("/vehicles/lookup/:plate", h.Vehicle.LookupByPlate)

	// WebSocket — servis planshetiga real-vaqt bronlar
	v1.GET("/ws", h.WS.Connect)

	// Himoyalangan marshrutlar
	protected := v1.Group("/")
	protected.Use(middleware.AuthRequired())
	{
		// Profil
		protected.GET("/profile", h.Profile.GetProfile)
		protected.PUT("/profile", h.Profile.UpdateProfile)
		protected.PUT("/profile/role", h.Profile.SetRole)
		protected.PUT("/profile/language", h.Profile.UpdateLanguage)
		protected.PUT("/profile/avatar", h.Profile.UploadAvatar)

		// Avtomobillar (owner)
		protected.POST("/vehicles", h.Vehicle.CreateVehicle)
		protected.GET("/vehicles", h.Vehicle.GetVehicles)
		protected.GET("/vehicles/:id", h.Vehicle.GetVehicle)
		protected.PUT("/vehicles/:id", h.Vehicle.UpdateVehicle)
		protected.DELETE("/vehicles/:id", h.Vehicle.DeleteVehicle)

		// Bronlar — mijoz tomonidan
		protected.POST("/bookings", h.Booking.CreateBooking)
		protected.GET("/bookings", h.Booking.GetMyBookings)
		protected.GET("/bookings/:id", h.Booking.GetBooking)
		protected.PUT("/bookings/:id/cancel", h.Booking.CancelBooking)

		// To'lov
		protected.GET("/payments/:booking_id", h.Payment.GetPayment)
		protected.POST("/payments/:booking_id/qr", h.Payment.GenerateQR)
		protected.POST("/payments/:booking_id/pay", h.Payment.MarkPaid)
		protected.POST("/payments/:booking_id/tip", h.Payment.AddTip)

		// Baholash
		protected.POST("/reviews", h.Review.CreateReview)
		protected.GET("/reviews/:id", h.Review.GetReview)
		protected.GET("/reviews/customer/:id", h.Review.GetCustomerReviews)

		// Bildirishnomalar
		protected.GET("/notifications", h.Notification.GetNotifications)
		protected.PUT("/notifications/:id/read", h.Notification.MarkAsRead)
		protected.POST("/notifications/fcm-token", h.Notification.RegisterFCMToken)

		// Servis tomonidagi marshrutlar (service roli)
		service := protected.Group("/service")
		service.Use(middleware.ServiceOnly())
		{
			service.GET("/profile", h.Shop.GetMyShop)
			service.PUT("/profile", h.Shop.UpdateProfile)
			service.GET("/bookings", h.Booking.GetShopBookings)
			service.PUT("/bookings/:id/confirm", h.Booking.ConfirmBooking)
			service.PUT("/bookings/:id/start", h.Booking.StartBooking)
			service.PUT("/bookings/:id/complete", h.Booking.CompleteBooking)
			service.PUT("/bookings/:id/cancel", h.Booking.ShopCancelBooking)
			service.GET("/customers", h.Shop.GetCustomers)
			service.GET("/customers/:customer_id", h.Shop.GetCustomerCard)
			service.PUT("/customers/:customer_id", h.Shop.UpdateCustomerCard)
		}
	}

	// Admin marshrutlari
	admin := v1.Group("/admin")
	admin.Use(middleware.AuthRequired(), middleware.AdminOnly())
	{
		admin.GET("/stats", h.Admin.GetStats)

		// Shinomontajlar boshqaruvi
		admin.GET("/shops", h.Admin.ListShops)
		admin.POST("/shops", h.Admin.CreateShop)
		admin.PUT("/shops/:id/verify", h.Admin.VerifyShop)

		// Bronlar
		admin.GET("/bookings", h.Admin.ListBookings)

		// Foydalanuvchilar va avtomobillar
		admin.GET("/users", h.Admin.ListUsers)
		admin.GET("/vehicles", h.Admin.ListVehicles)

		// Sharhlar
		admin.GET("/reviews", h.Admin.ListReviews)
		admin.PUT("/reviews/:id/moderate", h.Admin.ModerateReview)

		// Xizmat turlari katalogi
		admin.GET("/service-types", h.Admin.ListServiceTypes)
		admin.POST("/service-types", h.Admin.CreateServiceType)

		// Mavsum bildirshnoma qoidalari
		admin.GET("/seasonal-rules", h.Admin.ListSeasonalRules)
		admin.POST("/seasonal-rules", h.Admin.CreateSeasonalRule)
		admin.PUT("/seasonal-rules/:id", h.Admin.UpdateSeasonalRule)
		admin.POST("/seasonal-rules/:id/send", h.Admin.SendSeasonalNow)

		// Broadcast bildirshnoma
		admin.POST("/notifications/broadcast", h.Admin.SendBroadcastNotification)
	}
}
