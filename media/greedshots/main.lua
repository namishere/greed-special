local mod = RegisterMod("Greedshots", 1)
local game = Game()
local level = game:GetLevel()

local CURSE_ID = 83
local START_BOTTOM_ID = 97
local START_TOP_ID = 84
local CENTER_POS = Vector(320.0, 280.0)
local DOOR_POS = Vector(80.0, 280.0)

if GREEDSHOTS then
	Isaac.GetPlayer().Position = Isaac.GetFreeNearPosition(DOOR_POS, 1)
	game:GetHUD():SetVisible(false)
	level:RemoveCurses(LevelCurse.CURSE_OF_DARKNESS)
	--Isaac.GetPlayer():AnimateHappy()
end
