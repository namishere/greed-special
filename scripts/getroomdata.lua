local mod = GreedSpecialRooms
local game = Game()
local rng = mod.rng

mod.roomdata = {}
mod.dotransition = false

local stringToType = {
	["planetarium"] = RoomType.ROOM_PLANETARIUM,
	["cainArcade"] = mod.enum.CAIN_ARCADE,
	["extraCurse"] = mod.enum.VOODOO_CURSE
}

local function GetRoomData(key)
	mod.lib.debugPrint("GetRoomData.. key: "..key)
	local level = game:GetLevel()
	Isaac.ExecuteCommand("goto s." .. mod.SpecialRoom[key].string .. "." .. mod.GetRoomID(key, rng))
	mod.dotransition = true -- we are bound to it the moment we leave the starting room
	local gotor = level:GetRoomByIdx(-3,0)
	if gotor.Data then
	--[[
		if curse then
			mod.roomdata.curse = gotor.Data
		else
			mod.lib.debugPrint("Adding redRoom data of key "..key)
			mod.roomdata.redRoom[key] = gotor.Data
		end
	]]
		mod.lib.debugPrint("returning data")
		return gotor.Data
	end
	return nil
end

function mod.GetCustomRoomData()
	mod.roomdata = {
		curse = nil,
		redRoom = {
			[mod.enum.SHOP_IDX]= {},
			[mod.enum.EXIT_IDX]= {}
		}
	}

	if mod.roomsrequested.curse > RoomType.ROOM_NULL then
		mod.roomdata.curse = GetRoomData(mod.roomsrequested.curse)
	end

	print(mod.enum.SHOP_IDX)
	mod.redRoomsRequired = 0
	for i,v in pairs(mod.roomsrequested.redRoom[mod.enum.SHOP_IDX]) do
		local rType = stringToType[i]
	--[[
		mod.lib.debugPrint(i.." = " ..tostring(v))
		mod.lib.debugPrint(rType)
	]]--
		if v > RoomType.ROOM_NULL then
			local data = GetRoomData(rType)
			if data ~= nil then
				mod.roomdata.redRoom[mod.enum.SHOP_IDX][rType] = data
				mod.redRoomsRequired = mod.redRoomsRequired + 1
			end
		end
	end
end
