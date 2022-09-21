GreedSpecialRooms = RegisterMod("Greed Mode Special Rooms", 1)
local mod = GreedSpecialRooms
local game = Game()
local rng = RNG()
local json = require("json")

include("roomshit")


--TODO: Probably rework planetarium code
--		- Done
--		Test test test test
--		Implement proper challenge waves
--		- Waves imported from base game, shop is using cathedral waves
--		Clean clean CLEAN THIS SHIT
--		- Shit reasonably cleaned
--		- Getting big enough that it might benefit splitting into a few files for clarity
--		Should we try and add support for mods to add new room variants?
--		- Done, I think
--		Need to ensure compatibility with alt path mod, waiting on team compliance version
--		- Compatible with Gamonymous version
--		- Need to recheck this, mod has changed since
--		Add language support for the modififed EID description
--		Generate a separate room for Cain's Birthright Arcade?

local CURSE_ID = 83
local START_TOP_ID = 84

local CENTER_POS = Vector(320.0, 280.0)
local STAIRCASE_POS = Vector(440.0 ,160.0)

local SACRIFICE_MIN = 12
local TELEPORT_LENGTH_DELAY = 5
local TELEPORT_LENGTH_ANIM = 20

local CAIN_ARCADE = 109

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

local SpecialRoom = {
	[RoomType.ROOM_ARCADE] = {variant = DoorVariant.KEY, string = "arcade"},
	[RoomType.ROOM_CHALLENGE] = {variant = DoorVariant.OPENED, string = "challenge"},
	[RoomType.ROOM_LIBRARY] = {variant = DoorVariant.KEY, string = "library"},
	[RoomType.ROOM_SACRIFICE] = {variant = DoorVariant.OPENED, string = "sacrifice"},
	[RoomType.ROOM_ISAACS] = {variant = DoorVariant.BOMB2, string = "isaacs"},
	[RoomType.ROOM_BARREN] = {variant = DoorVariant.BOMB2, string = "barren"},
	[RoomType.ROOM_CHEST] = {variant = DoorVariant.KEY2, string = "chest"},
	[RoomType.ROOM_DICE] = {variant = DoorVariant.KEY2, string = "dice"},
	[RoomType.ROOM_PLANETARIUM] = {variant = DoorVariant.KEY, string = "planetarium"},

	[CAIN_ARCADE] = {variant = DoorVariant.KEY, string = "arcade"},
}

local ShopSlotToRedRoom = {
	[DoorSlot.LEFT0] = 69,
	[DoorSlot.UP0] = 57,
	[DoorSlot.UP1] = 58,
	[DoorSlot.RIGHT0] = 72
}

mod.data = {
	run = {visitedPlanetarium = false},
	--config = {}
}

--this gets recalculated each floor and is only needed then, so whatever
mod.cainBirthright = false

mod.debug = false
mod.lastseed = 0

-- Vars for fake stage transition
mod.teleportIndex = 0
mod.teleportStartFrame = 0
mod.teleportEndFrame = 0
mod.paused = false

mod.savedrooms = {}
mod.roomsrequested = {
	curse = nil,
	redroom = {}
}
mod.roomsgenerated = {}

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

local function ValidateBool(var, default)
	if var ~= nil then return var end
	return default
end

function mod:LoadModData(continuedRun)
	debugPrint("loading mod data.. continue is "..tostring(continuedRun))
	local save = {}
	if mod:HasData() then
		debugPrint("data exists")
		save = json.decode(mod:LoadData())
	else
		debugPrint("creating data")
		save = {
			run = {visitedPlanetarium = false},
			--config = {}
		}
	end
	if not continuedRun then
		debugPrint("wiping run data")
		mod.data.run.visitedPlanetarium = false
	else
		local result = ValidateBool(save.run.visitedPlanetarium, false)
		debugPrint("ValidateBool returned "..tostring(result))
		mod.data.run.visitedPlanetarium = result
	end
	debugPrint("visitedPlanetarium: "..tostring(mod.data.run.visitedPlanetarium))
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


function mod.ResetTempVars()
	mod.paused = false
	mod.teleportIndex = 0
	mod.teleportStartFrame = 0
	mod.teleportEndFrame = 0
	mod:scheduleForUpdate(function()
		mod.savedrooms = {}
		mod.roomsgenerated = {}
	end, 0, ModCallbacks.MC_POST_UPDATE)
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

function mod:DoPlanetarium(level, levelStage, stageType, rng)
	Isaac.ExecuteCommand("goto s.planetarium." .. mod.GetRoomID(RoomType.ROOM_PLANETARIUM, rng))
	local gotor = level:GetRoomByIdx(-3,0)
	if gotor.Data then
		local oldChallenge = game.Challenge
		game.Challenge = Challenge.CHALLENGE_RED_REDEMPTION
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
		game.Challenge = oldChallenge
		level:SetStage(levelStage, stageType)
	else
		debugPrint("Planetarium gotor has no Data :(")
	end
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
	local newType = 0

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
		local planetariumChance = mod:GetCustomPlanetariumChance(level, stage, stageType)
		if PlanetariumChance then
			PlanetariumChance.storage.currentFloorSpawnChance = plaenetariumChance * 100
		end
		planetarium = (GreedSpecialRooms.Planetarium or (rng:RandomFloat() < planetariumChance))
		if planetarium then
			mod:DoPlanetarium(level, stage, stageType, rng)
		end
	end

	mod.roomchoice = GreedSpecialRooms.RoomChoice or mod:PickSpecialRoom(stage)
	if mod.roomchoice == RoomType.ROOM_ARCADE and mod.cainBirthright then
		newType = RoomType.ROOM_ARCADE + 100
	else
		newType = mod.roomchoice
	end
	debugPrint(newType)
	if mod.roomchoice > 0 then
		Isaac.ExecuteCommand("goto s." .. SpecialRoom[mod.roomchoice].string .. "." .. mod.GetRoomID(newType, rng))

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
	local level = game:GetLevel()
	if mod.lastseed ~= level:GetDungeonPlacementSeed() then
		mod:MovePlayersToPos(CENTER_POS)
	elseif level:GetCurrentRoomDesc().Data.Type == RoomType.ROOM_PLANETARIUM
	and level:GetCurrentRoomDesc().GridIndex > 0 then --we enter a planetarium in the process of spawning one
		debugPrint("we entered a planetarium")
		mod.data.run.visitedPlanetarium = true
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	local level = game:GetLevel()
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
				and gridEntity.VarData >= SACRIFICE_MIN -1 then
				debugPrint("rolling for teleport")
					if rng:RandomInt(2) == 0 then

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
	end
end, EntityType.ENTITY_PLAYER)

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
	mod.InitRooms()
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
		mod:SaveData(json.encode(mod.data))
	end
end)

if EID then
	local function HandleSacrificeRoomEID(descObj)
		if game:IsGreedMode()
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

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continue)
	mod:LoadModData(continue)
	mod.ResetTempVars()
	-----mod compatibility-----
	if PlanetariumChance and game:IsGreedMode() then
		PlanetariumChance.storage.canPlanetariumsSpawn = true
		--PlanetariumChance:updatePlanetariumChance()
	end
end)

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function(_, shouldSave)
	if not shouldSave then
		mod.data.run.visitedPlanetarium = false
	end
	mod:SaveData(json.encode(mod.data))
end)

mod:AddCallback(ModCallbacks.MC_POST_GAME_END, function()
	mod.ResetTempVars()
	mod.data.run.visitedPlanetarium = false
	mod:SaveData(json.encode(mod.data))
end)

mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
	if MMC and level:GetCurrentRoomDesc().Data.Type == RoomType.ROOM_CHALLENGE then
		MMC.Manager():Crossfade(Music.MUSIC_JINGLE_CHALLENGE_OUTRO)
		MMC.Manager():Queue(Music.MUSIC_BOSS_OVER)
	end
end)