local mod = GreedSpecialRooms
local game = Game()

local START_TOP_ID = 84

local CENTER_POS = Vector(320.0, 280.0)
local STAIRCASE_POS = Vector(440.0 ,160.0)

local function MovePlayersToPos(position)
	Isaac.GetPlayer().Position = position
	if game:GetNumPlayers() > 1 then
		for i = 1, game:GetNumPlayers() - 1 do
			Isaac.GetPlayer(i).Position = Isaac.GetFreeNearPosition(position, 1)
		end
	end
end

local function UpdateRoomDisplayFlags(initroomdesc)
	mod.lib.debugPrint("UpdateRoomDisplayFlags")
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

function mod.DoStageTransition()
	mod.lib.debugPrint("DoStageTransition")
	if mod.dotransition then
		mod.lib.scheduleForUpdate(function()
			mod.lib.debugPrint("Render")
			local uLevel = game:GetLevel()
			game:StartRoomTransition(START_TOP_ID, Direction.DOWN, RoomTransitionAnim.MAZE)
			if mod.hasStairway then
				Isaac.Spawn(1000, 156, 1, STAIRCASE_POS, Vector.Zero, nil)
			end

			if #mod.roomsupdated > 0 then
				for i=1, #mod.roomsupdated do
					local roomDesc = uLevel:GetRoomByIdx(mod.roomsupdated[i])
					roomDesc.VisitedCount = 0
					UpdateRoomDisplayFlags(roomDesc)
				end
			end

			mod.lib.debugPrint("Calling Update(), pray...")
			uLevel:Update()
			--uLevel:UpdateVisibility()
		end, 0, ModCallbacks.MC_POST_RENDER)
		mod.lib.scheduleForUpdate(function()
			mod.lib.debugPrint("Update")
			local uLevel = game:GetLevel()
			if mod.hasStairway then
				Isaac.Spawn(1000, 156, 1, STAIRCASE_POS, Vector.Zero, nil)
			end
			if mod.hasCurseOfTheMaze then
				uLevel:AddCurse(LevelCurse.CURSE_OF_MAZE, true)
			end

			uLevel:UpdateVisibility()
		end, 0, ModCallbacks.MC_POST_UPDATE)
		mod.dotransition = false
	end
end

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
	if mod.lastseed ~= game:GetLevel():GetDungeonPlacementSeed() then
		MovePlayersToPos(CENTER_POS)
	end
end)

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
	mod.lastseed = game:GetLevel():GetDungeonPlacementSeed()
end)
