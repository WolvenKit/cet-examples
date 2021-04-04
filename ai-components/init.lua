local AIControl = require('AIControl')
local TargetingHelper = require('TargetingHelper')

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
	local player = Game.GetPlayer()
	local targets = TargetingHelper.GetMarkedTargets()

	local playerForward = player:GetWorldForward()
	local playerPosition = player:GetWorldPosition()

	local movePosition = Vector4.new(
		playerPosition.x + playerForward.x * 2,
		playerPosition.y + playerForward.y * 2,
		playerPosition.z,
		playerPosition.w
	)

	for _, target in pairs(targets) do
		AIControl.ResetBehavior(target) -- Make NPC react faster to the next command
		AIControl.MoveTo(target, movePosition)
	end
end)

registerHotkey('TeleportMarkedNPC', 'Teleport marked NPCs to palyer', function()
	local player = Game.GetPlayer()
	local targets = TargetingHelper.GetMarkedTargets()

	local playerForward = player:GetWorldForward()
	local playerPosition = player:GetWorldPosition()

	local teleportOffsetX, teleportOffsetY = 0, 0.5
	local teleportPosition = Vector4.new(
		playerPosition.x + playerForward.x * 3,
		playerPosition.y + playerForward.y * 3,
		playerPosition.z,
		playerPosition.w
	)

	for _, target in pairs(targets) do
		-- Give NPSs some space
		teleportPosition.x = teleportPosition.x + teleportOffsetX
		teleportPosition.y = teleportPosition.y + teleportOffsetY

		AIControl.TeleportTo(target, teleportPosition)
		AIControl.HoldFor(target, 5.0) -- Stay for 5 secs after teleport

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
			AIControl.FreeFollower(self)
			TargetingHelper.UnmarkTarget(self)
		end
	end)

	-- Maintain the correct state on session end
	Observe('RadialWheelController', 'RegisterBlackboards', function(_, loaded)
		if not loaded then
			AIControl.FreeFollowers()
			TargetingHelper.UnmarkAll()
		end
	end)
end)

-- Maintain the correct state on "Reload All Mods"
registerForEvent('onShutdown', function()
	AIControl.FreeFollowers()
	TargetingHelper.UnmarkAll()
end)

registerForEvent('onUpdate', function(delta)
	AIControl.UpdateTasks(delta)
end)