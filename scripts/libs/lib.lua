local mod = GreedSpecialRooms
local game = Game()
mod.lib = {}

--mod.lib.alias_table = include("alias")

-- Debugging
function mod.lib.debugPrint(string)
	if mod.debug and (type(string) == "string") then
		print(string)
		Isaac.DebugString("SPECIALGREED: " .. string)
	end
end

-- Tables
function mod.lib.copyTable(sourceTab)
	local targetTab = {}
	sourceTab = sourceTab or {}

	if type(sourceTab) ~= "table" then
		error("[ERROR] - lib.copyTable - invalid argument #1, table expected, got " .. type(sourceTab), 2)
	end

	for i, v in pairs(sourceTab) do
		if type(v) == "table" then
			targetTab[i] = script.copyTable(sourceTab[i])
		else
			targetTab[i] = sourceTab[i]
		end
	end

	return targetTab
end

function mod.lib.Shuffle(tbl, rng)
	for i = #tbl, 2, -1 do
		local j = rng:RandomInt(1, i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
end

-- For save validation
function mod.lib.ValidateBool(var, default)
	if var ~= nil then return var end
	return default
end

---- scheduling functions utils
local function runUpdates(tab) --This is from Fiend Folio
	for i = #tab, 1, -1 do
		local f = tab[i]
		f.Delay = f.Delay - 1
		if f.Delay <= 0 then
			f.Func()
			table.remove(tab, i)
		end
	end
end

mod.delayedFuncs = {}
function mod.lib.scheduleForUpdate(foo, delay, callback)
	callback = callback or ModCallbacks.MC_POST_UPDATE

	if not mod.delayedFuncs[callback] then
		mod.delayedFuncs[callback] = {}
		mod:AddCallback(callback, function()
			runUpdates(mod.delayedFuncs[callback])
		end)
	end

	table.insert(mod.delayedFuncs[callback], { Func = foo, Delay = delay })
end

-- Level gen
local function IsDeadEnd(roomidx, shape)
	local level = game:GetLevel()
	shape = shape or RoomShape.ROOMSHAPE_1x1
	local deadend = false
	local adjindex = mod.adjindexes[shape]
	local adjrooms = 0
	for i, entry in pairs(adjindex) do
		local oob = false
		for j, idx in pairs(mod.borderrooms[i]) do
			if idx == roomidx then
				oob = true
			end
		end
		if level:GetRoomByIdx(roomidx+entry).GridIndex ~= -1 and not oob then
			adjrooms = adjrooms+1
		end
	end
	if adjrooms == 1 then
		deadend = true
	end
	return deadend
end

function mod.lib.GetDeadEnds(roomdesc)
	local level = game:GetLevel()
	local roomidx = roomdesc.SafeGridIndex
	local shape = roomdesc.Data.Shape
	local adjindex = mod.adjindexes[shape]
	local deadends = {}
	for i, entry in pairs(adjindex) do
		if level:GetRoomByIdx(roomidx).Data then
			local oob = false
			for j, idx in pairs(mod.borderrooms[i]) do
				for k, shapeidx in pairs(mod.shapeindexes[shape]) do
					if idx == roomidx+shapeidx then
						oob = true
					end
				end
			end
			if roomdesc.Data.Doors & (1 << i) > 0 and IsDeadEnd(roomidx+adjindex[i]) and level:GetRoomByIdx(roomidx+adjindex[i]).GridIndex == -1 and not oob then
				table.insert(deadends, {Slot = i, GridIndex = roomidx+adjindex[i]})
			end
		end
	end

	if #deadends >= 1 then
		return deadends
	else
		return nil
	end
end
