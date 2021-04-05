-- Recursive settings exporter

local function makePath(groupPath, varName)
	return groupPath .. '/' .. varName
end

local function isNameType(type)
	return type == 'Name' or type == 'NameList'
end

local function isNumberType(type)
	return type == 'Int' or type == 'Float'
end

local function isListType(type)
	return type == 'IntList' or type == 'FloatList' or type == 'StringList' or type == 'NameList'
end

local function exportVar(var)
	local output = {}

	output.path = makePath(Game.NameToString(var:GetGroupPath()), Game.NameToString(var:GetName()))
	output.value = var:GetValue()
	output.type = var:GetType().value

	if isNameType(output.type) then
		output.value = Game.NameToString(output.value)
	end

	if isNumberType(output.type)  then
		output.min = var:GetMinValue()
		output.max = var:GetMaxValue()
		output.step = var:GetStepValue()
	end

	if isListType(output.type)  then
		output.index = var:GetIndex() + 1
		output.options = var:GetValues()

		if isNameType(output.type) then
			for i, option in ipairs(output.options) do
				output.options[i] = Game.NameToString(option)
			end
		end
	end

	return output
end

local function exportVars(isPreGame, group, output)
	if type(group) ~= 'userdata' then
		group = Game.GetSettingsSystem():GetRootGroup()
	end

	if type(isPreGame) ~= 'bool' then
		isPreGame = GetSingleton('inkMenuScenario'):GetSystemRequestsHandler():IsPreGame()
	end

	if not output then
		output = {}
	end

	for _, var in ipairs(group:GetVars(isPreGame)) do
		table.insert(output, exportVar(var))
	end

	for _, child in ipairs(group:GetGroups(isPreGame)) do
		exportVars(isPreGame, child, output)
	end

	table.sort(output, function(a, b)
		return a.path < b.path
	end)

	return output
end

local function exportTo(exportPath, isPreGame)
	local output = {}

	local vars = exportVars(isPreGame)

	for _, var in ipairs(vars) do
		local value = var.value
		local options

		if type(value) == 'string' then
			value = string.format('%q', value)
		end

		if var.options and #var.options > 1 then
			options = {}

			for i, option in ipairs(var.options) do
				options[i] = option
			end

			options = ' -- ' .. table.concat(options, ' | ')
		elseif var.step then
			options = (' -- %.2f to %.2f / %.2f'):format(var.min, var.max, var.step)
		end

		table.insert(output, ('  ["%s"] = %s,%s'):format(var.path, value, options or ''))
	end

	table.insert(output, 1, '{')
	table.insert(output, '}')

	output = table.concat(output, '\n')

	if exportPath then
		if not exportPath:find('%.lua$') then
			exportPath = exportPath .. '.lua'
		end

		local exportFile = io.open(exportPath, 'w')

		if exportFile then
			exportFile:write('return ')
			exportFile:write(output)
			exportFile:close()
		end
	else
		return output
	end
end

return exportTo