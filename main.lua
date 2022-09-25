GreedSpecialRooms = RegisterMod("Greed Mode Special Rooms", 1)
local mod = GreedSpecialRooms
local game = Game()

mod.debug = false
mod.startroom = nil
mod.hasStairway = false
mod.hasCurseOfTheMaze = false
mod.lastseed = 1
mod.rng = RNG()

--enables mod.debug
--by adding debug-key to gitignore we can effectively switch on debug mode locally
--without having to switch it off before doing a release
--you just throw the file in the root directory, mod picks it up, git ignores it
--for the record, the contents of debug-key is literally just
--		GreedSpecialRooms.debug = true
--you can even grab it from scripts/enums
pcall(require("debug-key"))

include("scripts.libs.the-everything-function-rev1")

include("scripts.libs.lib")
include("scripts.enums.shared")
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

	mod.rng:SetSeed(game:GetSeeds():GetStageSeed(level:GetAbsoluteStage()), 35)
end

function mod.Init()
	if not mod.roomInit then
		mod.InitRooms()
		mod.roomInit = true
	end

	if game:IsGreedMode() and game:GetLevel():GetStage() < LevelStage.STAGE7_GREED then
		--fills mod.startroom, mod.hasCurseOfTheMaze, and mod.hasStairway
		--also sets rng seed
		PreProcess()

		--fills mod.roomrequests
		mod.GetRoomRequests()

		--takes mod.roomrequests
		--fills mod.roomdata, mod.redRoomsRequired, and mod.dotransition
		mod.GetCustomRoomData()

		--takes mod.redRoomsRequired and fills mod.redRoomsGenerated
		mod.GenerateRedRooms()

		--takes mod.roomdata, mod.startroom, and mod.redRoomsGenerated
		--returns if all red room data was used
		mod.ReplaceRoomData()

		--takes mod.dotransition and mod.roomsupdated
		mod.DoStageTransition()
	end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.Init)

function mod.OnNewRoom()
	if game:GetLevel():GetCurrentRoomDesc().Data.Type == RoomType.ROOM_PLANETARIUM
	and game:GetLevel():GetCurrentRoomDesc().GridIndex > 0 then --we enter a planetarium in the process of spawning one
		mod.lib.debugPrint("we entered a planetarium")
		mod.data.run.visitedPlanetarium = true
	end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnNewRoom)
