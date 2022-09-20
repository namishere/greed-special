local mod = GreedSpecialRooms

mod.roomdata = {}

local function GetRoomData(key)
	Isaac.ExecuteCommand("goto s." .. SpecialRoom[key].string .. "." .. mod.GetRoomID(key, rng))
	local gotor = level:GetRoomByIdx(-3,0)
	if gotor.Data then
		mod.roomdata[key] = gotor.Data
		return true
	end
	return false
end

function mod.GetCustomRoomData()
	local redRoomsRequired = 0
	for _,v in pairs(mod.roomrequests) do
		if v > RoomType.ROOM_NULL and GetRoomData(v) then
			redRoomsRequired = redRoomsRequired + 1
		end
	end
	if mod.roomrequests[curseReplacement] > 0 then
		redRoomsRequired = redRoomsRequired -1
	end
	return redRoomsRequired
end
