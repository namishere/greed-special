local mod = GreedSpecialRooms

local roomTable = {}
--include("the-everything-function-rev1")

local baseRooms = include("scripts.enums.rooms")
local alias_table = include("scripts.libs.alias")
mod.roomInit = false

--Exported function
function mod.AddSpecialRooms(r)
	for idx,v in pairs(r) do
		mod.lib.debugPrint(dump(r))
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

function mod.InitRooms()
	roomTable  = {}
	mod.AddSpecialRooms(baseRooms)

	for idx,v in pairs(roomTable) do
		--print(idx)
		roomTable[idx].sampler = alias_table:new(roomTable[idx].weights)
		--print(dump(roomTable[idx].sampler))
	end
end
