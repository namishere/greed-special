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
local ZERO_POS = Vector(0.0, 0.0)

local SACRIFICE_MIN = 12
local TELEPORT_DELAY = 5
local TELEPORT_ANIM = 20

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

mod.debug = false
mod.roomchoice = 0

-- Vars for fake stage transition
mod.teleportIndex = 0
mod.teleportStartFrame = 0
mod.teleportEndFrame = 0
mod.paused = false

mod.lastSacCount = nil

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

function mod.ResetVars()
	mod.paused = false
	mod.lastSacCount = nil
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

function mod:DoPlanetarium(level, levelStage)
	Isaac.ExecuteCommand("goto s.planetarium." .. rng:RandomInt(SpecialRoom[RoomType.ROOM_PLANETARIUM].maxVariant))
	local gotor = level:GetRoomByIdx(-3,0)
	if gotor.Data then
		if level:MakeRedRoomDoor(71, DoorSlot.RIGHT0) then
			local newRoom = level:GetRoomByIdx(72,0)
			newRoom.Data = gotor.Data
			newRoom.Flags = 0
			mod:UpdateRoomDisplayFlags(newRoom)
			level:UpdateVisibility()
			success = true
		end
	end
	return success
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
	-- TODO: add 1/4 chance if devil deal visited?
	elseif rng:RandomInt(2) == 1 then
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
	local door = game:GetRoom():GetDoor(DoorSlot.LEFT0)
	local currentroomidx = level:GetCurrentRoomDesc().GridIndex
	local currentroomvisitcount = level:GetRoomByIdx(currentroomidx).VisitedCount
	local curseRoom = level:GetRoomByIdx(CURSE_ID, 0)

	rng:SetSeed(game:GetSeeds():GetStageSeed(level:GetStage()),level:GetStageType()+1)

	--TODO: This errors on PostRender for Jacob & Esau!!!
	for i = 0, game:GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		player:GetData().ResetPosition = player.Position
	end

	local hascurseofmaze = false
	if level:GetCurses() & LevelCurse.CURSE_OF_MAZE > 0 then
		level:RemoveCurses(LevelCurse.CURSE_OF_MAZE)
		hascurseofmaze = true
	end

	--TODO: forgotten when we refactored code, needs to be reimplemented
	local stairway = false
	for i = 0, game:GetNumPlayers() - 1 do
		if Isaac.GetPlayer(i):HasCollectible(CollectibleType.COLLECTIBLE_STAIRWAY) then
			stairway = true
			break
		end
	end

	local planetarium = not gplan and (GreedSpecialRooms.Planetarium or (rng:RandomFloat() < level:GetPlanetariumChance()))
	if planetarium then
		planetarium = mod:DoPlanetarium(level, stage)
	end

	mod.roomchoice = GreedSpecialRooms.RoomChoice or mod:PickSpecialRoom(stage)

	if mod.roomchoice > 0 then
		Isaac.ExecuteCommand("goto s." .. SpecialRoom[mod.roomchoice].string .. "." .. rng:RandomInt(SpecialRoom[mod.roomchoice].maxVariant))

		local gotor = level:GetRoomByIdx(-3,0)
		if gotor.Data then
			curseRoom.Data = gotor.Data
			curseRoom.Flags = 0
			mod:scheduleForUpdate(function()
				game:StartRoomTransition(currentroomidx, 0, RoomTransitionAnim.FADE)
				if level:GetRoomByIdx(currentroomidx).VisitedCount ~= currentroomvisitcount then
					level:GetRoomByIdx(currentroomidx).VisitedCount = currentroomvisitcount-1
				end
				mod:UpdateRoomDisplayFlags(curseRoom)
				level:UpdateVisibility()
				for i = 0, game:GetNumPlayers() - 1 do
					local player = Isaac.GetPlayer(i)
					player.Position = player:GetData().ResetPosition
				end
			end, 0, ModCallbacks.MC_POST_RENDER)
			mod:scheduleForUpdate(function()
				if hascurseofmaze then
					level:AddCurse(LevelCurse.CURSE_OF_MAZE)
					mod.applyingcurseofmaze = false
				end
				for i = 0, game:GetNumPlayers() - 1 do --You have to do it twice or it doesn't look right, not sure why
					local player = Isaac.GetPlayer(i)
					player.Position = player:GetData().ResetPosition
				end
				level:UpdateVisibility()
			end, 0, ModCallbacks.MC_POST_UPDATE)

			door.TargetRoomType = mod.roomchoice
			door:SetVariant(SpecialRoom[mod.roomchoice].variant)

			if MinimapAPI then
				MinimapAPI:GetRoomByIdx(CURSE_ID, 0):UpdateType()
			end
		end
	end

	game:StartRoomTransition(currentroomidx, 0, RoomTransitionAnim.FADE)
	mod:scheduleForUpdate(function()
		for i = 0, game:GetNumPlayers() - 1 do
			local player = Isaac.GetPlayer(i)
			player.Position = player:GetData().ResetPosition
		end
	end, 0)
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	local room = game:GetRoom()
	if game:IsGreedMode() and room:GetType() == RoomType.ROOM_SACRIFICE then
		for i = 1, room:GetGridSize() do
			local gridEntity = room:GetGridEntity(i)
			if gridEntity and gridEntity:ToSpikes() then
				local sacCount = gridEntity.VarData
				if not mod.lastSacCount then
					mod.lastSacCount = sacCount
				end
				
				if mod.lastSacCount ~= sacCount then
					if gridEntity.VarData >= SACRIFICE_MIN and rng:RandomInt(2) == 0 then
						for i = 0, game:GetNumPlayers() - 1 do
							Isaac.GetPlayer().Velocity = Vector.Zero
						end
						mod:PauseGame(true)
						mod.teleportStartFrame = game:GetFrameCount() - TELEPORT_DELAY
						mod.teleportEndFrame = mod.teleportStartFrame + (TELEPORT_DELAY * game:GetNumPlayers()) + TELEPORT_ANIM
						mod.teleportIndex = 1
						debugPrint("player count is "..game:GetNumPlayers()..". let's get started...")
					end
				end
				mod.lastSacCount = sacCount
			end
		end
	end
	
	if mod.teleportIndex > 0 then
		if game:GetFrameCount() - mod.teleportStartFrame == TELEPORT_DELAY * mod.teleportIndex then
			debugPrint("teleporting teleportIndex #"..mod.teleportIndex)
			local player = Isaac.GetPlayer(mod.teleportIndex - 1)
			local playerRef = EntityRef(player)
			local playerCount = game:GetNumPlayers()
			player:AnimateTeleport(true)
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
			end, TELEPORT_ANIM)
			if mod.teleportIndex < playerCount then
				mod.teleportIndex = mod.teleportIndex + 1
			end
		elseif game:GetFrameCount() == mod.teleportEndFrame then
			game:GetLevel():SetStage(7, 0)
			Isaac.GetPlayer():UseActiveItem(CollectibleType.COLLECTIBLE_FORGET_ME_NOW, UseFlag.USE_NOANIM)
		end
	end
end)

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
		
		mod.ResetVars()
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	mod.ResetVars()
	-----mod compatibility-----
	if PlanetariumChance and game:IsGreedMode() then
		PlanetariumChance.storage.canPlanetariumsSpawn = true
		PlanetariumChance:updatePlanetariumChance()
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_GAME_END, function()
	mod.ResetVars()
end)

mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
	if MMC and level:GetCurrentRoomDesc().Data.Type == RoomType.ROOM_CHALLENGE then
		MMC.Manager():Crossfade(Music.MUSIC_JINGLE_CHALLENGE_OUTRO)
		MMC.Manager():Queue(Music.MUSIC_BOSS_OVER)
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

mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flags, source, countdown)
	if mod.paused then
		return false
	end
end)