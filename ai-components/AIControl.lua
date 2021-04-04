local TargetingHelper = require('TargetingHelper')

local AIControl = {}

local followers = {}
local followTimer = 0.0
local followInterval = 5.0

function AIControl.MakeFriendly(targetPuppet, friendPuppet)
	if not friendPuppet then
		friendPuppet = Game.GetPlayer()
	end

	-- Set NPC attitude to friendly
	targetPuppet:GetAttitudeAgent():SetAttitudeGroup(friendPuppet:GetAttitudeAgent():GetAttitudeGroup())
	targetPuppet:GetAttitudeAgent():SetAttitudeTowards(friendPuppet:GetAttitudeAgent(), 'AIA_Friendly')
end

function AIControl.MakeNeutral(targetPuppet, friendPuppet)
	if not friendPuppet then
		friendPuppet = Game.GetPlayer()
	end

	-- Restore NPC original group
	targetPuppet:GetAttitudeAgent():SetAttitudeGroup(targetPuppet:GetRecord():BaseAttitudeGroup())
	targetPuppet:GetAttitudeAgent():SetAttitudeTowards(friendPuppet:GetAttitudeAgent(), 'AIA_Neutral')
end

function AIControl.MakePsycho(targetPuppet, friendPuppet)
	if not friendPuppet then
		friendPuppet = Game.GetPlayer()
	end

	targetPuppet:GetAttitudeAgent():SetAttitudeGroup('HostileToEveryone')
	targetPuppet:GetAttitudeAgent():SetAttitudeTowards(friendPuppet:GetAttitudeAgent(), 'AIA_Neutral')
end

function AIControl.IsFollower(targetPuppet)
	local currentRole = targetPuppet:GetAIControllerComponent():GetAIRole()

	return currentRole and currentRole:IsA('AIFollowerRole')
end

function AIControl.MakeFollower(targetPuppet, movementType)
	local currentRole = targetPuppet:GetAIControllerComponent():GetAIRole()

	if currentRole then
		currentRole:OnRoleCleared(targetPuppet)
	end

	local followerRole = NewObject('handle:AIFollowerRole')
	followerRole.followerRef = Game.CreateEntityReference('#player', {})

	targetPuppet:GetAIControllerComponent():SetAIRole(followerRole)
	targetPuppet:GetAIControllerComponent():OnAttach()

	targetPuppet:GetMovePolicesComponent():ChangeMovementType(movementType or 'Sprint')

	AIControl.MakeFriendly(targetPuppet)

	for _, followerPuppet in pairs(followers) do
		followerPuppet:GetAttitudeAgent():SetAttitudeTowards(targetPuppet:GetAttitudeAgent(), 'AIA_Friendly')
	end

	targetPuppet.isPlayerCompanionCachedTimeStamp = 0

	followers[TargetingHelper.GetTargetId(targetPuppet)] = targetPuppet
end

function AIControl.FreeFollower(targetPuppet)
	if targetPuppet:IsAttached() then
		local currentRole = targetPuppet:GetAIControllerComponent():GetAIRole()

		if currentRole and currentRole:IsA('AIFollowerRole') then
			currentRole:OnRoleCleared(targetPuppet)

			local noRole = NewObject('handle:AINoRole')

			targetPuppet:GetAIControllerComponent():SetAIRole(noRole)
			targetPuppet:GetAIControllerComponent():OnAttach()

			AIControl.MakeNeutral(targetPuppet)

			-- Restore sense preset
			local sensePreset = targetPuppet:GetRecord():SensePreset():GetID()
			Game['senseComponent::RequestPresetChange;GameObjectTweakDBIDBool'](targetPuppet, sensePreset, true)
		end
	end

	followers[TargetingHelper.GetTargetId(targetPuppet)] = nil
end

function AIControl.FreeFollowers()
	for _, follower in pairs(followers) do
		AIControl.FreeFollower(follower)
	end
end

function AIControl.InterruptCombat(targetPuppet)
	-- Clear threats in case NPC is aggroed
	targetPuppet:GetTargetTrackerComponent():ClearThreats()

	-- Reset NPC state to relaxed
	Game['NPCPuppet::ChangeHighLevelState;GameObjectgamedataNPCHighLevelState'](targetPuppet, 'Relaxed')
	Game['NPCPuppet::ChangeDefenseModeState;GameObjectgamedataDefenseMode'](targetPuppet, 'NoDefend')
	Game['NPCPuppet::ChangeUpperBodyState;GameObjectgamedataNPCUpperBodyState'](targetPuppet, 'Normal')
	Game['NPCPuppet::ChangeStanceState;GameObjectgamedataNPCStanceState'](targetPuppet, 'Relaxed')
end

function AIControl.TeleportTo(targetPuppet, targetPosition, targetRotation)
    local teleportCmd = NewObject('handle:AITeleportCommand')
    teleportCmd.position = targetPosition
    teleportCmd.rotation = targetRotation or 0.0
    teleportCmd.doNavTest = false

    targetPuppet:GetAIControllerComponent():SendCommand(teleportCmd)
end

function AIControl.MoveTo(targetPuppet, targetPosition, targetDistance, movementType)
	if not targetPosition then
		targetPosition = Game.GetPlayer():GetWorldPosition()
	end

	if not targetDistance then
		targetDistance = 1.0
	end

	if not movementType then
		movementType = 'Sprint'
	end

    local worldPosition = NewObject('WorldPosition')
    GetSingleton('WorldPosition'):SetVector4(worldPosition, targetPosition)

    local positionSpec = NewObject('AIPositionSpec')
    GetSingleton('AIPositionSpec'):SetWorldPosition(positionSpec, worldPosition)

    local moveCmd = NewObject('handle:AIMoveToCommand')
    moveCmd.movementTarget = positionSpec
    moveCmd.movementType = movementType
    moveCmd.finishWhenDestinationReached = true
    moveCmd.desiredDistanceFromTarget = targetDistance
    moveCmd.ignoreNavigation = true

    targetPuppet:GetAIControllerComponent():SendCommand(moveCmd)
end

function AIControl.HoldFor(targetPuppet, duration)
    local holdCmd = NewObject('handle:AIHoldPositionCommand')
    holdCmd.duration = duration or 1.0
	holdCmd.ignoreInCombat = false
	holdCmd.removeAfterCombat = false
	holdCmd.alwaysUseStealth = false

    targetPuppet:GetAIControllerComponent():SendCommand(holdCmd)
end

function AIControl.FollowTarget(targetPuppet, followPuppet, movementType)
	if not followPuppet then
		local currentRole = targetPuppet:GetAIControllerComponent():GetAIRole()

		if currentRole or currentRole:IsA('AIFollowerRole') then
			followPuppet = currentRole.followTarget
		else
			followPuppet = Game.GetPlayer()
		end
	end

	if not movementType then
		movementType = 'Sprint'
	end

    local followCmd = NewObject('handle:AIFollowTargetCommand')
    followCmd.target = followPuppet
	followCmd.lookAtTarget = followPuppet
	followCmd.desiredDistance = 1.0
	followCmd.tolerance = 0.5
	followCmd.movementType = movementType
	followCmd.matchSpeed = true
	followCmd.teleport = true
	followCmd.stopWhenDestinationReached = false
	followCmd.ignoreInCombat = false
	followCmd.removeAfterCombat = false
	followCmd.alwaysUseStealth = false

    targetPuppet:GetAIControllerComponent():SendCommand(followCmd)
end

function AIControl.ResetBehavior(targetPuppet)
	local orientation = GetSingleton('Quaternion'):ToEulerAngles(targetPuppet:GetWorldTransform().Orientation)

	AIControl.TeleportTo(targetPuppet, targetPuppet:GetWorldPosition(), orientation.roll)
end

function AIControl.UpdateTasks(delta)
	followTimer = followTimer + delta

	if followTimer >= followInterval then
		-- This forces the NPC to follow the player a further outside the NPC's area
		for _, follower in pairs(followers) do
			if TargetingHelper.IsActive(follower) then
				AIControl.FollowTarget(follower)
			else
				AIControl.FreeFollower(follower)
			end
		end

		followTimer = followTimer - followInterval
	end
end

return AIControl