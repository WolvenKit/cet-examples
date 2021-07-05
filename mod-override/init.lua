local ModOverride = require('ModOverride')
local UI = require('UI')

registerForEvent('onInit', function()
	ModOverride.Init()

	UI.Init()

	UI.OnReadyCheck(ModOverride.IsReady)

	UI.OnListItems(function(filter)
		return ModOverride.GetItems(filter)
	end)

	UI.OnAddToInventory(function(iconicMod)
		local player = Game.GetPlayer()
		local itemId = ItemID.FromTDBID(iconicMod.recorId)

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
