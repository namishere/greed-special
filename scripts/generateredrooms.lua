local mod = GreedSpecialRooms
local game = Game()

local PossibleSlots = {
	DoorSlot.LEFT0,
	DoorSlot.UP0,
	DoorSlot.UP1,
	DoorSlot.RIGHT0
}

local SHOP_IDX = 70

mod.redRoomsGenerated = {}

function mod.GenerateRedRooms(rng)
	mod.lib.debugPrint("GenerateRedRooms")
	mod.lib.debugPrint("redRoomsRequired: "..mod.redRoomsRequired)
	local level = game:GetLevel()
	local oldStage = level:GetStage()
	local oldStageType = level:GetStageType()

	mod.redRoomsGenerated = {}
	local tempTable = mod.lib.copyTable(PossibleSlots)

	level:SetStage(7, 0)
	for i = 1, # PossibleSlots do
		local idx = rng:RandomInt(#tempTable)+1
		mod.lib.debugPrint("idx "..idx)
		local slot = tempTable[idx]
		mod.lib.debugPrint("slot "..slot)
		local result = level:MakeRedRoomDoor(SHOP_IDX, slot)

		mod.lib.debugPrint("success: "..tostring(result))
		if result then
			mod.lib.debugPrint("Generated Red Room at slot "..slot..", now at "..#mod.redRoomsGenerated + 1 .." created")
			mod.redRoomsGenerated[#mod.redRoomsGenerated+1] = slot
			if #mod.redRoomsGenerated == mod.redRoomsRequired then
				break
			end
		end
		table.remove(tempTable, idx)
	end
	level:SetStage(oldStage, oldStageType)
end
