package handlers

import (
	"moshn/backend/services"
	"moshn/backend/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// AssignmentHandler — kirgan ustaga yo'naltirilgan SOS va tamirlash so'rovlarini
// mijoz ma'lumotlari bilan birga qaytaradi.
type AssignmentHandler struct {
	sos      *services.SosService
	repair   *services.RepairService
	mechanic *services.MechanicService
}

func NewAssignmentHandler(sos *services.SosService, repair *services.RepairService, mechanic *services.MechanicService) *AssignmentHandler {
	return &AssignmentHandler{sos: sos, repair: repair, mechanic: mechanic}
}

// MyAssignments — GET /mechanic/assignments
func (h *AssignmentHandler) MyAssignments(c *gin.Context) {
	userIDStr, _ := c.Get("user_id")
	userID, _ := uuid.Parse(userIDStr.(string))

	mech, err := h.mechanic.GetByUserID(userID)
	if err != nil {
		utils.NotFound(c, "Usta profili topilmadi")
		return
	}

	sosList, err := h.sos.ListForMechanic(mech.ID)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}
	repairList, err := h.repair.ListForMechanic(mech.ID)
	if err != nil {
		utils.InternalError(c, err.Error())
		return
	}

	utils.Success(c, gin.H{"sos": sosList, "repairs": repairList})
}
