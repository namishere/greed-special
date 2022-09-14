GreedSpecialRooms = RegisterMod("Greed Mode Special Rooms", 1)
local mod = GreedSpecialRooms
local game = Game()
local level = game:GetLevel()
local rng = RNG()
local seed = game:GetSeeds()

--TODO: Shop is displayed as visited when starting a new game; can't figure out how to fix
--		Probably rework planetarium code
--		- Did a little bit
--		Test test test test
--		Ideally figure out a way to either avoid the backdrop changing when entering a new level
--		- (or figure out a new solution that doesn't require us to warp between rooms)
--		Implement proper challenge waves
--		- Waves imported from base game, shop is using cathedral waves
--		Clean clean CLEAN THIS SHIT
--		- Shit reasonably cleaned
--		Should we try and add support for mods to add new room variants?
--		Need to ensure compatibility with alt path mod, waiting on team compliance version
--		- Compatible with Gamonymous version

local CURSE_ID = 83
local START_BOTTOM_ID = 97
local START_TOP_ID = 84

local CENTER_POS = Vector(320.0, 280.0)
local STAIRCASE_POS = Vector(440.0 ,160.0)

local SACRIFICE_MIN = 12
local TELEPORT_LENGTH_DELAY = 5
local TELEPORT_LENGTH_ANIM = 20

local DoorVariant = {
	BOMB = 0,
	KEY = 1, -- subtype 1 is maus door and strange door??? may be general use
	KEY2 = 2,
	BOMB2 = 3, -- also used by knife door?
	BARRED = 4,
	LOCKED = 5, -- fallback behavior for invalid variants
	UNKNOWN = 6, -- shows bars fading when entering room?
	CLOSED = 7,
	OPENED = 8
}

--maxVariant starts at index 0
local SpecialRoom = {
	[RoomType.ROOM_ARCADE] = {maxVariant = 32, variant = DoorVariant.KEY, string = "arcade", minimapIcon = "Arcade"},
	[RoomType.ROOM_CHALLENGE] = {maxVariant = 24, variant = DoorVariant.OPENED, string = "challenge", minimapIcon = "AmbushRoom"},
	[RoomType.ROOM_LIBRARY] = {maxVariant = 14, variant = DoorVariant.KEY, string = "library", minimapIcon = "Library"},
	[RoomType.ROOM_SACRIFICE] = {maxVariant = 11, variant = DoorVariant.OPENED, string = "sacrifice", minimapIcon = "SacrificeRoom"},
	[RoomType.ROOM_ISAACS] = {maxVariant = 24, variant = DoorVariant.BOMB2, string = "isaacs", minimapIcon = "IsaacsRoom"},
	[RoomType.ROOM_BARREN] = {maxVariant = 24, variant = DoorVariant.BOMB2, string = "barren", minimapIcon = "BarrenRoom"},
	[RoomType.ROOM_CHEST] = {maxVariant = 48, variant = DoorVariant.KEY2, string = "chest", minimapIcon = "ChestRoom"},
	[RoomType.ROOM_DICE] = {maxVariant = 18, variant = DoorVariant.KEY2, string = "dice", minimapIcon = "DiceRoom"},
	[RoomType.ROOM_PLANETARIUM] = {maxVariant = 4, variant = DoorVariant.KEY, string = "planetarium", minimapIcon = "Planetarium"}
}

mod.debug = true
mod.roomchoice = 0
mod.lastseed = 0

-- Vars for fake stage transition
mod.teleportIndex = 0
mod.teleportStartFrame = 0
mod.teleportEndFrame = 0
mod.paused = false

local function debugPrint(string)
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

function mod.ResetTempVars()
	mod.paused = false
	mod.teleportIndex = 0
	mod.teleportStartFrame = 0
	mod.teleportEndFrame = 0
end

mod.delayedFuncs = {}
function mod:scheduleForUpdate(foo, delay, callback)
    callback = callback or ModCallbacks.MC_POST_UPDATE

    if not mod.delayedFuncs[callback] then
        mod.delayedFuncs[callback] = {}
        mod:AddCallback(callback, function()
            runUpdates(mod.delayedFuncs[callback])
        end)
    end

    table.insert(mod.delayedFuncs[callback], { Func = foo, Delay = delay })
end

function mod:UpdateRoomDisplayFlags(initroomdesc)
	local level = game:GetLevel()
	local roomdesc = level:GetRoomByIdx(initroomdesc.GridIndex) --Only roomdescriptors from level:GetRoomByIdx() are mutable
	local roomdata = roomdesc.Data
	if level:GetRoomByIdx(roomdesc.GridIndex).DisplayFlags then
		if level:GetRoomByIdx(roomdesc.GridIndex) ~= level:GetCurrentRoomDesc().GridIndex then
			if roomdata then
				roomdesc.DisplayFlags = RoomDescriptor.DISPLAY_ICON
			end
		end
	end
end

function mod:MovePlayersToPos(position)
	Isaac.GetPlayer().Position = position
	if game:GetNumPlayers() > 1 then
		for i = 1, game:GetNumPlayers() - 1 do
			Isaac.GetPlayer(i).Position = Isaac.GetFreeNearPosition(position, 1)
		end
	end
end

--TODO: I'd like to redo this myself, I want to lower the added chance
--		but I'm having trouble parsing this code. Ideally I'd like to
--		save game:GetTreasureRoomVisitCount() on MC_POST_NEW_LEVEL
--		and compare the saved count with the new count when moving floors
--		This needs to account for Forget Me Now and also save that data

function mod:GetCustomPlanetariumChance(level, stage, stageType)
	local planetariumBonus = 0
	local stageOffset = -1
	--If not Alt Path then reduce by 1. For mods where Greed Downpour is a second floor.
	if stageType >= StageType.STAGETYPE_REPENTANCE then
		stageOffset = 0
	end
	stage = stage + stageOffset

	if game:GetTreasureRoomVisitCount() < stage*2 then
		--To apply multiple bonus if many Treasure Rooms are skipped and unaccounted for.
		planetariumBonus = 0.2 * math.ceil((stage*2-game:GetTreasureRoomVisitCount())/2)
		--Skipping one treasure on Basement and one in Caves should add up to 40% but actually adds up to 20% with this formula, this extra bit helps with that.
		if stage >= 2 and game:GetTreasureRoomVisitCount()/(stage*2) <= 0.5 and level:GetPlanetariumChance() < 0.2 then
			planetariumBonus = planetariumBonus + 0.2
			--If someone wanted to skip one treasure room for 4 floors (until Sheol) it'd be inaccurate again but seems excessive

			--if stage = 4 then
			--	planetariumBonus = planetariumBonus + 0.2
			--end

		end
	end

	debugPrint("Stage used for calc: "..stage)
	debugPrint("Tresure Rooms Visited: "..game:GetTreasureRoomVisitCount())
	debugPrint("Natural Planetarium Chance: "..string.format("%.2f", level:GetPlanetariumChance()))
	debugPrint("Bonus Planetarium Chance: "..string.format("%.2f",planetariumBonus))
	debugPrint("Full Planetarium Chance: "..string.format("%.2f", math.min(1, level:GetPlanetariumChance() + planetariumBonus)))

	return math.min(1, level:GetPlanetariumChance() + planetariumBonus)
end

function mod:DoPlanetarium(level, levelStage, stageType)
	Isaac.ExecuteCommand("goto s.planetarium." .. rng:RandomInt(SpecialRoom[RoomType.ROOM_PLANETARIUM].maxVariant))
	local gotor = level:GetRoomByIdx(-3,0)
	debugPrint("Planetarium gotor has no Data :(")
	if gotor.Data then
		level:SetStage(7, 0)
		if level:MakeRedRoomDoor(71, DoorSlot.RIGHT0) then
			local newRoom = level:GetRoomByIdx(72,0)
			newRoom.Data = gotor.Data
			newRoom.Flags = 0
			mod:UpdateRoomDisplayFlags(newRoom)
			level:UpdateVisibility()
		else
			debugPrint("Failed to make a Red Room Door for Planetarium :(")
		end
		level:SetStage(levelStage, stageType)
	end
end

function mod:PickSpecialRoom(stage)
	--TODO: convert into flag system
	local allPlayersFullHealth = true
	local allPlayersRedHeartsOnly = true
	local allPlayersSoulHeartsOnly = true

	local redHeartCount = 0
	local soulHeartCount = 0
	local keyCountTwoOrMore = (Isaac.GetPlayer():GetNumKeys() >= 2)
	local coinCountFifteenOrMore = (Isaac.GetPlayer():GetNumCoins() >= 15)

	local devilRoomVisited = game:GetStateFlag(GameStateFlag.STATE_DEVILROOM_VISITED)

	for i = 0, Game():GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		if allPlayersFullHealth and player:GetMaxHearts() > player:GetHearts() + player:GetSoulHearts() then --bone hearts ignored
			allPlayersFullHealth = false
		end

		redHeartCount = math.max(redHeartCount, player:GetHearts())
		soulHeartCount = math.max(soulHeartCount, player:GetSoulHearts())
	end

	allPlayersRedHeartsOnly = (soulHeartCount == 0)
	allPlayersSoulHeartsOnly = (redHeartCount == 0)

	-- Special Room
	if rng:RandomInt(7) == 0 or (allPlayersFullHealth and rng:RandomInt(4) == 0) then
		if rng:RandomInt(50) == 0 or (keyCountTwoOrMore and rng:RandomInt(5) == 0) then
			return RoomType.ROOM_DICE
		else
			return RoomType.ROOM_SACRIFICE
		end
	elseif rng:RandomInt(20) == 0 then
		return RoomType.ROOM_LIBRARY
	elseif rng:RandomInt(2) ~= 0 or (devilRoomVisited and rng:RandomInt(4) ~= 0) then
		--if rng:RandomInt(4) == 0 or (stage == LevelStage.STAGE1_GREED and rng:RandomInt(4) == 0) then
			--return RoomType.ROOM_MINIBOSS
		if allPlayersFullHealth and stage > LevelStage.STAGE1_GREED and rng:RandomInt(2) == 0 then
			return RoomType.ROOM_CHALLENGE
		else
			-- WOW the logic for arcades & vaults is a fucking headache
			if game:GetLevel():GetStage() % 2 == 0 then
				local vaultBaseChance = (rng:RandomInt(10) == 0 or (keyCountTwoOrMore and rng:RandomInt(3) == 0))
				if vaultBaseChance then
					if not coinCountFifteenOrMore or keyCountTwoOrMore then
						return RoomType.ROOM_CHEST
					end
				elseif coinCountFifteenOrMore then
					return RoomType.ROOM_ARCADE
				end
			end

			--Arcade/Vault logic can fall through without generating either
			if rng:RandomInt(50) == 0
			or (((allPlayersRedHeartsOnly and redHeartCount < 4)
			or (allPlayersSoulHeartsOnly and soulHeartCount <= 4))
			and rng:RandomInt(5) == 0) then
				if rng:RandomInt(2) == 0 then
					return RoomType.ROOM_ISAACS
				else
					return RoomType.ROOM_BARREN
				end
			end
		end
	end
	-- Default to Curse Room
	return 0
end

--player:AddControlsCooldown(int) could work too, but we want to mimic the whole game pausing
function mod:PauseGame(force)
	if game:GetRoom():GetBossID() ~= 54 or force then -- Intentionally fail achievement note pauses on Lamb, since it breaks the Victory Lap menu super hard
		for _, projectile in pairs(Isaac.FindByType(9)) do
			projectile:Remove()

			local poof = Isaac.Spawn(1000, 15, 0, projectile.Position, Vector.Zero, nil)
			poof.SpriteScale = Vector.One * 0.75
		end

		for _, pillar in pairs(Isaac.FindByType(951, 1)) do
			pillar:Kill()
			pillar:Remove()
		end

		mod.paused = true

		Isaac.GetPlayer():UseActiveItem(CollectibleType.COLLECTIBLE_PAUSE, UseFlag.USE_NOANIM)
	end
end

function mod:Init()
	local level = game:GetLevel()
	local stage = level:GetStage()
	local stageType = level:GetStageType()
	local door = game:GetRoom():GetDoor(DoorSlot.LEFT0)
	local currentroomidx = level:GetCurrentRoomDesc().GridIndex
	local currentroomvisitcount = level:GetRoomByIdx(currentroomidx).VisitedCount
	local curseRoom = level:GetRoomByIdx(CURSE_ID, 0)

	rng:SetSeed(level:GetDungeonPlacementSeed()+1, 35)

	local hascurseofmaze = false
	if level:GetCurses() & LevelCurse.CURSE_OF_MAZE > 0 then
		level:RemoveCurses(LevelCurse.CURSE_OF_MAZE)
		hascurseofmaze = true
	end

	local stairway = false
	for i = 0, game:GetNumPlayers() - 1 do
		if Isaac.GetPlayer(i):HasCollectible(CollectibleType.COLLECTIBLE_STAIRWAY) then
			stairway = true
			break
		end
	end

	local planetarium = false
	if not gplan then
		local plaenetariumChance = mod:GetCustomPlanetariumChance(level, stage, stageType)
		if PlanetariumChance then
			PlanetariumChance.storage.currentFloorSpawnChance = plaenetariumChance * 100
		end
		planetarium = (GreedSpecialRooms.Planetarium or (rng:RandomFloat() < plaenetariumChance))
		if planetarium then
			mod:DoPlanetarium(level, stage, stageType)
		end
	end

	mod.roomchoice = GreedSpecialRooms.RoomChoice or mod:PickSpecialRoom(stage)

	if mod.roomchoice > 0 then
		Isaac.ExecuteCommand("goto s." .. SpecialRoom[mod.roomchoice].string .. "." .. rng:RandomInt(SpecialRoom[mod.roomchoice].maxVariant))

		local gotor = level:GetRoomByIdx(-3,0)
		if gotor.Data then
			curseRoom.Data = gotor.Data
			curseRoom.Flags = 0

			door.TargetRoomType = mod.roomchoice
			door:SetVariant(SpecialRoom[mod.roomchoice].variant)
			door:SetRoomTypes(RoomType.ROOM_DEFAULT, mod.roomchoice)
			door:Update()

			if MinimapAPI then
				MinimapAPI:GetRoomByIdx(CURSE_ID, 0):UpdateType()
			end
		end
	end

	if mod.roomchoice > 0 or planetarium then
		mod:scheduleForUpdate(function()
			local uLevel = game:GetLevel()
			game:StartRoomTransition(START_TOP_ID, Direction.DOWN, RoomTransitionAnim.MAZE)
			if stairway then
				Isaac.Spawn(1000, 156, 1, STAIRCASE_POS, Vector.Zero, nil)
			end

			if uLevel:GetRoomByIdx(currentroomidx).VisitedCount ~= currentroomvisitcount then
				uLevel:GetRoomByIdx(currentroomidx).VisitedCount = currentroomvisitcount-1
			end
			mod:UpdateRoomDisplayFlags(curseRoom)
			uLevel:Update()
			uLevel:UpdateVisibility()
		end, 0, ModCallbacks.MC_POST_RENDER)
		mod:scheduleForUpdate(function()
			local uLevel = game:GetLevel()
			if stairway then
				Isaac.Spawn(1000, 156, 1, STAIRCASE_POS, Vector.Zero, nil)
			end
			if hascurseofmaze then
				uLevel:AddCurse(LevelCurse.CURSE_OF_MAZE, true)
			end
			uLevel:UpdateVisibility()
		end, 0, ModCallbacks.MC_POST_UPDATE)
	end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
	if mod.lastseed ~= level:GetDungeonPlacementSeed() then
		mod:MovePlayersToPos(CENTER_POS)
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	mod.lastseed = level:GetDungeonPlacementSeed()

	if mod.teleportIndex > 0 then
		if game:GetFrameCount() - mod.teleportStartFrame == TELEPORT_LENGTH_DELAY * mod.teleportIndex then
			debugPrint("teleporting teleportIndex #"..mod.teleportIndex)
			local player = Isaac.GetPlayer(mod.teleportIndex - 1)
			local playerRef = EntityRef(player)
			local playerCount = game:GetNumPlayers()
			player:AnimateTeleport(mod.teleportIndex == 1)
			mod:scheduleForUpdate(function()
				--if you restart while teleporting (via the console in this case, but other mods could invoke it),
				--player becomes garbage data and the game crashes. now doing two pairs of sanity checks;
				--check that we're past POST_GAME_STARTED so we've had a chance to wipe mod.paused,
				--and use an EntityRef instead of the raw player entity so we can check that it still exists
				if game:GetFrameCount() > 1 and mod.paused and playerRef.Entity then
					local refPlayer = playerRef.Entity
					local sprite = refPlayer:GetSprite()
					refPlayer:GetData().greedcolor = {sprite.Color.R, sprite.Color.G, sprite.Color.B, sprite.Color.A}
					sprite.Color = Color(1, 1, 1, 0)
				end
			end, TELEPORT_LENGTH_ANIM, ModCallbacks.MC_POST_UPDATE)
			if mod.teleportIndex < playerCount then
				mod.teleportIndex = mod.teleportIndex + 1
			end
		elseif game:GetFrameCount() == mod.teleportEndFrame then
			game:GetLevel():SetStage(7, 0)
			Isaac.GetPlayer():UseActiveItem(CollectibleType.COLLECTIBLE_FORGET_ME_NOW, UseFlag.USE_NOANIM)
		end
	end
end)

for hook = InputHook.IS_ACTION_PRESSED, InputHook.IS_ACTION_TRIGGERED do
	mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function(_, entity, hook, action)
		if mod.paused and action ~= ButtonAction.ACTION_CONSOLE then
			return false
		end
	end, hook)
end

mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function(_, entity, hook, action)
	if mod.paused and action ~= ButtonAction.ACTION_CONSOLE then
		return 0
	end
end, InputHook.GET_ACTION_VALUE)

mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, tookDamage, damageAmount, damageFlags, damageSource, damageCountdownFrames)
	if mod.paused then
		return false
	end

	local level = game:GetLevel()
	local room = level:GetCurrentRoom()
	if game:IsGreedMode() and room:GetType() == RoomType.ROOM_SACRIFICE then
		if damageFlags == (DamageFlag.DAMAGE_SPIKES | DamageFlag.DAMAGE_NO_PENALTIES) then
			for i = 1, room:GetGridSize() do
				local gridEntity = room:GetGridEntity(i)
				if gridEntity and gridEntity:ToSpikes()
				and gridEntity.VarData >= SACRIFICE_MIN -1 and rng:RandomInt(2) == 0 then
					mod:scheduleForUpdate(function()
						for i = 0, game:GetNumPlayers() - 1 do
							Isaac.GetPlayer().Velocity = Vector.Zero
						end
						mod:PauseGame(true)
						mod.teleportStartFrame = game:GetFrameCount()
						mod.teleportEndFrame = mod.teleportStartFrame + (TELEPORT_LENGTH_DELAY * game:GetNumPlayers()) + TELEPORT_LENGTH_ANIM
						mod.teleportIndex = 1
						debugPrint("player count is "..game:GetNumPlayers()..". let's get started...")
					end, 0, ModCallbacks.MC_POST_UPDATE)
				end
			end
		end
	end
end, EntityType.ENTITY_PLAYER)

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
	if game:IsGreedMode() then
		if game:GetLevel():GetStage() < LevelStage.STAGE7_GREED then
			mod:Init()
		elseif mod.paused then
			for i = 0, game:GetNumPlayers() - 1 do
				local player = Isaac.GetPlayer(i)
				local data = player:GetData()
				local color = {1, 1, 1, 1}
				if data.greedcolor then
					color = {data.greedcolor[1], data.greedcolor[2], data.greedcolor[3], data.greedcolor[4]}
				end

				player:GetSprite().Color = Color(color[1], color[2],color[3], color[4])
				player:AnimateAppear()
			end
		end

		mod.ResetTempVars()
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	mod.ResetTempVars()
	-----mod compatibility-----
	if PlanetariumChance and game:IsGreedMode() then
		PlanetariumChance.storage.canPlanetariumsSpawn = true
		--PlanetariumChance:updatePlanetariumChance()
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_GAME_END, function()
	mod.ResetTempVars()
end)

mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
	if MMC and level:GetCurrentRoomDesc().Data.Type == RoomType.ROOM_CHALLENGE then
		MMC.Manager():Crossfade(Music.MUSIC_JINGLE_CHALLENGE_OUTRO)
		MMC.Manager():Queue(Music.MUSIC_BOSS_OVER)
	end
end)
