local mod = GreedSpecialRooms
local json = require("json")

mod.data = {
	run = {
		visitedPlanetarium = false
	}
}

function mod:LoadModData(continuedRun)
	mod.lib.debugPrint("loading mod data.. continue is "..tostring(continuedRun))
	local save = {}
	if mod:HasData() then
		mod.lib.debugPrint("data exists")
		save = json.decode(mod:LoadData())
	else
		mod.lib.debugPrint("creating data")
		save = {
			run = {
				visitedPlanetarium = false
			},
			--config = {}
		}
	end
	if not continuedRun then
		mod.lib.debugPrint("wiping run data")
		mod.data.run.visitedPlanetarium = false
	else
		local result = mod.lib.ValidateBool(save.run.visitedPlanetarium, false)
		mod.lib.debugPrint("ValidateBool returned "..tostring(result))
		mod.data.run.visitedPlanetarium = result
	end
	mod.lib.debugPrint("visitedPlanetarium: "..tostring(mod.data.run.visitedPlanetarium))
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function() 	mod:SaveData(json.encode(mod.data)) end)

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continue)
	mod:LoadModData(continue)
	--mod.ResetTempVars()
end)

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function(_, shouldSave)
	if not shouldSave then
		mod.data.run.visitedPlanetarium = false
	end
	mod:SaveData(json.encode(mod.data))
end)

mod:AddCallback(ModCallbacks.MC_POST_GAME_END, function()
	--mod.ResetTempVars()
	mod.data.run.visitedPlanetarium = false
	mod:SaveData(json.encode(mod.data))
end)
