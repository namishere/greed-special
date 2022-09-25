local mod = GreedSpecialRooms
local game = Game()

--External Item Descriptions
if EID then
	local function HandleSacrificeRoomEID(descObj)
		if game:IsGreedMode() and game:GetLevel():GetStage() == LevelStage.STAGE1_GREED
		and descObj.ObjType == -999 and descObj.ObjVariant == -1 then
			local curCounter = descObj.ObjSubType or 1
			if curCounter <= 2 then
				local splitPoint = string.find(descObj.Description, '#', 1)
				descObj.Description = descObj.Description:sub(1,splitPoint-1)
			elseif curCounter >= 12 then
				descObj.Description = 	"50% chance to teleport to the \"Ultra Greed\" floor"
			end
		end
		return descObj
	end
	EID:addDescriptionModifier("GreedSpecialRooms Sacrifice", HandleSacrificeRoomEID, nil)
end

--Planetarium Chance
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continue)
	if PlanetariumChance and game:IsGreedMode() then
		PlanetariumChance.storage.canPlanetariumsSpawn = true
		if not continue then
			PlanetariumChance.storage.currentFloorSpawnChance = game:GetLevel():GetPlanetariumChance() * 100
		end
	end
end)

--Music Mod Callback (bugfix)
mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
	if MMC and game:IsGreedMode()
	and game:GetLevel():GetCurrentRoomDesc().Data.Type == RoomType.ROOM_CHALLENGE then
		MMC.Manager():Crossfade(Music.MUSIC_JINGLE_CHALLENGE_OUTRO)
		MMC.Manager():Queue(Music.MUSIC_BOSS_OVER)
	end
end)
