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
mod.firstrun = false
mod.runseed = 0 -- to tell if a new run has started
mod.refesh = false

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
	local roomdesc = level:GetRoomByIdx(initroomdesc.GridIndex)
	local roomdata = roomdesc.Data
	if roomdata and level:GetRoomByIdx(roomdesc.GridIndex).DisplayFlags
	and level:GetRoomByIdx(roomdesc.GridIndex) ~= level:GetCurrentRoomDesc().GridIndex then
		if level:GetStateFlag(LevelStateFlag.STATE_FULL_MAP_EFFECT)
		or (roomdata.Type ~= RoomType.ROOM_DEFAULT and roomdata.Type ~= RoomType.ROOM_ULTRASECRET
		and roomdata.Type ~= RoomType.ROOM_SECRET and roomdata.Type ~= RoomType.ROOM_SUPERSECRET
		and level:GetStateFlag(LevelStateFlag.STATE_COMPASS_EFFECT))
		or (level:GetStateFlag(LevelStateFlag.STATE_BLUE_MAP_EFFECT)
		and (roomdata.Type == RoomType.ROOM_SECRET or roomdata.Type == RoomType.ROOM_SUPERSECRET))
		then
			roomdesc.DisplayFlags = 111
		elseif level:GetStateFlag(LevelStateFlag.STATE_MAP_EFFECT) then
			roomdesc.DisplayFlags = 001
		else
			roomdesc.DisplayFlags = 0
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
		local stageType = level:GetStageType()
		level:SetStage(7, 0)
		if level:MakeRedRoomDoor(71, DoorSlot.RIGHT0) then
			local newRoom = level:GetRoomByIdx(72,0)
			newRoom.Data = gotor.Data
			newRoom.DisplayFlags = 5
			newRoom.Flags = 0
			sucess = true
		end
		level:SetStage(levelStage, stageType)
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
	local keyCountTwoOrMore = (Isaac.GetPlayer(i):GetNumKeys() >= 2)
	local coinCountFiveOrMore = (Isaac.GetPlayer(i):GetNumCoins() >= 5)

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
					if not coinCountFiveOrMore or keyCountTwoOrMore then
						return RoomType.ROOM_CHEST
					end
				elseif coinCountFiveOrMore then
					return RoomType.ROOM_ARCADE
				end
			end

			--Arcade/Vault logic can fall through without generating either
			if mod.roomchoice == 0 and rng:RandomInt(50) == 0
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

function mod:RefreshRooms(level, stage, curseRoom, planetarium)
	local shop = level:GetRoomByIdx(70,0)

	if stage == LevelStage.STAGE1_GREED and (seed:GetStartSeed() ~= mod.runseed) then
	-- Normal fadein (game start)
		local oldData = shop.Data
		Isaac.ExecuteCommand("goto s.default.0")
		shop.Data = level:GetRoomByIdx(-3,0).Data
		level:ChangeRoom(70)
		game:StartRoomTransition(START_TOP_ID, 1, RoomTransitionAnim.FADE)
		if not mod.firstrun then --otherwise it doesn't work when starting the first game of the session......
			game:ChangeRoom(START_TOP_ID)
		end

		if stairway then
			Isaac.Spawn(1000, 156, 1, Vector(440,160), Vector(0,0), nil)
		end

		shop.Data = oldData

		mod.firstrun = true

	else
		-- mosaic (level transition)
		-- do this here so that the door graphics are updated..
		mod:scheduleForUpdate(function()
			level:ChangeRoom(START_BOTTOM_ID) --TODO: Single crash here at womb w/ sacrifice room & planetarium spawn. Can't reproduce
			game:StartRoomTransition(START_TOP_ID, 1, RoomTransitionAnim.FADE)
			level:GetRoomByIdx(START_TOP_ID).VisitedCount = 1

			--YES this is immediately removed by changing rooms below but if I don't do it here it doesn't look right
			if stairway then
				Isaac.Spawn(1000, 156, 1, STAIRCASE_POS, ZERO_POS, nil)
			end

			mod:MovePlayersToPos(CENTER_POS)
		end, 0, ModCallbacks.MC_POST_RENDER)

		-- Refresh room to fix changes made not being saved when exiting room
		-- Causes various grid/backdrop details to shift a bit after fadein. sad!
		mod:scheduleForUpdate(function()
			level:ChangeRoom(START_BOTTOM_ID)
			level:GetRoomByIdx(START_BOTTOM_ID).VisitedCount = 1

			mod:MovePlayersToPos(CENTER_POS)
		end, 0, ModCallbacks.MC_POST_UPDATE)
	end

	mod:scheduleForUpdate(function()
		shop.VisitedCount = 0
		shop.DisplayFlags = 001

		curseRoom.VisitedCount = 0
		curseRoom.DisplayFlags = 001

		if planetarium then
			local planetariumRoom = level:GetRoomByIdx(72)
			planetariumRoom.VisitedCount = 0
			UpdateRoomDisplayFlags(planetariumRoom)
		end

		level:UpdateVisibility()
	end, 1, ModCallbacks.MC_POST_RENDER)

end

function mod:Init()
	local level = game:GetLevel()
	local stage = level:GetStage()
	local door = game:GetRoom():GetDoor(DoorSlot.LEFT0)
	local curseRoom = level:GetRoomByIdx(CURSE_ID, 0)

	mod.refresh = false
	rng:SetSeed(game:GetSeeds():GetStageSeed(level:GetStage()),level:GetStageType()+1)

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

	local planetarium = not gplan and (GreedSpecialRooms.Planetarium or (rng:RandomFloat() < level:GetPlanetariumChance()))
	if planetarium then
		mod.refresh = true
		planetarium = mod:DoPlanetarium(level, stage)
	end

	mod.roomchoice = GreedSpecialRooms.RoomChoice or mod:PickSpecialRoom(stage)

	if mod.roomchoice > 0 then
		Isaac.ExecuteCommand("goto s." .. SpecialRoom[mod.roomchoice].string .. "." .. rng:RandomInt(SpecialRoom[mod.roomchoice].maxVariant))
		mod.refresh = true

		local gotor = level:GetRoomByIdx(-3,0)
		if gotor.Data then
			curseRoom.Data = gotor.Data
			curseRoom.Flags = 0

			local doorData = door:GetSaveState()
			door.TargetRoomType = mod.roomchoice
			door:SetVariant(SpecialRoom[mod.roomchoice].variant)

			if MinimapAPI then
				local icon = SpecialRoom[mod.roomchoice].minimapIcon
				if mod.roomchoice == RoomType.ROOM_CHALLENGE and curseRoom.Data.Subtype == 1 then
					icon = "BossAmbushRoom"
				end
				MinimapAPI:GetRoomByIdx(CURSE_ID, 0).PermanentIcons = {icon}
			end
		end
	elseif stage == LevelStage.STAGE1_GREED and (seed:GetStartSeed() ~= mod.runseed) then
		mod:MovePlayersToPos(Vector(320.0, 160.0)) -- for consistency
	end

	if mod.refresh then
		mod:RefreshRooms(level, stage, curseRoom, planetarium)
	end

	if hascurseofmaze then
		mod:scheduleForUpdate(function()
			level:AddCurse(LevelCurse.CURSE_OF_MAZE)
		end, 0, ModCallbacks.MC_POST_UPDATE)
	end
end

mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
	if MMC and level:GetCurrentRoomDesc().Data.Type == RoomType.ROOM_CHALLENGE then
		MMC.Manager():Crossfade(Music.MUSIC_JINGLE_CHALLENGE_OUTRO)
		MMC.Manager():Queue(Music.MUSIC_BOSS_OVER)
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
	if game:IsGreedMode() and game:GetLevel():GetStage() < LevelStage.STAGE7_GREED then
		mod:Init()
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	-----mod compatibility-----
	if PlanetariumChance and game:IsGreedMode() then
		PlanetariumChance.storage.canPlanetariumsSpawn = true
		PlanetariumChance:updatePlanetariumChance()
	end

	mod.runseed = seed:GetStartSeed()
end)

mod:AddCallback(ModCallbacks.MC_POST_GAME_END, function()
	mod.runseed = 0
end)
