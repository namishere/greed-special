GreedSpecialRooms = RegisterMod("Greed Mode Special Rooms", 1)
local mod = GreedSpecialRooms
local game = Game()

mod.rng = RNG()

Isaac.GetItemConfig():GetTrinket(TrinketType.TRINKET_TELESCOPE_LENS).Tags = Isaac.GetItemConfig():GetTrinket(TrinketType.TRINKET_TELESCOPE_LENS).Tags & ~ItemConfig.TAG_NO_GREED

local function shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = mod.rng:RandomInt(i)+1
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

local voodooHead = false
local cainBirthright = false
local roomSubType = 0

local function PickSpecialRoom(stage)
	print(game:GetRoom():GetShopLevel())
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

	roomSubType = 0

	for i = 0, game:GetNumPlayers() - 1 do
		local player = Isaac.GetPlayer(i)
		if allPlayersFullHealth and player:GetMaxHearts() > player:GetHearts() + player:GetSoulHearts() then --bone hearts ignored
			allPlayersFullHealth = false
		end

		redHeartCount = math.max(redHeartCount, player:GetHearts())
		soulHeartCount = math.max(soulHeartCount, player:GetSoulHearts())
	end

	if PlayerManager.AnyoneHasCollectible(CollectibleType.COLLECTIBLE_VOODOO_HEAD) then
		voodooHead = true
	end
	if PlayerManager.AnyPlayerTypeHasBirthright(PlayerType.PLAYER_CAIN) and mod.rng:RandomInt(2) == 0 then
		cainBirthright = true
	end

	allPlayersRedHeartsOnly = (soulHeartCount == 0)
	allPlayersSoulHeartsOnly = (redHeartCount == 0)

	--force roomtype
	if mod.RoomChoice and mod.RoomChoice > RoomType.ROOM_NULL then
		return mod.RoomChoice
	end

	-- Special Room
	if mod.rng:RandomInt(7) == 0 or (allPlayersFullHealth and mod.rng:RandomInt(4) == 0) then
		if mod.rng:RandomInt(50) == 0 or (keyCountTwoOrMore and mod.rng:RandomInt(5) == 0) then
			return RoomType.ROOM_DICE
		else
			return RoomType.ROOM_SACRIFICE
		end
	elseif mod.rng:RandomInt(20) == 0 then
		return RoomType.ROOM_LIBRARY
	elseif mod.rng:RandomInt(2) ~= 0 or (devilRoomVisited and mod.rng:RandomInt(4) ~= 0) then
		--if rng:RandomInt(4) == 0 or (stage == LevelStage.STAGE1_GREED and rng:RandomInt(4) == 0) then
			--return RoomType.ROOM_MINIBOSS
		if allPlayersFullHealth and stage > LevelStage.STAGE1_GREED and mod.rng:RandomInt(2) == 0 then
			if mod.rng:RandomInt(2) == 0 then -- eh
				roomSubType = RoomSubType.CHALLENGE_BOSS
			end
			return RoomType.ROOM_CHALLENGE
		else
			-- WOW the logic for arcades & vaults is a fucking headache
			if game:GetLevel():GetStage() % 2 == 0 then
				local vaultBaseChance = (mod.rng:RandomInt(10) == 0 or (keyCountTwoOrMore and mod.rng:RandomInt(3) == 0))
				if vaultBaseChance then
					if not coinCountFifteenOrMore or keyCountTwoOrMore then
						return RoomType.ROOM_CHEST
					end
				elseif coinCountFifteenOrMore and not cainBirthright then
					return RoomType.ROOM_ARCADE
				end
			end

			--Arcade/Vault logic can fall through without generating either
			if mod.rng:RandomInt(50) == 0
			or (((allPlayersRedHeartsOnly and redHeartCount < 4)
			or (allPlayersSoulHeartsOnly and soulHeartCount <= 4))
			and mod.rng:RandomInt(5) == 0) then
				if mod.rng:RandomInt(2) == 0 then
					return RoomType.ROOM_ISAACS
				else
					return RoomType.ROOM_BARREN
				end
			end
		end
	end

	if voodooHead then
		roomSubType = RoomSubType.CURSE_VOODOO_HEAD
		return RoomType.ROOM_CURSE
	end

	-- Default to Curse Room
	return 0
end

function mod.LevelPlaceRoom(lgr, rcr, seed)
	if game:IsGreedMode() and rcr.Type == RoomType.ROOM_CURSE and rcr.Subtype ~= RoomSubType.CURSE_VOODOO_HEAD then
		mod.rng:SetSeed(seed, 35)
		local replacement = PickSpecialRoom(game:GetLevel():GetStage())
		if replacement ~= 0 then
			return RoomConfigHolder.GetRandomRoom(seed, true, StbType.SPECIAL_ROOMS, replacement, rcr.Shape, nil, nil, nil, nil, rcr.Doors, roomSubType)
		end
	end
end

mod:AddCallback(ModCallbacks.MC_PRE_LEVEL_PLACE_ROOM, mod.LevelPlaceRoom)

local PossibleIndexes = {
	69,
	57,
	58,
	72, -- shop only
	85, -- shop only
	98, -- shop only
	99
}

function mod.GenerateExtraRooms()
	local level = game:GetLevel()
	if game:IsGreedMode() then
		mod.rng:SetSeed(game:GetSeeds():GetStageSeed(level:GetDungeonPlacementSeed()), 35)
		local roomConfig
		local shuffledIndexes
		if game:GetLevel():GetStage() < LevelStage.STAGE7_GREED then
			if voodooHead then
				roomConfig = RoomConfigHolder.GetRandomRoom(level:GetDungeonPlacementSeed(), true, StbType.SPECIAL_ROOMS, RoomType.ROOM_CURSE, nil, nil, nil, nil, nil, nil, RoomSubType.CURSE_VOODOO_HEAD)
				shuffledIndexes = shuffle(PossibleIndexes)
				for _, idx in ipairs(shuffledIndexes) do
					print("Trying to place Extra Curse at index: " .. idx)
					local room = level:TryPlaceRoom(roomConfig, idx, -1, level:GetDungeonPlacementSeed(), false, true, false)
					if room then
						print("Extra Curse placed at index: " .. idx)
						break
					end
				end
			end
			if cainBirthright then
				roomConfig = RoomConfigHolder.GetRandomRoom(level:GetDungeonPlacementSeed(), true, StbType.SPECIAL_ROOMS, RoomType.ROOM_ARCADE, nil, nil, nil, nil, nil, nil, RoomSubType.ARCADE_CAIN)
				shuffledIndexes = shuffle(PossibleIndexes)
				for _, idx in ipairs(shuffledIndexes) do
					print("Trying to place Cain Arcade at index: " .. idx)
					local room = level:TryPlaceRoom(roomConfig, idx, -1, level:GetDungeonPlacementSeed(), false, true, false)
					if room then
						print("Cain Arcade placed at index: " .. idx)
						break
					end
				end
			end
		end

		if mod.rng:RandomFloat() < game:GetLevel():GetPlanetariumChance() then
			roomConfig = RoomConfigHolder.GetRandomRoom(level:GetDungeonPlacementSeed(), true, StbType.SPECIAL_ROOMS, RoomType.ROOM_PLANETARIUM)
			shuffledIndexes = shuffle(PossibleIndexes)
			for _, idx in ipairs(shuffledIndexes) do
				print("Trying to place Planetarium at index: " .. idx)
				local room = level:TryPlaceRoom(roomConfig, idx, -1, level:GetDungeonPlacementSeed(), false, true, false)
				if room then
					print("Planetarium placed at index: " .. idx)
					break
				end
			end
		end
	end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.GenerateExtraRooms)

function mod.PlanetariumChanceCalculate()
	if game:IsGreedMode() then
		if ((not PlayerManager.AnyoneHasTrinket(TrinketType.TRINKET_TELESCOPE_LENS)) or game:GetLevel():GetStage() > LevelStage.STAGE6_GREED) and game:GetLevel():GetStage() > LevelStage.STAGE5_GREED then
			return 0.0
		end
	end
end

mod:AddCallback(ModCallbacks.MC_POST_PLANETARIUM_CALCULATE, mod.PlanetariumChanceCalculate)