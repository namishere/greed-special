MainMod = RegisterMod("Weighted Rooms", 1)
local mod = MainMod
local alias_table = include("alias")

--internal
local roomTable  = {
	[RoomType.ROOM_DEFAULT] = {
		ids = {},
		weights = {}
	}
}

--Exported function
function mod.AddSpecialRooms(r)
	for idx,v in pairs(r) do
		roomTable[idx] = {
			ids = {},
			weights = {}
		}

		for i = 1, #v.rooms do
			roomTable[idx].ids[i] = v.rooms[i].id
			roomTable[idx].weights[i] = v.rooms[i].weight
		end

	--[[
		print("1: "..dump(roomTable))
		print("2: "..dump(roomTable[idx].ids))
		print("3: "..dump(roomTable[idx].weights))
	]]--
	end
end

--Use case

--Example list of rooms to be added by mod
--id: room's id as defined by the stb
--weight: likelihood of that room being chosen
local ExternalModRooms = {
	[RoomType.ROOM_TREASURE] = {
		rooms = {
			{id = 1, weight = 3},
			{id = 2, weight = 1},
			{id = 3, weight = .75},
			{id = 4, weight = .5},
			{id = 5, weight = .33},
			{id = 6, weight = .1}
		}
	}
}

--Called by the external mod before POST_GAME_STARTED
MainMod.AddSpecialRooms(ExternalModRooms)

--Demo, called by main mod
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, isContinue)
	local rng = RNG()
	rng:SetSeed(Game():GetLevel():GetDungeonPlacementSeed(), 35)
	local treasureSample = alias_table:new(roomTable[RoomType.ROOM_TREASURE].weights) -- assign weights for 1, 2, 3, 4, 5, 6 etc.

	--print selected room ids
	print(roomTable[RoomType.ROOM_TREASURE].ids[treasureSample(rng)])
	print(roomTable[RoomType.ROOM_TREASURE].ids[treasureSample(rng)])
	print(roomTable[RoomType.ROOM_TREASURE].ids[treasureSample(rng)])
	print(roomTable[RoomType.ROOM_TREASURE].ids[treasureSample(rng)])
	print(roomTable[RoomType.ROOM_TREASURE].ids[treasureSample(rng)])
end)
