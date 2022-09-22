local mod = GreedSpecialRooms
local game = Game()
local rng = mod.rng

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
		if v > RoomType.ROOM_NULL and GetRoomData(stringToType[i], false) then
			mod.redRoomsRequired = mod.redRoomsRequired + 1
		end
	end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
	if game:GetLevel():GetCurrentRoomDesc().Data.Type == RoomType.ROOM_PLANETARIUM
	and game:GetLevel():GetCurrentRoomDesc().GridIndex > 0 then --we enter a planetarium in the process of spawning one
		mod.lib.debugPrint("we entered a planetarium")
		--mod.data.run.visitedPlanetarium = true
	end
end)
