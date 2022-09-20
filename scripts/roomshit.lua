local mod = GreedSpecialRooms

local roomTable = {}
--include("the-everything-function-rev1")

mod.roomInit = false

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

function mod.InitRooms()
	roomTable  = {}
	mod.AddSpecialRooms(mod.enum.rooms)

	for idx,v in pairs(roomTable) do
		--print(idx)
		roomTable[idx].sampler = mod.lib.alias_table:new(roomTable[idx].weights)
		--print(dump(roomTable[idx].sampler))
	end
end
