local mod = GreedSpecialRooms
local game = Game()

local CURSE_IDX = 83

local ShopSlotToRedRoom = {
	[DoorSlot.LEFT0] = 69,
	[DoorSlot.UP0] = 57,
	[DoorSlot.UP1] = 58,
	[DoorSlot.RIGHT0] = 72
}

mod.roomsupdated = {}

function mod.ReplaceRoomData(rng)
	mod.lib.debugPrint("ReplaceRoomData")
	local level = game:GetLevel()
	local curseRoom = level:GetRoomByIdx(CURSE_IDX, 0)
	local door = mod.startroom:GetDoor(DoorSlot.LEFT0)

	mod.roomsupdated = {}

	rng:SetSeed(level:GetDungeonPlacementSeed()+1,35)

	if mod.roomdata.curse ~= nil then
		curseRoom.Data = mod.roomdata.curse
		curseRoom.Flags = 0

		print(dump(mod.SpecialRoom[mod.roomsrequested.curse]))
		door.TargetRoomType = mod.roomsrequested.curse
		door:SetVariant(mod.SpecialRoom[mod.roomsrequested.curse].variant)
		door:SetRoomTypes(RoomType.ROOM_DEFAULT, mod.roomsrequested.curse)
		door:Update()

		if MinimapAPI then
			MinimapAPI:GetRoomByIdx(CURSE_IDX, 0):UpdateType()
		end

		mod.roomsupdated[#mod.roomsupdated] = CURSE_IDX
		mod.roomsupdated.curse = nil
	end
	if #mod.redRoomsGenerated > 0 then
		local roomCount = #mod.redRoomsGenerated
		mod.lib.debugPrint("Red Room Loop")
		mod.lib.debugPrint("roomCount: "..roomCount)

		for i,v in pairs(mod.roomdata.redRoom) do
			print(i.." "..dump(v))
			local slotIdx = rng:RandomInt(#mod.redRoomsGenerated+1)
			mod.lib.debugPrint("slotIdx: "..slotIdx.." ShopSlotToRedRoom: "..ShopSlotToRedRoom[slotIdx])

			local room = level:GetRoomByIdx(ShopSlotToRedRoom[slotIdx], 0)

			room.Data = mod.roomdata.redRoom[i]
			room.Flags = 0

			mod.lib.debugPrint("#redRoomsGenerated pre-removal: "..#mod.redRoomsGenerated)

			table.remove(mod.redRoomsGenerated, slotIdx+1)
			mod.roomdata.redRoom[i] = nil

			mod.roomsupdated[#mod.roomsupdated] = slotIdx

			mod.lib.debugPrint("#redRoomsGenerated post-removal: "..#mod.redRoomsGenerated)
			if #mod.redRoomsGenerated == 0 then
				mod.roomdata = {}
				return false
			end
		end
		--[[
		for i = 1, roomCount do
			local slotIdx = rng:RandomInt(#mod.redRoomsGenerated+1)
			local dataIdx = rng:RandomInt(#mod.roomdata.redRoom+1)


			mod.lib.debugPrint("slotIdx: "..slotIdx.." dataIdx: "..dataIdx.." ShopSlotToRedRoom: "..ShopSlotToRedRoom[slotIdx])
			local room = level:GetRoomByIdx(ShopSlotToRedRoom[slotIdx], 0)

			room.Data = mod.roomdata.redRoom[dataIdx]
			room.Flags = 0

			table.remove(mod.redRoomsGenerated, slotIdx+1)
			table.remove(mod.roomdata.redRoom, dataIdx+1)

			mod.roomsupdated[#mod.roomsupdated] = slotIdx

			if #mod.redRoomsGenerated == 0 then
				return false
			end
		end
		]]--
	end

	return true
end

