registerHotkey('CycleFOV', 'Cycle FOV', function()
	local fov = Game.GetSettingsSystem():GetVar('/graphics/basic', 'FieldOfView')

	local value = fov:GetValue() + fov:GetStepValue()

	if value > fov:GetMaxValue() then
		value = fov:GetMinValue()
	end

	fov:SetValue(value)

	print(('Current FOV: %.1f'):format(fov:GetValue()))
end)

registerHotkey('CycleResolution', 'Cycle resolution', function()
	local resolution = Game.GetSettingsSystem():GetVar('/video/display', 'Resolution')

	local options = resolution:GetValues()
	local current = resolution:GetIndex() + 1 -- lua tables start at 1
	local next = current + 1

	if next > #options then
		next = 1
	end

	resolution:SetIndex(next - 1)

	Game.GetSettingsSystem():ConfirmChanges()

	print(('Switched resolution from %s to %s'):format(options[current], options[next]))
end)

registerHotkey('ToggleHUD', 'Toggle HUD', function()
	local settingsSystem = Game.GetSettingsSystem()

	-- Read the state of the first hud option
	local hudGroup = settingsSystem:GetGroup('/interface/hud')
	local hudState = hudGroup:GetVar('healthbar'):GetValue()

	-- Invert the state
	local newState = not hudState --

	for _, var in ipairs(hudGroup:GetVars(false)) do
		var:SetValue(newState)
	end
end)

registerHotkey('ExportSettings', 'Export all settings', function()
	require('dump')('settings.lua')
end)
