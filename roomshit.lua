local mod = GreedSpecialRooms
local alias_table = include("alias")

local rooms = include("rooms")
local roomTable = {}
include("the-everything-function-rev1")

mod.init = false



--Exported function
function mod.AddSpecialRooms(r)
	for idx,v in pairs(r) do
		roomTable[idx] = {
			ids = {},
			weights = {},
			sampler = nil
		}

		for i = 1, #v do
			roomTable[idx].ids[i] = v[i].id
			roomTable[idx].weights[i] = v[i].weight
		end

		--[[
		print("1: "..dump(roomTable))
		print("2: "..dump(roomTable[idx].ids))
		print("3: "..dump(roomTable[idx].weights))
		]]--

	end
end

function mod.GetRoomID(rType, rng)
	return roomTable[rType].ids[roomTable[rType].sampler(rng)]
end

--[[
--Use case

--Example list of rooms to be added by mod
--id: room's id as defined by the stb
--weight: likelihood of that room being chosen

local ExternalModRooms = {
	[RoomType.ROOM_TREASURE] = {
		{id = 1, weight = 3},
		{id = 2, weight = 1},
		{id = 3, weight = .75},
		{id = 4, weight = .5},
		{id = 5, weight = .33},
		{id = 6, weight = .1}
	}
}

--Called by the external mod before POST_GAME_STARTED
]]--

--Demo, called by main mod
function mod.InitRooms()
	if not mod.init then
		roomTable  = {}
		mod.AddSpecialRooms(rooms)

		for idx,v in pairs(roomTable) do
			--print(idx)
			roomTable[idx].sampler = alias_table:new(roomTable[idx].weights)
			--print(dump(roomTable[idx].sampler))
		end
		mod.init = true
	end

	--[[
	local rng = RNG()
	rng:SetSeed(Game():GetLevel():GetDungeonPlacementSeed(), 35)
	--print(roomTable[RoomType.ROOM_TREASURE].ids[roomTable[RoomType.ROOM_TREASURE].sampler(rng)])

	print(mod.GetRoomID(roomTable, RoomType.ROOM_ARCADE, rng))



	local treasureSample = alias_table:new(roomTable[RoomType.ROOM_TREASURE].weights) -- assign weights for 1, 2, 3, 4, 5, 6 etc.

	--print selected room ids
	print(roomTable[RoomType.ROOM_TREASURE].ids[treasureSample(rng)])
	print(roomTable[RoomType.ROOM_TREASURE].ids[treasureSample(rng)])
	print(roomTable[RoomType.ROOM_TREASURE].ids[treasureSample(rng)])
	print(roomTable[RoomType.ROOM_TREASURE].ids[treasureSample(rng)])
	print(roomTable[RoomType.ROOM_TREASURE].ids[treasureSample(rng)])
	]]--
end
