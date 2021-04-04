local ModOverride = {}

local ready = false
local items = {}

-- Find all iconic weapon + mod pairs
function ModOverride.Discover()
	local iconicMods = {}
	local iconicModifer = TweakDB:GetRecord('Quality.IconicItem')
	local weaponRecords = TweakDB:GetRecords('gamedataWeaponItem_Record')

	for _, weaponRecord in pairs(weaponRecords) do
		local weaponTag = weaponRecord:GetVisualTagsItem(0).value

		if not iconicMods[weaponTag] and weaponRecord:StatModifiersContains(iconicModifer) then
			for index = 0, weaponRecord:GetSlotPartListPresetCount() - 1 do
				local slotItemPartPreset = weaponRecord:GetSlotPartListPresetItem(index)

				if slotItemPartPreset:Slot():EntitySlotName() == 'IconicWeaponModLegendary' then
					local modRecord = slotItemPartPreset:ItemPartPreset()

					iconicMods[weaponTag] = {
						modRecord = modRecord,
						weaponTag = weaponTag,
						weaponRecord = weaponRecord
					}

					break
				end
			end
		end
	end

	return iconicMods
end

-- Make given mods available for player
function ModOverride.Unlock(iconicMods)
	items = {}

	local slots = {
		['AttachmentSlots.GenericWeaponMod'] = 4,
		['AttachmentSlots.MeleeWeaponMod'] = 3,
	}

	for _, iconic in pairs(iconicMods) do
		local modId = iconic.modRecord:GetID()
		local weaponId = iconic.weaponRecord:GetID()
		local weaponName = TweakDB:GetFlat(TweakDBID.new(weaponId, '.displayName'))
		local slotList = TweakDB:GetFlat(TweakDBID.new(modId, '.placementSlots'))

		-- Iconic mods are allowed to be installed in only one slot
		-- If there is more than one slot then TweakDB is modified
		if #slotList == 1 then
			for slotGroup, slotCount in pairs(slots) do
				for index = 1, slotCount do
					local slotId = TweakDBID.new(slotGroup .. index)
					local slotUnlocked = false

					for _, unlockedId in ipairs(slotList) do
						if tostring(slotId) == tostring(unlockedId) then
							slotUnlocked = true
							break
						end
					end

					if not slotUnlocked then
						table.insert(slotList, slotId)
					end
				end
			end

			TweakDB:SetFlatNoUpdate(TweakDBID.new(modId, '.displayName'), weaponName)
			TweakDB:SetFlatNoUpdate(TweakDBID.new(modId, '.placementSlots'), slotList)
			TweakDB:Update(modId)
		end

		table.insert(items, ModOverride.MakeItem(iconic))
	end

	table.sort(items, function(a, b)
		return a.label < b.label
	end)
end

function ModOverride.IsReady()
	return ready
end

function ModOverride.Init()
	local iconicMods = ModOverride.Discover()

	ModOverride.Unlock(iconicMods)

	-- Initital state
	ready = Game.GetPlayer():IsAttached() and not GetSingleton('inkMenuScenario'):GetSystemRequestsHandler():IsPreGame()

	-- Observe game session
	Observe('RadialWheelController', 'RegisterBlackboards', function(_, loaded)
		ready = loaded
	end)
end

function ModOverride.MakeItem(iconic)
	local weaponName = Game.GetLocalizedTextByKey(iconic.weaponRecord:DisplayName())
	local weaponDesc = Game.GetLocalizedTextByKey(iconic.weaponRecord:LocalizedDescription())
	local abilityDesc = Game.GetLocalizedText(iconic.modRecord:GetOnAttachItem(0):UIData():LocalizedDescription())
	local weaponTag = iconic.weaponTag:gsub('_', ' '):gsub('^' .. weaponName .. ' ', '')

	local item = {}

	item.id = iconic.modRecord:GetID()
	item.label = ('%s %q'):format(weaponTag, weaponName:gsub('%%', '%%%%'))

	item.abilityDesc = abilityDesc:gsub('%%', '%%%%')
	item.weaponDesc = weaponDesc:gsub('%%', '%%%%')

	item.filter = item.label:upper()

	return item
end

function ModOverride.GetItems(filter)
	if not filter or filter == '' then
		return items
	end

	local filterEsc = filter:gsub('([^%w])', '%%%1'):upper()
	local filterRe = filterEsc:gsub('%s+', '.* ') .. '.*'

	local filtered = {}

	for _, item in ipairs(items) do
		if item.filter:find(filterRe) then
			table.insert(filtered, item)
		end
	end

	return filtered
end

return ModOverride