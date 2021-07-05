local StashAnywhere = {}

---@return Stash
function StashAnywhere.GetStashEntity()
	return Game.FindEntityByID(EntityID.new({ hash = 16570246047455160070ULL }))
end

---@return gameItemData[]
function StashAnywhere.GetStashItems()
	local stash = StashAnywhere.GetStashEntity()

    if stash then
		local success, items = Game.GetTransactionSystem():GetItemList(stash)

		if success then
			return items
		end
    end

    return {}
end

function StashAnywhere.OpenStashMenu()
	local stash = StashAnywhere.GetStashEntity()

    if stash then
        local openStashEvent = OpenStash.new()
        openStashEvent:SetProperties()

        stash:OnOpenStash(openStashEvent)
    end
end

registerHotkey('OpenStash', 'Open stash', function()
	StashAnywhere.OpenStashMenu()
end)

registerHotkey('PrintStash', 'Print stash items', function()
	local items = StashAnywhere.GetStashItems()

    if #items > 0 then
		print('[Stash] Total Items:', #items)

		for _, itemData in pairs(items) do
			local itemID = itemData:GetID()
			local recordID = itemID.id

			print('[Stash]', Game.GetLocalizedTextByKey(TDB.GetLocKey(recordID .. '.displayName')))
		end
    end
end)

return StashAnywhere