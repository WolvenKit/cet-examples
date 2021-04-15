-- Convert CET version to number
-- 1.9.6  -> 1.0906
-- 1.12.2 -> 1.1202
-- next   -> 1.12021
local cetVer = tonumber((GetVersion():gsub('^v(%d+)%.(%d+)%.(%d+)(.*)', function(major, minor, patch, wip)
	return ('%d.%02d%02d%d'):format(major, minor, patch, (wip == '' and 0 or 1))
end))) or 1.12

local function getMainStash() end

if cetVer > 1.1202 then
	getMainStash = function()
		local stashId = NewObject('entEntityID')
		stashId.hash = 16570246047455160070ULL

		return Game.FindEntityByID(stashId)
	end
else
	local stashEntity

	getMainStash = function()
		return stashEntity
	end

	registerForEvent('onInit', function()
		Observe('Stash', 'GetDevicePS', function(self)
			if self:GetEntityID().hash == 16570246047455160070ULL then
				stashEntity = Game.FindEntityByID(self:GetEntityID())
			end
		end)
	end)
end

registerHotkey('OpenStash', 'Open stash', function()
	local stash = getMainStash()

    if stash then
        local openEvent = NewObject('handle:OpenStash')
        openEvent:SetProperties()
    
        stash:OnOpenStash(openEvent)
    end
end)

registerHotkey('PrintStash', 'Print stash items', function()
	local stash = getMainStash()

    if stash then
        local success, items = Game.GetTransactionSystem():GetItemList(stash)

		if success then
			print('[Stash] Total Items:', #items)

			for _, itemData in pairs(items) do
				print('[Stash]', Game.GetLocalizedTextByKey(Game['TDB::GetLocKey;TweakDBID'](itemData:GetID().id + '.displayName')))
			end
		end
    end
end)
