GreedSpecialRooms = RegisterMod("Greed Mode Special Rooms", 1)
local mod = GreedSpecialRooms
local game = Game()

mod.rng = RNG()

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
		and mod.rng:RandomInt(2) == 0 then
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
	-- Default to Curse Room
	return 0
end

function mod.LevelPlaceRoom(lgr, rcr, seed)
	if game:IsGreedMode() and rcr.Type == RoomType.ROOM_CURSE then
		mod.rng:SetSeed(game:GetSeeds():GetStageSeed(game:GetLevel():GetAbsoluteStage()), 35)
		local replacement = PickSpecialRoom()
		if replacement ~= 0 then
			print("----------")
			print("lgr:")
			print(lgr)
			print(lgr.Type)
			print("rcr:")
			print(rcr)
			print(rcr.Type)
			print("seed:")
			print(seed)
			return RoomConfigHolder.GetRandomRoom(seed, false, StbType.SPECIAL_ROOMS, replacement, rcr.Shape)
		end
	end
end

mod:AddCallback(ModCallbacks.MC_PRE_LEVEL_PLACE_ROOM, mod.LevelPlaceRoom)
