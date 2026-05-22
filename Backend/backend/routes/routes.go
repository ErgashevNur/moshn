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
	Service      *handlers.ServiceHandler
	Mechanic     *handlers.MechanicHandler
	Review       *handlers.ReviewHandler
	Warranty     *handlers.WarrantyHandler
	Notification *handlers.NotificationHandler
	Search       *handlers.SearchHandler
	Admin        *handlers.AdminHandler
	Sos          *handlers.SosHandler
	Repair       *handlers.RepairHandler
	Assignment   *handlers.AssignmentHandler
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
		// Safe default: only localhost dev. Set ALLOWED_ORIGINS env var in prod.
		corsCfg.AllowOrigins = []string{"http://localhost:3000", "http://localhost:8080"}
	} else {
		corsCfg.AllowOrigins = opts.AllowedOrigins
	}
	r.Use(cors.New(corsCfg))

	// Rate limit: 120 req/min per IP globally
	globalLimiter := middleware.NewRateLimiter(120)
	r.Use(globalLimiter.Middleware())

	r.Static("/uploads", "/app/uploads")
	r.GET("/health", func(c *gin.Context) { c.JSON(http.StatusOK, gin.H{"status": "ok"}) })

	v1 := r.Group("/v1")

	// Auth (public) — stricter rate limit on login/register to slow brute force
	authLimiter := middleware.NewRateLimiter(10) // 10 req/min/IP
	auth := v1.Group("/auth")
	auth.Use(authLimiter.Middleware())
	{
		auth.POST("/register", h.Auth.Register)
		auth.POST("/login", h.Auth.Login)
		auth.POST("/refresh", h.Auth.RefreshToken)
		auth.POST("/send-otp", h.Auth.SendOTP)
		auth.POST("/verify-otp", h.Auth.VerifyOTP)
	}

	// Protected routes
	protected := v1.Group("/")
	protected.Use(middleware.AuthRequired())
	{
		// Profile
		protected.GET("/profile", h.Profile.GetProfile)
		protected.PUT("/profile", h.Profile.UpdateProfile)
		protected.PUT("/profile/language", h.Profile.UpdateLanguage)
		protected.PUT("/profile/avatar", h.Profile.UploadAvatar)

		// Vehicles
		protected.POST("/vehicles", h.Vehicle.CreateVehicle)
		protected.GET("/vehicles", h.Vehicle.GetVehicles)
		protected.GET("/vehicles/:id", h.Vehicle.GetVehicle)
		protected.PUT("/vehicles/:id", h.Vehicle.UpdateVehicle)
		protected.DELETE("/vehicles/:id", h.Vehicle.DeleteVehicle)
		protected.POST("/vehicles/ocr", h.Vehicle.OCRVehicle)
		protected.GET("/vehicles/:id/history", h.Vehicle.GetHistory)
		protected.POST("/vehicles/:id/transfer", h.Vehicle.TransferOwnership)

		// Service records
		protected.POST("/services", middleware.MechanicOnly(), h.Service.CreateService)
		protected.GET("/services/:id", h.Service.GetService)
		protected.PUT("/services/:id/confirm", h.Service.ConfirmService)
		protected.PUT("/services/:id/reject", h.Service.RejectService)
		protected.GET("/services/pending", h.Service.GetPendingServices)
		protected.POST("/services/voice", middleware.MechanicOnly(), h.Service.ProcessVoiceService)
		protected.POST("/services/:id/photos", h.Service.UploadPhotos)

		// Mechanics (public-ish, no auth required for read)
		protected.GET("/mechanics/:id", h.Mechanic.GetMechanic)
		protected.GET("/mechanics/:id/reviews", h.Mechanic.GetMechanicReviews)
		protected.PUT("/mechanics/profile", middleware.MechanicOnly(), h.Mechanic.UpdateMechanicProfile)
		protected.GET("/mechanics/my-services", middleware.MechanicOnly(), h.Mechanic.GetMyServices)

		// Reviews
		protected.POST("/reviews", h.Review.CreateReview)
		protected.GET("/reviews/:id", h.Review.GetReview)

		// Warranty
		protected.POST("/warranty", h.Warranty.CreateClaim)
		protected.GET("/warranty", h.Warranty.GetClaims)
		protected.GET("/warranty/:id", h.Warranty.GetClaim)

		// Search
		protected.GET("/search", h.Search.Search)

		// Notifications
		protected.GET("/notifications", h.Notification.GetNotifications)
		protected.PUT("/notifications/:id/read", h.Notification.MarkAsRead)
		protected.POST("/notifications/fcm-token", h.Notification.RegisterFCMToken)

		// SOS — favqulodda yordam so'rovi
		protected.POST("/sos", h.Sos.CreateRequest)
		protected.GET("/sos", h.Sos.ListMine)

		// Tamirlash so'rovlari — mijoz usta tanlab so'rov yuboradi
		protected.POST("/repair-requests", h.Repair.Create)
		protected.GET("/repair-requests", h.Repair.ListMine)

		// Ustaga yo'naltirilgan so'rovlar (mijoz ma'lumotlari bilan)
		protected.GET("/mechanic/assignments", middleware.MechanicOnly(), h.Assignment.MyAssignments)
	}

	// Mechanics search (public)
	v1.GET("/mechanics", h.Mechanic.GetMechanics)

	// WebSocket — real-time SOS eventlari (token query orqali auth)
	v1.GET("/ws", h.WS.Connect)

	// Admin routes
	admin := v1.Group("/admin")
	admin.Use(middleware.AuthRequired(), middleware.AdminOnly())
	{
		admin.GET("/stats", h.Admin.GetStats)
		admin.GET("/mechanics", h.Admin.ListMechanics)
		admin.POST("/mechanics", h.Admin.CreateMechanic)
		admin.PUT("/mechanics/:id/verify", h.Admin.VerifyMechanic)
		admin.GET("/services", h.Admin.ListServices)
		admin.GET("/users", h.Admin.ListUsers)
		admin.GET("/vehicles", h.Admin.ListVehicles)
		admin.GET("/reviews", h.Admin.ListReviews)
		admin.PUT("/reviews/:id/moderate", h.Admin.ModerateReview)
		admin.GET("/warranty", h.Admin.ListWarrantyClaims)
		admin.PUT("/warranty/:id/resolve", h.Admin.ResolveWarrantyClaim)
		admin.POST("/notifications/broadcast", h.Admin.SendBroadcastNotification)
		admin.GET("/sos", h.Sos.AdminList)
		admin.PUT("/sos/:id/status", h.Sos.AdminUpdateStatus)
		admin.PUT("/sos/:id/assign", h.Sos.AdminAssign)

		// Tamirlash so'rovlari — operator boshqaruvi
		admin.GET("/repair-requests", h.Repair.AdminList)
		admin.PUT("/repair-requests/:id/assign", h.Repair.AdminAssign)
		admin.PUT("/repair-requests/:id/status", h.Repair.AdminUpdateStatus)
	}
}
