local ModOverride = require('ModOverride')

local ui = {
	windowOpen = false,
	windowX = 0,
	windowY = 300,
	windowWidth = 340,
	windowHeight = 0,
	windowPaddingX = 8,
	windowPaddingY = 8,
	listBoxHeight = 114,
	filterText = '',
	selected = nil,
}

registerForEvent('onInit', function()
	ModOverride.Init()
end)

registerForEvent('onOverlayOpen', function()
	ui.windowOpen = true
end)

registerForEvent('onOverlayClose', function()
	ui.windowOpen = false
end)

registerForEvent('onDraw', function()
	if not ui.windowOpen then
		return
	end

	ImGui.SetNextWindowPos(ui.windowX, ui.windowY, ImGuiCond.FirstUseEver)
	ImGui.SetNextWindowSize(ui.windowWidth + ui.windowPaddingX * 2 - 1, ui.windowHeight)
	ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, ui.windowPaddingX, ui.windowPaddingY)

	if ImGui.Begin('Iconic Mods', ImGuiWindowFlags.NoResize + ImGuiWindowFlags.NoScrollbar + ImGuiWindowFlags.NoScrollWithMouse) then
		if ModOverride.IsReady() then
			ImGui.SetNextItemWidth(ui.windowWidth)
			ImGui.PushStyleColor(ImGuiCol.TextDisabled, 0xffaaaaaa)
			ui.filterText = ImGui.InputTextWithHint('##ModOverrideFilter', 'Filter mods...', ui.filterText, 100)
			ImGui.PopStyleColor()

			ImGui.Spacing()

			ImGui.PushStyleColor(ImGuiCol.FrameBg, 0)
			ImGui.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 0)
			ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 0, 0)
			ImGui.BeginListBox("##ModOverrideList", ui.windowWidth, ui.listBoxHeight)

			for _, item in ipairs(ModOverride.GetItems(ui.filterText)) do
				if ImGui.Selectable(item.label, (ui.selected == item)) then
					ui.selected = item
				end
			end

			ImGui.EndListBox()
			ImGui.PopStyleVar(2)
			ImGui.PopStyleColor()

			if ui.selected then
				ImGui.Spacing()
				ImGui.Separator()
				ImGui.Spacing()

				ImGui.PushStyleColor(ImGuiCol.Text, 0xfffefd01)
				ImGui.Text(ui.selected.label)
				ImGui.PopStyleColor()

				ImGui.PushStyleColor(ImGuiCol.Text, 0xff484ad5)
				ImGui.TextWrapped(ui.selected.weaponDesc)
				ImGui.PopStyleColor()

				ImGui.PushStyleColor(ImGuiCol.Text, 0xff9f9f9f)
				ImGui.TextWrapped(ui.selected.abilityDesc)
				ImGui.PopStyleColor()

				ImGui.Spacing()

				if ImGui.Button('Add to inventory', ui.windowWidth, 20) then
					local player = Game.GetPlayer()
					local itemId = GetSingleton('gameItemID'):FromTDBID(ui.selected.id)

					Game.GetTransactionSystem():GiveItem(player, itemId, 1)
				end
			end
		else
			ImGui.Spacing()
			ImGui.PushStyleColor(ImGuiCol.Text, 0xff9f9f9f)
			ImGui.TextWrapped('Load the game to access the iconic mods')
			ImGui.PopStyleColor()
			ImGui.Spacing()
		end
	else
		ui.selected = nil
	end

	ImGui.End()
	ImGui.PopStyleVar()
end)
