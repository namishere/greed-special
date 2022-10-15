local mod = GreedSpecialRooms
local game = Game()
local rng = mod.rng

local CURSE_IDX = 83

local ShopSlotToRedRoom = {
	[DoorSlot.LEFT0] = 69,
	[DoorSlot.UP0] = 57,
	[DoorSlot.UP1] = 58,
	[DoorSlot.RIGHT0] = 72
}

mod.roomsupdated = {}

function mod.ReplaceRoomData()
	mod.lib.debugPrint("ReplaceRoomData start")
	local level = game:GetLevel()
	local curseRoom = level:GetRoomByIdx(CURSE_IDX, 0)
	local door = mod.startroom:GetDoor(DoorSlot.LEFT0)

	mod.roomsupdated = {}

	if mod.roomdata.curse ~= nil then
		mod.lib.debugPrint("Curse Room")
		curseRoom.Data = mod.roomdata.curse
		curseRoom.Flags = 0

		mod.lib.debugPrint(dump(mod.SpecialRoom[mod.roomsrequested.curse]))
		door.TargetRoomType = mod.roomsrequested.curse
		door:SetVariant(mod.SpecialRoom[mod.roomsrequested.curse].variant)
		door:SetRoomTypes(RoomType.ROOM_DEFAULT, mod.roomsrequested.curse)
		door:Update()

		if MinimapAPI then
			MinimapAPI:GetRoomByIdx(CURSE_IDX, 0):UpdateType()
		end

		mod.roomsupdated[#mod.roomsupdated] = CURSE_IDX
		mod.roomdata.curse = nil
	end
	if #mod.redRoomsGenerated > 0 then
		mod.lib.debugPrint("Red Room Loop")
		mod.lib.debugPrint("roomCount: "..#mod.redRoomsGenerated)
		--mod.lib.debugPrint(dump(mod.redRoomsGenerated))

		for i,v in pairs(mod.roomdata.redRoom) do
			mod.lib.debugPrint(i.." "..dump(v))
			local idx = rng:RandomInt(#mod.redRoomsGenerated)+1
			local slotIdx = mod.redRoomsGenerated[idx]
			mod.lib.debugPrint(idx)
			mod.lib.debugPrint(slotIdx)
			mod.lib.debugPrint("slotIdx: "..slotIdx.." ShopSlotToRedRoom: "..ShopSlotToRedRoom[slotIdx])

			local room = level:GetRoomByIdx(ShopSlotToRedRoom[slotIdx], 0)

			assert(room.Data ~= nil, "huh??? no room data at idx "..ShopSlotToRedRoom[slotIdx].."???")
			room.Data = mod.roomdata.redRoom[i]
			room.Flags = 0

			--mod.lib.debugPrint("#redRoomsGenerated pre-removal: "..#mod.redRoomsGenerated)

			table.remove(mod.redRoomsGenerated, idx)
			mod.roomdata.redRoom[i] = nil

			mod.roomsupdated[#mod.roomsupdated] = ShopSlotToRedRoom[slotIdx]

			--mod.lib.debugPrint("#redRoomsGenerated post-removal: "..#mod.redRoomsGenerated)
			if #mod.redRoomsGenerated == 0 then
				mod.roomdata = {}
				mod.lib.debugPrint("ReplaceRoomData: ran out of red rooms!")
				return false
			end
		end
	end
	mod.lib.debugPrint("ReplaceRoomData finished succesfully")

	return true
end

