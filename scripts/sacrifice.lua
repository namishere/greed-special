local mod = GreedSpecialRooms
local game = Game()

local SACRIFICE_MIN = 12
local TELEPORT_LENGTH_DELAY = 5
local TELEPORT_LENGTH_ANIM = 20

local teleportIndex = 0
local teleportStartFrame = 0
local teleportEndFrame = 0

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	if teleportIndex > 0 then
		if game:GetFrameCount() - teleportStartFrame == TELEPORT_LENGTH_DELAY * teleportIndex then
			mod.lib.debugPrint("teleporting teleportIndex #"..teleportIndex)
			local player = Isaac.GetPlayer(teleportIndex - 1)
			local playerRef = EntityRef(player)
			local playerCount = game:GetNumPlayers()
			player:AnimateTeleport(teleportIndex == 1)
			mod.lib.scheduleForUpdate(function()
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
			end, TELEPORT_LENGTH_ANIM -1, ModCallbacks.MC_POST_UPDATE)
			if teleportIndex < playerCount then
				teleportIndex = teleportIndex + 1
			end
		elseif game:GetFrameCount() == teleportEndFrame then
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

	local sacrificeMin = GreedSpecialRooms.SacrificeMin or SACRIFICE_MIN

	local level = game:GetLevel()
	local room = level:GetCurrentRoom()
	if game:IsGreedMode() and room:GetType() == RoomType.ROOM_SACRIFICE then
		if damageFlags == (DamageFlag.DAMAGE_SPIKES | DamageFlag.DAMAGE_NO_PENALTIES) then
			for i = 1, room:GetGridSize() do
				local gridEntity = room:GetGridEntity(i)
				if gridEntity and gridEntity:ToSpikes()
				and gridEntity.VarData >= sacrificeMin -1 then
				mod.lib.debugPrint("rolling for teleport")
					if mod.rng:RandomInt(2) == 0 then

						mod.lib.scheduleForUpdate(function()
							for i = 0, game:GetNumPlayers() - 1 do
								Isaac.GetPlayer().Velocity = Vector.Zero
							end
							mod:PauseGame(true)
							teleportStartFrame = game:GetFrameCount()
							teleportEndFrame = teleportStartFrame + (TELEPORT_LENGTH_DELAY * game:GetNumPlayers()) + TELEPORT_LENGTH_ANIM
							teleportIndex = 1
							mod.lib.debugPrint("player count is "..game:GetNumPlayers()..". let's get started...")
						end, 0, ModCallbacks.MC_POST_UPDATE)
					end
				end
			end
		end
	end
end, EntityType.ENTITY_PLAYER)

mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
	if game:IsGreedMode() and mod.paused then
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
		mod.paused = false
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
	teleportIndex = 0
	teleportStartFrame = 0
	teleportEndFrame = 0
end)
