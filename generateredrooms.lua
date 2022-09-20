local mod = GreedSpecialRooms
local game = Game()

local PossibleSlots = {
	DoorSlot.LEFT0,
	DoorSlot.UP0,
	DoorSlot.UP1,
	DoorSlot.RIGHT0
}

local SHOP_IDX = 71

function script.copyTable(sourceTab)
	local targetTab = {}
	sourceTab = sourceTab or {}

	if type(sourceTab) ~= "table" then
		error("[ERROR] - cucco_helper.copyTable - invalid argument #1, table expected, got " .. type(sourceTab), 2)
	end

	for i, v in pairs(sourceTab) do
		if type(v) == "table" then
			targetTab[i] = script.copyTable(sourceTab[i])
		else
			targetTab[i] = sourceTab[i]
		end
	end

	return targetTab
end

function mod.GenerateRedRooms(redRoomsRequired)
	local level = game:GetLevel()
	local oldStage = level:GetStage()
	local oldStageType = level:GetStageType()
	local oldChallenge = game.Challenge
	local redRoomsGenerated = {}
	local tempTable = script.copyTable(PossibleSlots)

	game.Challenge = Challenge.CHALLENGE_RED_REDEMPTION
	level:SetStage(7, 0)
	for i = 1, # PossibleSlots do
		local slot = rng:RandomInt(#tempTable+1)
		if game:MakeRedRoomDoor(SHOP_IDX, slot) then
			redRoomsGenerated[#table+1] = slot
			if #redRoomsGenerated == redRoomsRequired then
				break
			end
		end
		table.remove(tempTable, slot)
	end
	game.Challenge = oldChallenge
	level:SetStage(oldStage, oldStageType)

	return redRoomsGenerated
end
