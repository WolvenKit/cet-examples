local TargetingHelper = {}

local markers = {}
local pins = {}

local function getLookAtPositionReal(distance)
	if not distance then
		distance = 100
	end

	local player = Game.GetPlayer()
	local from, forward = Game.GetTargetingSystem():GetCrosshairData(player)
	local to = Vector4.new(
		from.x + forward.x * distance,
		from.y + forward.y * distance,
		from.z + forward.z * distance,
		from.w
	)

	local filters = {
		'Dynamic', -- Movable Objects
		'Vehicle',
		'Static', -- Buildings, Concrete Roads, Crates, etc.
		'Water',
		'Terrain',
		'PlayerBlocker', -- Trees, Billboards, Barriers
	}

	local results = {}

	for _, filter in ipairs(filters) do
		local success, result = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(from, to, filter, false, false)

		if success then
			table.insert(results, {
				distance = GetSingleton('Vector4'):Distance(from, ToVector4(result.position)),
				position = ToVector4(result.position),
				normal = result.normal,
				material = result.material,
				collision = CName.new(filter),
			})
		end
	end

	if #results == 0 then
		return nil
	end

	local nearest = results[1]

	for i = 2, #results do
		if results[i].distance < nearest.distance then
			nearest = results[i]
		end
	end

	return nearest.position
end

local function getLookAtPositionFallback()
	local player = Game.GetPlayer()

	local playerForward = player:GetWorldForward()
	local playerPosition = player:GetWorldPosition()

	return Vector4.new(
		playerPosition.x + playerForward.x * 2.5,
		playerPosition.y + playerForward.y * 2.5,
		playerPosition.z,
		playerPosition.w
	)
end

local function getLookAtTargetReal(searchFilter)
	local player = Game.GetPlayer()

	local searchQuery = NewObject('gameTargetSearchQuery')
	searchQuery.searchFilter = searchFilter or Game['TSF_NPC;']()
	searchQuery.maxDistance = Game['SNameplateRangesData::GetMaxDisplayRange;']()

	return Game.GetTargetingSystem():GetObjectClosestToCrosshair(player, searchQuery)
end

local function getLookAtTargetFallback(searchFilter)
	local player = Game.GetPlayer()

	local searchQuery = NewObject('gameTargetSearchQuery')
	searchQuery.searchFilter = searchFilter or Game['TSF_NPC;']()
	searchQuery.maxDistance = Game['SNameplateRangesData::GetMaxDisplayRange;']()

	return Game.GetTargetingSystem():GetObjectClosestToCrosshair(player, NewObject('EulerAngles'), searchQuery)
end

local function inititalizeMethods()
	-- Test if `SyncRaycastByCollisionGroup` is available
	local success, result = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(Vector4.new(0,0,0,0), Vector4.new(0,0,0,0), 'Static', false, false)
	if success ~= nil and result ~= nil then
		TargetingHelper.GetLookAtPosition = getLookAtPositionReal
		TargetingHelper.GetLookAtTarget = getLookAtTargetReal
	else
		print('[Targeting Helper] Ray casting is not available.')
		TargetingHelper.GetLookAtPosition = getLookAtPositionFallback
		TargetingHelper.GetLookAtTarget = getLookAtTargetFallback
	end
end

function TargetingHelper.GetLookAtPosition(distance)
	inititalizeMethods()

	return TargetingHelper.GetLookAtPosition(distance)
end

function TargetingHelper.GetLookAtTarget(searchFilter)
	inititalizeMethods()

	return TargetingHelper.GetLookAtTarget(searchFilter)
end

function TargetingHelper.GetLookAtTargets(searchFilter)
	local player = Game.GetPlayer()

	local searchQuery = NewObject('gameTargetSearchQuery')
	searchQuery.searchFilter = searchFilter or Game['TSF_NPC;']()
	searchQuery.maxDistance = Game['SNameplateRangesData::GetMaxDisplayRange;']()

	local success, targetParts = Game.GetTargetingSystem():GetTargetParts(player, searchQuery)
	local targets = {}

	if success then
		for _, targetPart in ipairs(targetParts) do
			local component = GetSingleton('gametargetingTargetPartInfo'):GetComponent(targetPart)

			local target = component:GetEntity()
			local targetId = tostring(target:GetEntityID().hash)

			targets[targetId] = target
		end
	end

	return targets
end

function TargetingHelper.IsActive(target)
	return target:IsAttached()
		and not target:IsDeadNoStatPool()
		and not target:IsTurnedOffNoStatusEffect()
		and not Game['ScriptedPuppet::IsDefeated;GameObject'](target)
		and not Game['ScriptedPuppet::IsUnconscious;GameObject'](target)
end

function TargetingHelper.GetTargetId(target)
	return tostring(target:GetEntityID().hash)
end

function TargetingHelper.IsTargetMarked(target)
	local targetId = TargetingHelper.GetTargetId(target)

	return markers[targetId] ~= nil
end

function TargetingHelper.MarkTarget(target)
	local targetId = TargetingHelper.GetTargetId(target)

	local mappinData = NewObject('gamemappinsMappinData')
	mappinData.mappinType = TweakDBID.new('Mappins.DefaultStaticMappin')
	mappinData.variant = Enum.new('gamedataMappinVariant', 'TakeControlVariant')
	mappinData.visibleThroughWalls = true

	local mappinId = Game.GetMappinSystem():RegisterMappinWithObject(mappinData, target, 'poi_mappin', Vector3.new(0, 0, 2.0))

	markers[targetId] = { target = target, mappinId = mappinId }
end

function TargetingHelper.UnmarkTarget(target)
	local targetId = TargetingHelper.GetTargetId(target)

	if markers[targetId] then
		local marker = markers[targetId]

		Game.GetMappinSystem():UnregisterMappin(marker.mappinId)

		markers[targetId] = nil
	end
end

function TargetingHelper.GetMarkedTargets(autoClear)
	-- Auto clear is ON by default
	if autoClear == nil then
		autoClear = true
	end

	local targets = {}

	for _, marker in pairs(markers) do
		if TargetingHelper.IsActive(marker.target) then
			table.insert(targets, marker.target)
		elseif autoClear then
			TargetingHelper.UnmarkTarget(marker.target)
		end
	end

	return targets
end

function TargetingHelper.UnmarkTargets()
	for _, marker in pairs(markers) do
		Game.GetMappinSystem():UnregisterMappin(marker.mappinId)
	end

	markers = {}
end

function TargetingHelper.MarkPosition(position, variant)
	local positionId = tostring(position)

	local mappinData = NewObject('gamemappinsMappinData')
	mappinData.mappinType = TweakDBID.new('Mappins.DefaultStaticMappin')
	mappinData.variant = Enum.new('gamedataMappinVariant', variant or 'AimVariant')
	mappinData.visibleThroughWalls = true

	local mappinId = Game.GetMappinSystem():RegisterMappin(mappinData, position)

	pins[positionId] = { position = position, mappinId = mappinId }
end

function TargetingHelper.UnmarkPosition(position)
	local positionId = tostring(position)

	if pins[positionId] then
		local pin = pins[positionId]

		Game.GetMappinSystem():UnregisterMappin(pin.mappinId)

		pins[positionId] = nil
	end
end

function TargetingHelper.UnmarkPositions()
	for _, pin in pairs(pins) do
		Game.GetMappinSystem():UnregisterMappin(pin.mappinId)
	end

	pins = {}
end

function TargetingHelper.Dispose()
	TargetingHelper.UnmarkTargets()
	TargetingHelper.UnmarkPositions()
end

return TargetingHelper