GreedSpecialRooms = RegisterMod("Greed Mode Special Rooms", 1)
local mod = GreedSpecialRooms
local game = Game()
gRng = RNG()

mod.debug = true
mod.startroom = nil
mod.hasStairway = false
mod.hasCurseOfTheMaze = false

include("scripts.libs.the-everything-function-rev1")

include("scripts.libs.lib")
include("scripts.enums.shared")
include("scripts.roomshit")
include("scripts.requestrooms")
include("scripts.getroomdata")
include("scripts.generateredrooms")
include("scripts.replaceroomdata")
include("scripts.dostagetransition")

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

	gRng:SetSeed(game:GetSeeds():GetStageSeed(level:GetAbsoluteStage()), 35)
end

function mod.Init()
	if not mod.roomInit then
		mod.InitRooms()
		mod.roomInit = true
	end

	if game:IsGreedMode() then
		--fills mod.startroom, mod.hasCurseOfTheMaze, and mod.hasStairway
		PreProcess()

		--fills mod.roomrequests
		mod.GetRoomRequests(gRng)

		--fills mod.roomdata
		--and mod.redRoomsRequired
		mod.GetCustomRoomData()

		--fiils mod.redRoomsGenerated
		mod.GenerateRedRooms(gRng)

		--returns if all red room data was used
		mod.ReplaceRoomData(gRng)

		mod.DoStageTransition()
	end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.Init)
