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
	mod.lib.debugPrint("GetRoomData(): key is  "..key)
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
		mod.lib.debugPrint("GetRoomData(): returning data")
		return gotor.Data
	end
	return nil
end

function mod.GetCustomRoomData()
	mod.lib.debugPrint("GetCustomRoomData()")
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

	local redroom = false
	mod.redRoomsRequired = {
		[mod.enum.SHOP_IDX]= 0,
		[mod.enum.EXIT_IDX]= 0
	}

	mod.lib.debugPrint("GetCustomRoomData(): Start red room loop")
	for i,v in pairs(mod.roomsrequested.redRoom) do

		mod.lib.debugPrint("mod.roomsrequested.redRoom.i = "..dump(i))
		mod.lib.debugPrint("mod.roomsrequested.redRoom.v = "..dump(v))

		for key, rtype in pairs(v) do

			mod.lib.debugPrint("GetCustomRoomData(): key = "..dump(key))
			mod.lib.debugPrint("GetCustomRoomData(): rType = "..dump(rtype))

			if rtype > RoomType.ROOM_NULL then
				local data = GetRoomData(rtype)
				if data ~= nil then
					redroom = true
					mod.lib.debugPrint("GetCustomRoomData(): mod.redRoomsRequired[i] = "..mod.redRoomsRequired[i])
					mod.roomdata.redRoom[i][#mod.roomdata.redRoom[i]+1] = { Data = data, rType = rtype }
					mod.redRoomsRequired[i] = mod.redRoomsRequired[i] + 1
					mod.lib.debugPrint("GetCustomRoomData(): mod.redRoomsRequired[i] is now "..mod.redRoomsRequired[i])
				end
			end
		end
	end

	if not redroom then
		mod.redRoomsRequired = nil
	end
end
