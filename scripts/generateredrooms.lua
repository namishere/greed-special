local mod = GreedSpecialRooms
local game = Game()
local rng = mod.rng

mod.redRoomsGenerated = {}

function mod.GenerateRedRooms()
	mod.lib.debugPrint("GenerateRedRooms()")
	mod.redRoomsGenerated = {}
	if mod.redRoomsRequired ~= nil then
		local level = game:GetLevel()
		local oldStage = level:GetStage()
		local oldStageType = level:GetStageType()
		level:SetStage(7, 0)

		for k, v in pairs(mod.redRoomsRequired) do
			mod.lib.debugPrint("GenerateRedRooms(): Start room loop")
			mod.lib.debugPrint("k = " ..dump(k))
			mod.lib.debugPrint("v = " ..dump(v))

			if v > 0 then
				mod.lib.debugPrint("GenerateRedRooms(): need "..mod.redRoomsRequired[k].." exits for room "..k)
				local deadends = mod.lib.GetDeadEnds(level:GetRoomByIdx(k))
				if deadends then
					mod.lib.debugPrint("GenerateRedRooms(): "..#deadends.." dead ends found in room "..k)
					mod.lib.Shuffle(deadends, rng)
					mod.lib.debugPrint("GenerateRedRooms(): "..#deadends.." dead ends after shuffle??")

					for i = 1, mod.redRoomsRequired[k] do
						mod.lib.debugPrint("GenerateRedRooms(): attempting to make room "..deadends[i].GridIndex.." at slot "..deadends[i].Slot.." in room "..k)
						local result = level:MakeRedRoomDoor(k, deadends[i].Slot)
						mod.lib.debugPrint("GenerateRedRooms(): success: "..dump(result))
						if result then
							mod.lib.debugPrint("GenerateRedRooms(): Generated Red Room "..deadends[i].GridIndex.." at slot "..deadends[i].Slot.." in room "..k)
							if mod.redRoomsGenerated[k] == nil then
								mod.redRoomsGenerated[k] = { deadends[i] }
							else
								table.insert(mod.redRoomsGenerated[k], deadends[i])
							end

							mod.lib.debugPrint("GenerateRedRooms(): mod.redRoomsGenerated[k]: "..dump(mod.redRoomsGenerated[k]))
							mod.lib.debugPrint("GenerateRedRooms(): "..#mod.redRoomsGenerated[k].. " vs "..mod.redRoomsRequired[k])
							if #mod.redRoomsGenerated[k] == #deadends then
								mod.lib.debugPrint("GenerateRedRooms(): ran out of dead ends for room "..k)
								break
							end
						end
					end
				else
					mod.lib.debugPrint("GenerateRedRooms(): no dead ends in room "..k)
				end
			else
				mod.lib.debugPrint("GenerateRedRooms(): nothing to generate for room "..k)
			end
			mod.lib.debugPrint("GenerateRedRooms(): mod.redRoomsGenerated: "..dump(mod.redRoomsGenerated))
		end
		level:SetStage(oldStage, oldStageType)
	else
		mod.lib.debugPrint("GenerateRedRooms(): no red rooms required")
	end
end
