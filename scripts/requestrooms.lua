local mod = GreedSpecialRooms
local game = Game()
local rng = mod.rng

--the var names in here are tied to stringToType in getroomdata
--TODO: this scheme doesn't really make sense. turn the values into
--		a table formatted {type = RoomType, string = [string used by goto]
mod.roomsrequested = {
	curse = RoomType.ROOM_NULL,
	redRoom = {
		[70] = {
			planetarium = RoomType.ROOM_NULL,
			cainArcade = RoomType.ROOM_NULL,
			extraCurse = RoomType.ROOM_NULL
		},
		[110] = {
			secretExit = RoomType.ROOM_NULL
		}
	}
}

mod.data = {
	run = { visitedPlanetarium = false }
}

local cainBirthright = false
local voodooHead = false

local function PickSpecialRoom(stage)
	--TODO: convert into flag system
	local allPlayersFullHealth = true
	local allPlayersRedHeartsOnly = true
	local allPlayersSoulHeartsOnly = true

	local redHeartCount = 0
	local soulHeartCount = 0
	local keyCountTwoOrMore = (Isaac.GetPlayer():GetNumKeys() >= 2)
	local coinCountFifteenOrMore = (Isaac.GetPlayer():GetNumCoins() >= 15)

	local devilRoomVisited = game:GetStateFlag(GameStateFlag.STATE_DEVILROOM_VISITED)
	voodooHead = false
	cainBirthright = false

	for i = 0, game:GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		if allPlayersFullHealth and player:GetMaxHearts() > player:GetHearts() + player:GetSoulHearts() then --bone hearts ignored
			allPlayersFullHealth = false
		end

		redHeartCount = math.max(redHeartCount, player:GetHearts())
		soulHeartCount = math.max(soulHeartCount, player:GetSoulHearts())

		if player:GetPlayerType() == PlayerType.PLAYER_CAIN and player:GetCollectibleNum(CollectibleType.COLLECTIBLE_BIRTHRIGHT) > 0
		and rng:RandomInt(2) == 0 then
			cainBirthright = true
		end

		if player:GetCollectibleNum(CollectibleType.COLLECTIBLE_VOODOO_HEAD) > 0 then
			voodooHead = true
		end
	end

	allPlayersRedHeartsOnly = (soulHeartCount == 0)
	allPlayersSoulHeartsOnly = (redHeartCount == 0)

	--force roomtype
	if mod.RoomChoice and mod.RoomChoice > RoomType.ROOM_NULL then
		return mod.RoomChoice
	end

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
				elseif coinCountFifteenOrMore and not cainBirthright then
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

local function GetCustomPlanetariumChance(baseChance, stage, stageType)
	local planetariumBonus = 0
	local stageOffset = -1
	--If not Alt Path then reduce by 1. For mods where Greed Downpour is a second floor.
	if stageType >= StageType.STAGETYPE_REPENTANCE then
		stageOffset = 0
	end
	stage = stage + stageOffset

	if game:GetTreasureRoomVisitCount() < stage*2
	and not(mod.data.run.visitedPlanetarium or baseChance >= 1 ) then
		--To apply multiple bonus if many Treasure Rooms are skipped and unaccounted for.
		planetariumBonus = 0.2 * math.ceil((stage*2-game:GetTreasureRoomVisitCount())/2)
		--Skipping one treasure on Basement and one in Caves should add up to 40% but actually adds up to 20% with this formula, this extra bit helps with that.
		if stage >= 2 and game:GetTreasureRoomVisitCount()/(stage*2) <= 0.5 and baseChance < 0.2 then
			planetariumBonus = planetariumBonus + 0.2
			--If someone wanted to skip one treasure room for 4 floors (until Sheol) it'd be inaccurate again but seems excessive

			--if stage = 4 then
			--	planetariumBonus = planetariumBonus + 0.2
			--end

		end
	end

--[[
	mod.lib.debugPrint("Stage used for calc: "..stage)
	mod.lib.debugPrint("Tresure Rooms Visited: "..game:GetTreasureRoomVisitCount())
	mod.lib.debugPrint("Planetarium Visited: "..tostring(mod.data.run.visitedPlanetarium))
	mod.lib.debugPrint("Natural Planetarium Chance: "..string.format("%.2f", baseChance))
	mod.lib.debugPrint("Bonus Planetarium Chance: "..string.format("%.2f",planetariumBonus))
	mod.lib.debugPrint("Full Planetarium Chance: "..string.format("%.2f", math.min(1, baseChance + planetariumBonus)))
]]--

	return math.min(1, baseChance + planetariumBonus)
end

--making this a function in case extra conditions are added later
local function GetCainArcade()
	if cainBirthright then
		return mod.enum.CAIN_ARCADE
	end
	return RoomType.ROOM_NULL
end

--same here
local function GetExtraCurseRoom()
	if voodooHead then
		return mod.enum.VOODOO_CURSE
	end
	return RoomType.ROOM_NULL
end

function mod.GetRoomRequests()
	local curseReplacement = RoomType.ROOM_NULL
	local rollPlanetarium = RoomType.ROOM_NULL
	local rollCainArcade = RoomType.ROOM_NULL
	local rollVoodooHead = RoomType.ROOM_NULL

	local level = game:GetLevel()
	local stage = game:GetLevel():GetStage()
	local stageType = level:GetStageType()

	local planetariumChance = GetCustomPlanetariumChance(level:GetPlanetariumChance(), stage, stageType)

	curseReplacement = GreedSpecialRooms.Room or PickSpecialRoom(stage, rollCainArcade)
	rollCainArcade = GetCainArcade()
	rollVoodooHead = GetExtraCurseRoom()

	if not gplan then
		if PlanetariumChance then
			PlanetariumChance.storage.canPlanetariumsSpawn = true
			PlanetariumChance.storage.currentFloorSpawnChance = planetariumChance * 100
		end

		if GreedSpecialRooms.Planetarium or rng:RandomFloat() < planetariumChance then
			rollPlanetarium = RoomType.ROOM_PLANETARIUM
		end
	end

	mod.roomsrequested = {
		curse = curseReplacement,
		redRoom = {
			[mod.enum.SHOP_IDX] = {
				planetarium = rollPlanetarium,
				cainArcade = rollCainArcade,
				extraCurse = rollVoodooHead
			},
			[mod.enum.EXIT_IDX] = {
				secretExit = RoomType.ROOM_NULL
			}
		}
	}

	mod.lib.debugPrint("curse = "..mod.roomsrequested.curse)
	mod.lib.debugPrint(dump(mod.roomsrequested.redRoom))
end
