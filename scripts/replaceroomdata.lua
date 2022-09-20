local mod = GreedSpecialRooms

local CURSE_IDX = 83

local ShopSlotToRedRoom = {
	[DoorSlot.LEFT0] = 69,
	[DoorSlot.UP0] = 57,
	[DoorSlot.UP1] = 58,
	[DoorSlot.RIGHT0] = 72
}

mod.roomsupdated = {}

function mod.ReplaceRoomData(rng)
	local level = game:GetLevel()
	local curseRoom = level:GetRoomByIdx(CURSE_IDX, 0)
	local door = mod.startroom:GetDoor(DoorSlot.LEFT0)

	mod.roomsupdated = {}

	rng:SetSeed(level:GetDungeonPlacementSeed()+1,35)

	if mod.roomdata.curse ~= nil then
		curseRoom.Data = mod.roomdata.curse
		curseRoom.Flags = 0

		door.TargetRoomType = mod.roomsrequested.curse
		door:SetVariant(SpecialRoom[mod.roomsrequested.curse].variant)
		door:SetRoomTypes(RoomType.ROOM_DEFAULT, mod.roomsrequested.curse)
		door:Update()

		if MinimapAPI then
			MinimapAPI:GetRoomByIdx(CURSE_IDX, 0):UpdateType()
		end

		mod.roomsupdated[#mod.roomsupdated] = CURSE_IDX
	end

	local roomCount = #mod.redRoomsGenerated
	for i = 1, roomCount do
		local slotIdx = rng:RandomInt(#mod.redRoomsGenerated+1)
		local dataIdx = rng:RandomInt(#mod.roomdata.redRoom+1]

		local room = level:GetRoomByIdx(ShopSlotToRedRoom[roomIdx])

		room.Data = mod.roomdata.redRoom[dataIdx]
		room.Flags = 0

		table.remove(mod.redRoomsGenerated, slotIdx)
		table.remove(mod.roomdata.redRoom, dataIdx)

		mod.roomsupdated[#mod.roomsupdated] = slotIdx

		if #mod.redRoomsGenerated == 0 then
			return false
		end
	end

	return true
end

