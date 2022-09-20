local mod = GreedSpecialRooms
local game = Game()

local PossibleSlots = {
	DoorSlot.LEFT0,
	DoorSlot.UP0,
	DoorSlot.UP1,
	DoorSlot.RIGHT0
}

local SHOP_IDX = 71

mod.redRoomsGenerated = {}

function mod.GenerateRedRooms(rng)
	local level = game:GetLevel()
	local oldStage = level:GetStage()
	local oldStageType = level:GetStageType()
	local oldChallenge = game.Challenge

	mod.redRoomsGenerated = {}
	local tempTable = mod.lib.copyTable(PossibleSlots)

	game.Challenge = Challenge.CHALLENGE_RED_REDEMPTION
	level:SetStage(7, 0)
	for i = 1, # PossibleSlots do
		local slot = rng:RandomInt(#tempTable+1)
		if game:MakeRedRoomDoor(SHOP_IDX, slot) then
			redRoomsGenerated[#table+1] = slot
			if #redRoomsGenerated == mod.redRoomsRequired then
				break
			end
		end
		table.remove(tempTable, slot)
	end
	game.Challenge = oldChallenge
	level:SetStage(oldStage, oldStageType)
end
