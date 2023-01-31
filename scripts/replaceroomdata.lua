local mod = GreedSpecialRooms
local game = Game()
local rng = mod.rng

mod.roomsupdated = {}

function mod.ReplaceRoomData()
	mod.lib.debugPrint("ReplaceRoomData()")
	local level = game:GetLevel()
	local curseRoom = level:GetRoomByIdx(mod.enum.CURSE_IDX, 0)
	local curseDoor = mod.startroom:GetDoor(DoorSlot.LEFT0)

	mod.roomsupdated = {}

	if mod.roomdata.curse ~= nil then
		mod.lib.debugPrint("ReplaceRoomData(): Curse Room")
		curseRoom.Data = mod.roomdata.curse
		curseRoom.Flags = 0

		mod.lib.debugPrint(dump(mod.SpecialRoom[mod.roomsrequested.curse]))
		curseDoor.TargetRoomType = mod.roomsrequested.curse
		curseDoor:SetVariant(mod.SpecialRoom[mod.roomsrequested.curse].variant)
		curseDoor:SetRoomTypes(RoomType.ROOM_DEFAULT, mod.roomsrequested.curse)
		curseDoor:Update()

		if MinimapAPI then
			MinimapAPI:GetRoomByIdx(mod.enum.CURSE_IDX, 0):SyncRoomDescriptor()
		end

		mod.roomsupdated[#mod.roomsupdated+1] = mod.enum.CURSE_IDX
		mod.roomdata.curse = nil
	end
	mod.lib.debugPrint("ReplaceRoomData(): Red Room Loop")
	for k, v in pairs(mod.redRoomsGenerated) do
		mod.lib.debugPrint("k = "..dump(k))
		mod.lib.debugPrint("v = "..dump(v))
		if #v > 0 then
			mod.lib.debugPrint("roomCount: "..#v)
			--mod.lib.debugPrint(dump(mod.redRoomsGenerated))

			for i,j in pairs(v) do
				mod.lib.debugPrint("i = "..dump(i))
				mod.lib.debugPrint("j = "..dump(j))
				if #v == 0 then
					--mod.roomdata = {}
					mod.lib.debugPrint("ReplaceRoomData(): ran out of red rooms for room "..k.."!")
					break
				end

				--mod.lib.debugPrint(i.." "..dump(j))

				mod.lib.debugPrint("ReplaceRoomData(): slot: "..j.Slot.." index: "..j.GridIndex)

				local room = level:GetRoomByIdx(j.GridIndex, 0)

				assert(room.Data ~= nil, "ReplaceRoomData(): huh??? no room data at idx "..j.GridIndex.."???")
				assert(mod.roomdata.redRoom[k][i] ~= nil, "ReplaceRoomData(): you fucked it!")
				room.Data = mod.roomdata.redRoom[k][i].Data
				room.Flags = 0

				--mod.lib.debugPrint("#redRoomsGenerated pre-removal: "..#mod.redRoomsGenerated)
				mod.roomsupdated[#mod.roomsupdated+1] = j.GridIndex

				--mod.lib.debugPrint("#redRoomsGenerated post-removal: "..#mod.redRoomsGenerated)
			end
		end
	end
	mod.lib.debugPrint("ReplaceRoomData(): finished")
end

