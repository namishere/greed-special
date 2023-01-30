local mod = GreedSpecialRooms
local game = Game()
local rng = mod.rng

mod.redRoomsGenerated = {}

function mod.GenerateRedRooms()
	if mod.redRoomsRequired > 0 then
		mod.lib.debugPrint("GenerateRedRooms: generating "..mod.redRoomsRequired.." rooms")
		local level = game:GetLevel()
		local oldStage = level:GetStage()
		local oldStageType = level:GetStageType()
		level:SetStage(7, 0)

		mod.redRoomsGenerated = {}
		local deadends = mod.lib.GetDeadEnds(level:GetRoomByIdx(mod.enum.SHOP_IDX))
		mod.lib.Shuffle(deadends, rng)

		for i = 1, #deadends do
			local result = level:MakeRedRoomDoor(mod.enum.SHOP_IDX, deadends[i].Slot)
			mod.lib.debugPrint("success: "..tostring(result))
			if result then
				mod.lib.debugPrint("Generated Red Room at slot "..deadends[i].Slot..", now at "..#mod.redRoomsGenerated + 1 .." created")
				mod.redRoomsGenerated[#mod.redRoomsGenerated+1] = deadends[i].Slot
				if #mod.redRoomsGenerated == mod.redRoomsRequired then
					break
				end
			end
		end
		level:SetStage(oldStage, oldStageType)
	else
		mod.lib.debugPrint("GenerateRedRooms: nothing to generate")
	end
end
