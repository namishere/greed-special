local mod = GreedSpecialRooms
local game = Game()
mod.lib = {}

--mod.lib.alias_table = include("alias")

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

function mod.lib.ValidateBool(var, default)
	if var ~= nil then return var end
	return default
end

function mod.lib.debugPrint(string)
	if mod.debug and (type(string) == "string") then
		print(string)
		Isaac.DebugString("SPECIALGREED: " .. string)
	end
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

