local TargetingHelper = require('TargetingHelper')

local AIControl = {}

local followers = {}
local followTimer = 0.0
local followInterval = 5.0

local queues = {}
local queueTimer = 0.0
local queueInterval = 0.02

---@param targetPosition Vector4
---@return AIPositionSpec
local function ToPositionSpec(targetPosition)
	local worldPosition = WorldPosition.new()
	worldPosition:SetVector4(targetPosition)

	local positionSpec = AIPositionSpec.new()
	positionSpec:SetWorldPosition(worldPosition)

	return positionSpec
end

---@param targetPuppet ScriptedPuppet
---@param friendPuppet ScriptedPuppet
function AIControl.MakeFriendly(targetPuppet, friendPuppet)
	if not friendPuppet then
		friendPuppet = Game.GetPlayer()
	end

	-- Set NPC attitude to friendly
	targetPuppet:GetAttitudeAgent():SetAttitudeGroup(friendPuppet:GetAttitudeAgent():GetAttitudeGroup())
	targetPuppet:GetAttitudeAgent():SetAttitudeTowards(friendPuppet:GetAttitudeAgent(), EAIAttitude.AIA_Friendly)
end

---@param targetPuppet ScriptedPuppet
---@param friendPuppet ScriptedPuppet
function AIControl.MakeNeutral(targetPuppet, friendPuppet)
	if not friendPuppet then
		friendPuppet = Game.GetPlayer()
	end

	-- Restore NPC original group
	targetPuppet:GetAttitudeAgent():SetAttitudeGroup(targetPuppet:GetRecord():BaseAttitudeGroup())
	targetPuppet:GetAttitudeAgent():SetAttitudeTowards(friendPuppet:GetAttitudeAgent(), EAIAttitude.AIA_Neutral)
end

---@param targetPuppet ScriptedPuppet
---@param friendPuppet ScriptedPuppet
function AIControl.MakePsycho(targetPuppet, friendPuppet)
	if not friendPuppet then
		friendPuppet = Game.GetPlayer()
	end

	targetPuppet:GetAttitudeAgent():SetAttitudeGroup('HostileToEveryone')
	targetPuppet:GetAttitudeAgent():SetAttitudeTowards(friendPuppet:GetAttitudeAgent(), EAIAttitude.AIA_Neutral)
end

---@param targetPuppet ScriptedPuppet
---@return boolean
function AIControl.IsFollower(targetPuppet)
	local currentRole = targetPuppet:GetAIControllerComponent():GetAIRole()

	return currentRole and currentRole:IsA('AIFollowerRole')
end

---@param targetPuppet ScriptedPuppet
---@param movementType moveMovementType
---@return boolean
function AIControl.MakeFollower(targetPuppet, movementType)
	if not targetPuppet:IsAttached() then
		return false
	end

	local currentRole = targetPuppet:GetAIControllerComponent():GetAIRole()

	if currentRole then
		if targetPuppet:IsCrowd() and currentRole:IsA('AIFollowerRole') then
			return true
		end

		currentRole:OnRoleCleared(targetPuppet)
	end

	local followerRole = AIFollowerRole.new()
	followerRole.followerRef = Game.CreateEntityReference('#player', {})

	targetPuppet:GetAIControllerComponent():SetAIRole(followerRole)
	targetPuppet:GetAIControllerComponent():OnAttach()

	targetPuppet:GetMovePolicesComponent():ChangeMovementType(movementType or moveMovementType.Sprint)

	AIControl.MakeFriendly(targetPuppet)

	for _, followerPuppet in pairs(followers) do
		followerPuppet:GetAttitudeAgent():SetAttitudeTowards(targetPuppet:GetAttitudeAgent(), EAIAttitude.AIA_Friendly)
	end

	targetPuppet.isPlayerCompanionCachedTimeStamp = 0

	followers[TargetingHelper.GetTargetId(targetPuppet)] = targetPuppet

	return true
end

---@param targetPuppet ScriptedPuppet
---@return boolean
function AIControl.FreeFollower(targetPuppet)
	if targetPuppet:IsAttached() then
		local currentRole = targetPuppet:GetAIControllerComponent():GetAIRole()

		if currentRole and currentRole:IsA('AIFollowerRole') then
			if targetPuppet:IsCrowd() then
				targetPuppet:Dispose() -- Can't change roles more than once on crowd npc
			else
				currentRole:OnRoleCleared(targetPuppet)

				local noRole = AINoRole.new()

				targetPuppet:GetAIControllerComponent():SetAIRole(noRole)
				targetPuppet:GetAIControllerComponent():OnAttach()

				AIControl.MakeNeutral(targetPuppet)

				-- Restore sense preset
				local sensePreset = targetPuppet:GetRecord():SensePreset():GetID()
				SenseComponent.RequestPresetChange(targetPuppet, sensePreset, true)
			end
		end
	end

	followers[TargetingHelper.GetTargetId(targetPuppet)] = nil

	return true
end

function AIControl.FreeFollowers()
	for _, follower in pairs(followers) do
		AIControl.FreeFollower(follower)
	end
end

---@param targetPuppet ScriptedPuppet
function AIControl.InterruptCombat(targetPuppet)
	-- Clear threats in case NPC is aggroed
	targetPuppet:GetTargetTrackerComponent():ClearThreats()

	-- Reset NPC state to relaxed
	NPCPuppet.ChangeHighLevelState(targetPuppet, gamedataNPCHighLevelState.Relaxed)
	NPCPuppet.ChangeDefenseModeState(targetPuppet, gamedataDefenseMode.NoDefend)
	NPCPuppet.ChangeUpperBodyState(targetPuppet, gamedataNPCUpperBodyState.Normal)
end

---@param targetPuppet ScriptedPuppet
---@param lookAtPuppet ScriptedPuppet
---@param duration Float|nil
function AIControl.LookAt(targetPuppet, lookAtPuppet, duration)
	if not lookAtPuppet then
		lookAtPuppet = Game.GetPlayer()
	end

	targetPuppet:GetStimReactionComponent():ActivateReactionLookAt(lookAtPuppet, duration and true or false, false, duration, true)
end

---@param targetPuppet ScriptedPuppet
function AIControl.StopLookAt(targetPuppet)
	targetPuppet:GetStimReactionComponent():DeactiveLookAt(false)
end

---@param targetPuppet ScriptedPuppet
---@param targetPosition Vector4
---@return AIRotateToCommand
function AIControl.RotateTo(targetPuppet, targetPosition)
	local positionSpec = ToPositionSpec(targetPosition)

	local rotateCmd = AIRotateToCommand.new()
	rotateCmd.target = positionSpec
	rotateCmd.angleTolerance = 5.0 -- If zero then command will never finish
	rotateCmd.angleOffset = 0.0
	rotateCmd.speed = 1.0

	targetPuppet:GetAIControllerComponent():SendCommand(rotateCmd)

	return rotateCmd, targetPuppet
end

---@param targetPuppet ScriptedPuppet
---@param targetPosition Vector4
---@param targetRotation Float
---@return AITeleportCommand
function AIControl.TeleportTo(targetPuppet, targetPosition, targetRotation)
	if not targetRotation then
		targetRotation = targetPuppet:GetWorldYaw()
	end

	local teleportCmd = AITeleportCommand.new()
	teleportCmd.position = targetPosition
	teleportCmd.rotation = targetRotation
	teleportCmd.doNavTest = false

	targetPuppet:GetAIControllerComponent():SendCommand(teleportCmd)

	return teleportCmd, targetPuppet
end

---@param targetPuppet ScriptedPuppet
---@param targetPosition Vector4
---@param targetDistance Float
---@param movementType moveMovementType
---@return AIMoveToCommand
function AIControl.MoveTo(targetPuppet, targetPosition, targetDistance, movementType)
	if not targetPosition then
		targetPosition = Game.GetPlayer():GetWorldPosition()
	end

	if not targetDistance then
		targetDistance = 1.0
	end

	if not movementType then
		movementType = moveMovementType.Run
	end

	local positionSpec = ToPositionSpec(targetPosition)

	local moveCmd = AIMoveToCommand.new()
	moveCmd.movementTarget = positionSpec
	moveCmd.movementType = movementType
	moveCmd.desiredDistanceFromTarget = targetDistance
	moveCmd.finishWhenDestinationReached = true
	moveCmd.ignoreNavigation = true
	moveCmd.useStart = true
	moveCmd.useStop = false

	targetPuppet:GetAIControllerComponent():SendCommand(moveCmd)

	return moveCmd, targetPuppet
end

---@param targetPuppet ScriptedPuppet
---@param duration Float|nil
---@return AIHoldPositionCommand
function AIControl.HoldFor(targetPuppet, duration)
	local holdCmd = AIHoldPositionCommand.new()
	holdCmd.duration = duration or 1.0
	holdCmd.ignoreInCombat = false
	holdCmd.removeAfterCombat = false
	holdCmd.alwaysUseStealth = false

	targetPuppet:GetAIControllerComponent():SendCommand(holdCmd)

	return holdCmd, targetPuppet
end

---@param targetPuppet ScriptedPuppet
---@param followPuppet ScriptedPuppet
---@param movementType moveMovementType
---@return AIFollowTargetCommand
function AIControl.FollowTarget(targetPuppet, followPuppet, movementType)
	if not followPuppet then
		---@type AIFollowerRole
		local currentRole = targetPuppet:GetAIControllerComponent():GetAIRole()

		if currentRole and currentRole:IsA('AIFollowerRole') then
			followPuppet = currentRole.followTarget
		else
			followPuppet = Game.GetPlayer()
		end
	end

	if not movementType then
		movementType = moveMovementType.Sprint
	end

	local followCmd = AIFollowTargetCommand.new()
	followCmd.target = followPuppet
	followCmd.lookAtTarget = followPuppet
	followCmd.desiredDistance = 1.0
	followCmd.tolerance = 0.5
	followCmd.movementType = movementType
	followCmd.matchSpeed = true
	followCmd.teleport = false
	followCmd.stopWhenDestinationReached = false
	followCmd.ignoreInCombat = false
	followCmd.removeAfterCombat = false
	followCmd.alwaysUseStealth = false

	targetPuppet:GetAIControllerComponent():SendCommand(followCmd)

	return followCmd, targetPuppet
end

---@param targetPuppet ScriptedPuppet
---@return AITeleportCommand
function AIControl.InterruptBehavior(targetPuppet)
	return AIControl.TeleportTo(targetPuppet, targetPuppet:GetWorldPosition())
end

---@param targetPuppet ScriptedPuppet
---@param commandInstance AICommand
---@return boolean
function AIControl.IsCommandActive(targetPuppet, commandInstance)
	return AIbehaviorUniqueActiveCommandList.IsActionCommandById(
		targetPuppet:GetAIControllerComponent().activeCommands,
		commandInstance.id
	)
end

---@param targetPuppet ScriptedPuppet
---@return boolean
function AIControl.HasQueue(targetPuppet)
	return queues[TargetingHelper.GetTargetId(targetPuppet)] ~= nil
end

---@param targetPuppet ScriptedPuppet
---@param commandTask function Task function must return a command instance
function AIControl.QueueTask(targetPuppet, commandTask)
	local targetId = TargetingHelper.GetTargetId(targetPuppet)

	local queue = queues[targetId]

	if not queue then
		queue = {
			target = targetPuppet,
			tasks = {},
			wait = nil,
		}

		queues[targetId] = queue
	end

	if not queue.wait then
		queue.wait = commandTask()
	else
		table.insert(queue.tasks, commandTask)
	end
end

---@param targetPuppet ScriptedPuppet
---@vararg function
function AIControl.QueueTasks(targetPuppet, ...)
	for i = 1, select('#', ...) do
		AIControl.QueueTask(targetPuppet, (select(i, ...)))
	end
end

---@param targetPuppet ScriptedPuppet
function AIControl.ClearQueue(targetPuppet)
	local targetId = TargetingHelper.GetTargetId(targetPuppet)
	local queue = queues[targetId]

	if queue then
		if queue.target:IsAttached() then
			queue.target:GetAIControllerComponent():CancelCommand(queue.wait)
			queue.target:GetStimReactionComponent():DeactiveLookAt(false)
		end

		queues[targetId] = nil
	end
end

function AIControl.ClearQueues()
	for targetId, queue in pairs(queues) do
		if queue.target:IsAttached() then
			queue.target:GetAIControllerComponent():CancelCommand(queue.wait)
			queue.target:GetStimReactionComponent():DeactiveLookAt(false)
		end

		queues[targetId] = nil
	end
end

---@param delta number
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

	queueTimer = queueTimer + delta

	if queueTimer >= queueInterval then
		for key, queue in pairs(queues) do
			if not AIControl.IsCommandActive(queue.target, queue.wait) then
				repeat
					local task = queue.tasks[1]
					local command = task()

					table.remove(queue.tasks, 1)

					if command and command:IsA('AICommand') then
						queue.wait = command
						break
					end
				until #queue.tasks == 0

				if #queue.tasks == 0 then
					queues[key] = nil
				end
			end
		end

		queueTimer = queueTimer - queueInterval
	end
end

function AIControl.Dispose()
	AIControl.FreeFollowers()
	AIControl.ClearQueues()
end

return AIControl