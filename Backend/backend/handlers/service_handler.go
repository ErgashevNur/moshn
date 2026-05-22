package handlers

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"moshn/backend/models"
	"moshn/backend/services"
	"moshn/backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/gorm"
)

type ServiceHandler struct {
	svc *services.ServiceRecordService
	db  *gorm.DB
}

func NewServiceHandler(svc *services.ServiceRecordService, db *gorm.DB) *ServiceHandler {
	return &ServiceHandler{svc: svc, db: db}
}

func (h *ServiceHandler) CreateService(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	var input services.CreateServiceInput
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	record, err := h.svc.CreateServiceRecord(userID, input)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Created(c, record)
}

func (h *ServiceHandler) GetService(c *gin.Context) {
	id, _ := uuid.Parse(c.Param("id"))
	record, err := h.svc.GetServiceRecord(id)
	if err != nil {
		utils.NotFound(c, err.Error())
		return
	}
	utils.Success(c, record)
}

func (h *ServiceHandler) ConfirmService(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	id, _ := uuid.Parse(c.Param("id"))

	record, err := h.svc.ConfirmRecord(id, userID)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, record)
}

func (h *ServiceHandler) RejectService(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	id, _ := uuid.Parse(c.Param("id"))

	var input struct {
		Reason string `json:"reason" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		utils.BadRequest(c, err.Error())
		return
	}

	record, err := h.svc.RejectRecord(id, userID, input.Reason)
	if err != nil {
		utils.BadRequest(c, err.Error())
		return
	}
	utils.Success(c, record)
}

func (h *ServiceHandler) GetPendingServices(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	records, err := h.svc.GetPendingRecords(userID)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, records)
}

func (h *ServiceHandler) ProcessVoiceService(c *gin.Context) {
	file, _, err := c.Request.FormFile("audio")
	if err != nil {
		utils.BadRequest(c, "Audio fayl topilmadi")
		return
	}
	defer file.Close()

	audioData, err := io.ReadAll(file)
	if err != nil {
		utils.InternalError(c, "Audio o'qishda xato")
		return
	}

	parsed, err := h.svc.ProcessVoice(audioData)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	utils.Success(c, parsed)
}

func (h *ServiceHandler) UploadPhotos(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))
	id, _ := uuid.Parse(c.Param("id"))

	var record models.ServiceRecord
	if err := h.db.Where("id = ?", id).First(&record).Error; err != nil {
		utils.NotFound(c, "Yozuv topilmadi")
		return
	}

	var mechanic models.Mechanic
	if h.db.Where("user_id = ?", userID).First(&mechanic).Error != nil {
		utils.Forbidden(c, "Faqat usta rasm yuklashi mumkin")
		return
	}
	if mechanic.ID != record.MechanicID {
		utils.Forbidden(c, "Bu yozuvga ruxsat yo'q")
		return
	}

	photoType := c.DefaultQuery("type", "before")
	form, _ := c.MultipartForm()
	files := form.File["photos"]

	var urls []string
	for _, fh := range files {
		f, _ := fh.Open()
		ext := filepath.Ext(fh.Filename)
		fname := fmt.Sprintf("services/%s/%s%s", id.String(), uuid.New().String(), ext)
		fullPath := filepath.Join("/app/uploads", fname)
		os.MkdirAll(filepath.Dir(fullPath), 0755)
		dst, _ := os.Create(fullPath)
		io.Copy(dst, f)
		dst.Close()
		f.Close()
		urls = append(urls, "/uploads/"+fname)
	}

	if photoType == "before" {
		existing := []string(record.PhotoBefore)
		existing = append(existing, urls...)
		h.db.Model(&record).Update("photo_before", pq.StringArray(existing))
	} else {
		existing := []string(record.PhotoAfter)
		existing = append(existing, urls...)
		h.db.Model(&record).Update("photo_after", pq.StringArray(existing))
	}

	utils.Success(c, gin.H{"urls": urls})
}
