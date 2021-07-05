local TargetingHelper = {}

local markers = {}
local pins = {}

---@param distance number
---@return Vector4
function TargetingHelper.GetLookAtPosition(distance)
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
				distance = Vector4.Distance(from, ToVector4(result.position)),
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

---@param searchFilter gameTargetSearchFilter|nil
---@return gameObject
function TargetingHelper.GetLookAtTarget(searchFilter)
	local player = Game.GetPlayer()

	local searchQuery = TargetSearchQuery.new()
	searchQuery.searchFilter = searchFilter or Game['TSF_NPC;']()
	searchQuery.maxDistance = SNameplateRangesData.GetMaxDisplayRange()

	return Game.GetTargetingSystem():GetObjectClosestToCrosshair(player, searchQuery)
end

---@param searchFilter gameTargetSearchFilter|nil
---@return gameObject[]
function TargetingHelper.GetLookAtTargets(searchFilter)
	local player = Game.GetPlayer()

	local searchQuery = TargetSearchQuery.new()
	searchQuery.searchFilter = searchFilter or Game['TSF_NPC;']()
	searchQuery.maxDistance = SNameplateRangesData.GetMaxDisplayRange()

	local success, targetParts = Game.GetTargetingSystem():GetTargetParts(player, searchQuery)
	local targets = {}

	if success then
		for _, targetPart in ipairs(targetParts) do
			local component = targetPart:GetComponent()

			local target = component:GetEntity()
			local targetId = tostring(target:GetEntityID().hash)

			targets[targetId] = target
		end
	end

	return targets
end

---@param target gameObject
---@return boolean
function TargetingHelper.IsActive(target)
	return target:IsAttached()
		and not target:IsDeadNoStatPool()
		and not target:IsTurnedOffNoStatusEffect()
		and not ScriptedPuppet.IsDefeated(target)
		and not ScriptedPuppet.IsUnconscious(target)
end

---@param target gameObject
---@return string
function TargetingHelper.GetTargetId(target)
	return tostring(target:GetEntityID().hash)
end

---@param target gameObject
---@return boolean
function TargetingHelper.IsTargetMarked(target)
	local targetId = TargetingHelper.GetTargetId(target)

	return markers[targetId] ~= nil
end

---@param target gameObject
function TargetingHelper.MarkTarget(target)
	local targetId = TargetingHelper.GetTargetId(target)

	local mappinData = MappinData.new()
	mappinData.mappinType = 'Mappins.DefaultStaticMappin'
	mappinData.variant = gamedataMappinVariant.TakeControlVariant
	mappinData.visibleThroughWalls = true

	local mappinId = Game.GetMappinSystem():RegisterMappinWithObject(mappinData, target, 'poi_mappin', Vector3.new(0, 0, 2.0))

	markers[targetId] = { target = target, mappinId = mappinId }
end

---@param target gameObject
function TargetingHelper.UnmarkTarget(target)
	local targetId = TargetingHelper.GetTargetId(target)

	if markers[targetId] then
		local marker = markers[targetId]

		Game.GetMappinSystem():UnregisterMappin(marker.mappinId)

		markers[targetId] = nil
	end
end

---@param autoClear boolean
---@return gameObject[]
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

---@param position Vector4
---@param variant gamedataMappinVariant
function TargetingHelper.MarkPosition(position, variant)
	local positionId = tostring(position)

	local mappinData = MappinData.new()
	mappinData.mappinType = 'Mappins.DefaultStaticMappin'
	mappinData.variant = variant or gamedataMappinVariant.AimVariant
	mappinData.visibleThroughWalls = true

	local mappinId = Game.GetMappinSystem():RegisterMappin(mappinData, position)

	pins[positionId] = { position = position, mappinId = mappinId }
end

---@param position Vector4
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