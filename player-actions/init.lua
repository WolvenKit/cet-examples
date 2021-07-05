-- General logging switch
local enableLogging = require('state')

if enableLogging ~= false then
	enableLogging = true
end

-- Custom action filter
local ignoreActions = {
	['BUTTON_RELEASED'] = {
		['UI_FakeMovement'] = true,
	},
	['RELATIVE_CHANGE'] = {
		['UI_FakeCamera'] = true,
		['CameraMouseX'] = true,
		['CameraMouseY'] = true,
		['mouse_x'] = true,
		['mouse_y'] = true,
	},
}

local function printLoggingState()
	print('Player action logging: ' .. (enableLogging and 'ON' or 'OFF'))
end

registerForEvent('onInit', function()
	printLoggingState()

	Observe('PlayerPuppet', 'OnAction', function(_, action)
		if enableLogging then
			local actionName = Game.NameToString(action:GetName())
			local actionType = action:GetType().value -- gameinputActionType
			local actionValue = action:GetValue()

			if not ignoreActions[actionType] or not ignoreActions[actionType][actionName] then
				spdlog.info(('[%s] %s = %.3f'):format(actionType, actionName, actionValue))
			end
		end
	end)
end)

registerHotkey('ToggleLog', 'Toggle logging', function()
	enableLogging = not enableLogging
	printLoggingState()

	local stateFile = io.open('state.lua', 'w')

	if stateFile then
		stateFile:write('return ')
		stateFile:write(tostring(enableLogging))
		stateFile:close()
	end
end)

registerHotkey('FlushLog', 'Flush input log', function()
	spdlog.error('---')
end)

--[[
An example of reading specific player actions

registerForEvent('onInit', function()
	Observe('PlayerPuppet', 'OnAction', function(_, action)
		local actionName = Game.NameToString(ListenerAction.GetName(action))
		local actionType = ListenerAction.GetType(action).value -- gameinputActionType
		local actionValue = ListenerAction.GetValue(action)

		if actionName == 'Forward' or actionName == 'Back' then
			if actionType == 'BUTTON_PRESSED' then
				print('[Action]', actionName, 'Pressed')
			elseif actionType == 'BUTTON_RELEASED' then
				print('[Action]', actionName, 'Released')
			end
		elseif actionName == 'MoveY' then
			if actionValue ~= 0 then
				print('[Action]', (actionValue > 0 and 'Forward' or 'Back'), Game.GetPlayer():GetWorldForward())
			end
		elseif actionName == 'Jump' then
			if actionType == 'BUTTON_PRESSED' then
				print('[Action] Jump Pressed')
			elseif actionType == 'BUTTON_HOLD_COMPLETE' then
				print('[Action] Jump Charged')
			elseif actionType == 'BUTTON_RELEASED' then
				print('[Action] Jump Released')
			end
		elseif actionName == 'WeaponSlot1' then
			if actionType == 'BUTTON_PRESSED' then
				print('[Action] Select Weapon 1')
			end
		end
	end)
end)
]]--
