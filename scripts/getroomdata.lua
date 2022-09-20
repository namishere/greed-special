local mod = GreedSpecialRooms

mod.roomdata {}

local function GetRoomData(key, curse)
	Isaac.ExecuteCommand("goto s." .. SpecialRoom[key].string .. "." .. mod.GetRoomID(key, rng))
	local gotor = level:GetRoomByIdx(-3,0)
	if gotor.Data then
		if curse then
			mod.roomdata.curse = gotor.Data
		else
			mod.roomdata.redRoom[key] = gotor.Data
		end
		return true
	end
	return false
end

function mod.GetCustomRoomData()
	mod.roomdata = {
		curse = nil,
		redRoom = {}
	}

	if mod.roomsrequested[curseReplacement] > RoomType.ROOM_NULL then
		GetRoomData(mod.roomsrequested[curseReplacement], true)
	end
	mod.redRoomsRequired = 0
	for _,v in pairs(mod.roomsrequested.redRoom) do
		if v > RoomType.ROOM_NULL and GetRoomData(v, false) then
			mod.redRoomsRequired = mod.redRoomsRequired + 1
		end
	end
end
