local TargetingHelper = require('TargetingHelper')
local AIControl = require('AIControl')

registerHotkey('SelectNPC', 'Mark / Unmark NPC', function()
	local target = TargetingHelper.GetLookAtTarget()

	if target and target:IsNPC() then
		if TargetingHelper.IsTargetMarked(target) then
			TargetingHelper.UnmarkTarget(target)
		else
			TargetingHelper.MarkTarget(target)
		end
	end
end)

registerHotkey('MoveMarkedNPC', 'Send marked NPCs to palyer', function()
	local targets = TargetingHelper.GetMarkedTargets()
	local movePosition = TargetingHelper.GetLookAtPosition()

	if #targets == 0 or not movePosition then
		return
	end

	local player = Game.GetPlayer()
	local moveOffsetX, moveOffsetY = 0, 0.5

	for _, target in pairs(targets) do
		-- Make NPC react faster to the next command
		-- before the first command is in the chain
		if not AIControl.HasQueue(target) then
			AIControl.InterruptBehavior(target)
		end

		-- Clone position for closures
		local pinPosition = ToVector4(movePosition)

		-- Place a pin that would be removed when task is completed
		TargetingHelper.MarkPosition(pinPosition)

		-- Move to the position while looking at the player
		AIControl.QueueTask(target, function()
			AIControl.LookAt(target, player)

			return AIControl.MoveTo(target, movePosition)
		end)

		-- Rotate to the player on arrival
		AIControl.QueueTask(target, function()
			TargetingHelper.UnmarkPosition(pinPosition)

			return AIControl.RotateTo(target, player:GetWorldPosition())
		end)

		-- Stay for a sec after reaching a position
		AIControl.QueueTask(target, function()
			return AIControl.HoldFor(target, 1.0)
		end)

		-- Stop looking at the player
		AIControl.QueueTask(target, function()
			AIControl.StopLookAt(target)
		end)

		-- Give next NPC some space
		movePosition.x = movePosition.x + moveOffsetX
		movePosition.y = movePosition.y + moveOffsetY

		moveOffsetX, moveOffsetY = moveOffsetY, moveOffsetX
	end
end)

registerHotkey('TeleportMarkedNPC', 'Teleport marked NPCs to palyer', function()
	local targets = TargetingHelper.GetMarkedTargets()
	local teleportPosition = TargetingHelper.GetLookAtPosition()

	if #targets == 0 or not teleportPosition then
		return
	end

	local teleportOffsetX, teleportOffsetY = 0, 0.5

	for _, target in pairs(targets) do
		AIControl.TeleportTo(target, teleportPosition)
		AIControl.HoldFor(target, 3.0) -- Stay for 3 secs after teleport

		-- Give next NPC some space
		teleportPosition.x = teleportPosition.x + teleportOffsetX
		teleportPosition.y = teleportPosition.y + teleportOffsetY

		teleportOffsetX, teleportOffsetY = teleportOffsetY, teleportOffsetX
	end
end)

registerHotkey('RecruitFollower', 'Recruit follower', function()
	local target = TargetingHelper.GetLookAtTarget()

	if target and target:IsNPC() then
		AIControl.InterruptCombat(target)
		AIControl.MakeFollower(target)
	end
end)

registerHotkey('RecruitEveryone', 'Recruit everyone', function()
	local targets = TargetingHelper.GetLookAtTargets()

	for _, target in pairs(targets) do
		AIControl.InterruptCombat(target)
		AIControl.MakeFollower(target)
	end
end)

registerHotkey('StartMassacre', 'Start massacre', function()
	local targets = TargetingHelper.GetLookAtTargets()

	for _, target in pairs(targets) do
		AIControl.MakePsycho(target)
	end
end)

registerForEvent('onInit', function()
	-- Free follower when NPC is detached
	Observe('ScriptedPuppet', 'OnDetach', function(self)
		if self and self:IsA('NPCPuppet') then
			TargetingHelper.UnmarkTarget(self)
			AIControl.FreeFollower(self)
		end
	end)

	-- Maintain the correct state on session end
	Observe('RadialWheelController', 'RegisterBlackboards', function(_, loaded)
		if not loaded then
			TargetingHelper.Dispose()
			AIControl.Dispose()
		end
	end)
end)

-- Maintain the correct state on "Reload All Mods"
registerForEvent('onShutdown', function()
	TargetingHelper.Dispose()
	AIControl.Dispose()
end)

registerForEvent('onUpdate', function(delta)
	AIControl.UpdateTasks(delta)
end)
