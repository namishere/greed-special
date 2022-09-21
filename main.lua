GreedSpecialRooms = RegisterMod("Greed Mode Special Rooms", 1)
local mod = GreedSpecialRooms
local game = Game()
local rng = RNG()

mod.debug = true
mod.startroom = nil
mod.hasStairway = false
mod.hasCurseOfTheMaze = false

include("scripts.libs.lib")
include("scripts.enums.shared")
include("scripts.roomshit")
include("scripts.requestrooms")
include("scripts.getroomdata")
include("scripts.generateredrooms")
include("scripts.replaceroomdata")
include("scripts.dostagetransition")

local function PreProcess()
	mod.startroom = game:GetRoom()

	mod.hasCurseOfTheMaze = false
	if game:GetLevel():GetCurses() & LevelCurse.CURSE_OF_MAZE > 0 then
		game:GetLevel():RemoveCurses(LevelCurse.CURSE_OF_MAZE)
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
	if not mod.roomInit then
		mod.InitRooms()
		mod.roomInit = true
	end

	if game:IsGreedMode() then
		--fills mod.startroom, mod.hasCurseOfTheMaze, and mod.hasStairway
		PreProcess()

		--fills mod.roomrequests
		mod.GetRoomRequests(rng)

		--fills mod.roomdata
		--and mod.redRoomsRequired
		mod.GetCustomRoomData()

		--fiils mod.redRoomsGenerated
		mod.GenerateRedRooms(rng)

		--returns if all red room data was used
		mod.ReplaceRoomData(rng)

		mod.DoStageTransition()
	end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.Init)
