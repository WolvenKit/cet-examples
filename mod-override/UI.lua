local UI = {}

local style = {}

local state = {
	open = false,
	filter = '',
	selected = nil,
}

local logic = {
	isReady = function() return false end,
	getItemList = function() return {} end,
	addToInventory = function() end,
}

function UI.Init()
	style.scale = ImGui.GetFontSize() / 13

	style.windowWidth = 340 * style.scale
	style.windowHeight = 0 -- Auto height
	style.windowPaddingX = 8 * style.scale
	style.windowPaddingY = 8 * style.scale

	style.framePaddingX = 3 * style.scale
	style.framePaddingY = 3 * style.scale
	style.innerSpacingX = 4 * style.scale
	style.innerSpacingY = 4 * style.scale
	style.itemSpacingX = 8 * style.scale
	style.itemSpacingY = 4 * style.scale

	style.listBoxHeight = (7 * 17 - 2) * style.scale
	style.buttonHeight = 20 * style.scale

	local screenWidth, screenHeight = GetDisplayResolution()

	style.windowX = (screenWidth - style.windowWidth) / 2
	style.windowY = (screenHeight - style.windowHeight) / 2
end

function UI.OnReadyCheck(callback)
	if type(callback) == 'function' then
		logic.isReady = callback
	end
end

function UI.OnListItems(callback)
	if type(callback) == 'function' then
		logic.getItemList = callback
	end
end

function UI.OnAddToInventory(callback)
	if type(callback) == 'function' then
		logic.addToInventory = callback
	end
end

function UI.Show()
	state.open = true
end

function UI.Hide()
	state.open = false
end

function UI.Draw()
	if not state.open then
		return
	end

	ImGui.SetNextWindowPos(style.windowX, style.windowY, ImGuiCond.FirstUseEver)
	ImGui.SetNextWindowSize(style.windowWidth + style.windowPaddingX * 2 - 1, style.windowHeight)

	ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, style.windowPaddingX, style.windowPaddingY)
	ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, style.framePaddingX, style.framePaddingY)
	ImGui.PushStyleVar(ImGuiStyleVar.ItemInnerSpacing, style.innerSpacingX, style.innerSpacingY)
	ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, style.itemSpacingX, style.itemSpacingY)

	if ImGui.Begin('Iconic Mods', ImGuiWindowFlags.NoResize + ImGuiWindowFlags.NoScrollbar + ImGuiWindowFlags.NoScrollWithMouse) then
		if logic.isReady() then
			ImGui.SetNextItemWidth(style.windowWidth)
			ImGui.PushStyleColor(ImGuiCol.TextDisabled, 0xffaaaaaa)
			state.filter = ImGui.InputTextWithHint('##ItemFilter', 'Filter mods...', state.filter, 100)
			ImGui.PopStyleColor()

			ImGui.Spacing()

			ImGui.PushStyleColor(ImGuiCol.FrameBg, 0)
			ImGui.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 0)
			ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 0, 0)
			ImGui.BeginListBox('##ItemList', style.windowWidth, style.listBoxHeight)

			for _, item in ipairs(logic.getItemList(state.filter)) do
				if ImGui.Selectable(item.label, (state.selected == item)) then
					state.selected = item
				end
			end

			ImGui.EndListBox()
			ImGui.PopStyleVar(2)
			ImGui.PopStyleColor()

			if state.selected then
				ImGui.Spacing()
				ImGui.Separator()
				ImGui.Spacing()

				ImGui.PushStyleColor(ImGuiCol.Text, 0xfffefd01)
				ImGui.Text(state.selected.label)
				ImGui.PopStyleColor()

				ImGui.PushStyleColor(ImGuiCol.Text, 0xff484ad5)
				ImGui.TextWrapped(state.selected.weaponDesc)
				ImGui.PopStyleColor()

				ImGui.PushStyleColor(ImGuiCol.Text, 0xff9f9f9f)
				ImGui.TextWrapped(state.selected.abilityDesc)
				ImGui.PopStyleColor()

				ImGui.Spacing()

				if ImGui.Button('Add to inventory', style.windowWidth, style.buttonHeight) then
					logic.addToInventory(state.selected)
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
		state.selected = nil
	end

	ImGui.End()

	ImGui.PopStyleVar(4)
end

return UI