local TargetingHelper = {}

local markers = {}

function TargetingHelper.GetLookAtTarget(searchFilter)
	local player = Game.GetPlayer()

	local searchQuery = NewObject('gameTargetSearchQuery')
	searchQuery.searchFilter = searchFilter or Game['TSF_NPC;']()
	searchQuery.maxDistance = Game['SNameplateRangesData::GetDisplayRange;']()

	return Game.GetTargetingSystem():GetObjectClosestToCrosshair(player, NewObject('EulerAngles'), searchQuery)
end

function TargetingHelper.GetLookAtTargets(searchFilter)
	local player = Game.GetPlayer()

	local searchQuery = NewObject('gameTargetSearchQuery')
	searchQuery.searchFilter = searchFilter or Game['TSF_NPC;']()
	searchQuery.maxDistance = Game['SNameplateRangesData::GetDisplayRange;']()

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

function TargetingHelper.UnmarkAll()
	for _, marker in pairs(markers) do
		Game.GetMappinSystem():UnregisterMappin(marker.mappinId)
	end

	markers = {}
end

return TargetingHelper