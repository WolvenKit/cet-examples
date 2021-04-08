local ModOverride = require('ModOverride')
local UI = require('UI')

registerForEvent('onInit', function()
	ModOverride.Init()

	UI.Init()

	UI.OnReadyCheck(ModOverride.IsReady)

	UI.OnListItems(function(filter)
		return ModOverride.GetItems(filter)
	end)

	UI.OnAddToInventory(function(item)
		local player = Game.GetPlayer()
		local itemId = GetSingleton('gameItemID'):FromTDBID(item.id)

		Game.GetTransactionSystem():GiveItem(player, itemId, 1)
	end)
end)

registerForEvent('onOverlayOpen', function()
	UI.Show()
end)

registerForEvent('onOverlayClose', function()
	UI.Hide()
end)

registerForEvent('onDraw', function()
	UI.Draw()
end)
