GreedSpecialRooms = RegisterMod("Greed Mode Special Rooms", 1)
local mod = GreedSpecialRooms
local game = Game()

mod.debug = true
mod.startroom = nil
mod.hasStairway = false
mod.hasCurseOfTheMaze = false
mod.inSecretExit = false

mod.frameLastInit = 0
mod.stageLastUpdate = { room = {Stage = 0, StageType = 0}, level = {Stage = 0, StageType = 0} }
mod.stageLastNewLevel = 0
mod.rng = RNG()

include("scripts.libs.the-everything-function-rev1")

include("scripts.enums.shared")
include("scripts.libs.lib")
include("scripts.savedata")
include("scripts.roomshit")
include("scripts.pause")
include("scripts.requestrooms")
include("scripts.getroomdata")
include("scripts.generateredrooms")
include("scripts.replaceroomdata")
include("scripts.dostagetransition")
include("scripts.modsupport")

include("scripts.sacrifice")

local function PreProcess()
	local level = game:GetLevel()
	mod.startroom = game:GetRoom()

	mod.hasCurseOfTheMaze = false
	if level:GetCurses() & LevelCurse.CURSE_OF_MAZE > 0 then
		level:RemoveCurses(LevelCurse.CURSE_OF_MAZE)
		mod.hasCurseOfTheMaze = true
	end

	mod.hasStairway = false
	for i = 0, game:GetNumPlayers() - 1 do
		if Isaac.GetPlayer(i):HasCollectible(CollectibleType.COLLECTIBLE_STAIRWAY) then
			mod.hasStairway = true
			break
		end
	end
end

function mod.Init()
	-- Do this outside of PreProcess because I want it done asap
	if not mod.roomInit then
		mod.InitRooms()
		mod.roomInit = true
	end

	local level = game:GetLevel()
	if game:IsGreedMode() and level:GetStage() < LevelStage.STAGE7_GREED then
		mod.lib.debugPrint("GreedSpecialRooms.Init() started")

		mod.rng:SetSeed(game:GetSeeds():GetStageSeed(level:GetAbsoluteStage()), 35)

		mod.lib.debugPrint("GreedSpecialRooms.Init(): inSecretExit is "..tostring(mod.inSecretExit))
		if mod.inSecretExit then
			local stRng = mod.rng:RandomInt(1)
			local stage = level:GetStage()
			if not (mod.stageLastUpdate.level.Type >= StageType.STAGETYPE_REPENTANCE) then
				stage = stage - 1
			end
			mod.lib.debugPrint("GreedSpecialRooms.Init(): Reseeding for alt path; stage "..(stage)..", type "..StageType.STAGETYPE_REPENTANCE + stRng)
			mod.inSecretExit = false
			level:SetStage(stage, StageType.STAGETYPE_REPENTANCE + stRng)
			Isaac.ExecuteCommand("reseed")
		elseif game:GetFrameCount() ~= frameLastInit or game:GetFrameCount() == 0 then
			--fills mod.startroom, mod.hasCurseOfTheMaze, and mod.hasStairway
			PreProcess()

			--fills mod.roomsrequested
			mod.GetRoomRequests()

			--takes mod.roomsrequested
			--fills mod.roomdata, mod.redRoomsRequired, and mod.dotransition
			mod.GetCustomRoomData()

			--takes mod.redRoomsRequired and fills mod.redRoomsGenerated
			mod.GenerateRedRooms()

			--takes mod.roomdata, mod.startroom, and mod.redRoomsGenerated
			--returns if all red room data was used
			mod.ReplaceRoomData()

			--takes mod.dotransition and mod.roomsupdated
			mod.DoStageTransition()

		else
			mod.lib.debugPrint("hey, what the fuck now? get out of here")
			for _,v in ipairs(mod.roomsupdated) do
				if MinimapAPI then
					MinimapAPI:GetRoomByIdx(v, 0):SyncRoomDescriptor()
				end
			end
			mod.UpdateMinimap()
		end

		mod.frameLastInit = game:GetFrameCount()
		mod.lib.debugPrint("GreedSpecialRooms.Init() finished")
	end
	mod.stageLastUpdate.level.Stage = level:GetStage()
	mod.stageLastUpdate.level.Type = level:GetStageType()
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.Init)

function mod.OnNewRoom()
	local level = game:GetLevel()
	if mod.stageLastUpdate.room.Stage == level:GetStage()
	and mod.stageLastUpdate.room.Type == level:GetStageType() then
		local roomDesc = game:GetLevel():GetCurrentRoomDesc()
		if roomDesc.GridIndex > 0 then
			if roomDesc.Data.Type == RoomType.ROOM_SECRET_EXIT then
				mod.inSecretExit = true
				mod.lib.debugPrint("OnNewRoom(): in secret exit, inSecretExit now "..tostring(mod.inSecretExit))
			else
				mod.inSecretExit = false
				mod.lib.debugPrint("OnNewRoom(): not in secret exit, inSecretExit now "..tostring(mod.inSecretExit))
				if roomDesc.Data.Type == RoomType.ROOM_PLANETARIUM then  --we enter a planetarium in the process of spawning one
					mod.lib.debugPrint("we entered a planetarium")
					mod.data.run.visitedPlanetarium = true
				end
			end
		end
	else
		mod.lib.debugPrint("OnNewRoom(): level changed since last OnNewRoom()")
	end
	mod.stageLastUpdate.room.Stage = level:GetStage()
	mod.stageLastUpdate.room.Type = level:GetStageType()
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)
