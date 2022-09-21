local mod = GreedSpecialRooms
local game = Game()

mod.roomdata = {}

local stringToType = {
	["planetarium"] = RoomType.ROOM_PLANETARIUM,
	["cainArcade"] = mod.enum.CAIN_ARCADE
}

local function GetRoomData(key, curse)
	mod.lib.debugPrint("GetRoomData.. key: "..key.." curse: "..tostring(curse))
	local level = game:GetLevel()
	Isaac.ExecuteCommand("goto s." .. mod.SpecialRoom[key].string .. "." .. mod.GetRoomID(key, rng))
	local gotor = level:GetRoomByIdx(-3,0)
	if gotor.Data then
		if curse then
			mod.roomdata.curse = gotor.Data
		else
			mod.lib.debugPrint("Adding redRoom data of key "..key)
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

	if mod.roomsrequested.curse > RoomType.ROOM_NULL then
		GetRoomData(mod.roomsrequested.curse, true)
	end
	mod.redRoomsRequired = 0
	for i,v in pairs(mod.roomsrequested.redRoom) do
		print(i.." "..tostring(v))
		print(stringToType[i])
		if stringToType[i] > RoomType.ROOM_NULL and GetRoomData(stringToType[i], false) then
			mod.redRoomsRequired = mod.redRoomsRequired + 1
		end
	end
end
