-- The list of the vehicles to add to the call list
local targetVehicles = {
	'Vehicle.v_standard2_archer_hella_police',
	'Vehicle.v_standard2_villefort_cortes_police',
	'Vehicle.v_standard3_chevalier_emperor_police',
	'Vehicle.v_standard2_archer_hella_player',
	'Vehicle.v_sport2_quadra_type66_nomad',
}

local function unlockVehicles(vehicles)
	local unlockableVehicles = TweakDB:GetFlat('Vehicle.vehicle_list.list')

	for _, vehiclePath in ipairs(vehicles) do
		local targetVehicleTweakDbId = TweakDBID.new(vehiclePath)
		local isVehicleUnlockable = false

		for _, unlockableVehicleTweakDbId in ipairs(unlockableVehicles) do
			if unlockableVehicleTweakDbId == targetVehicleTweakDbId then
				isVehicleUnlockable = true
				break
			end
		end

		if not isVehicleUnlockable then
			table.insert(unlockableVehicles, targetVehicleTweakDbId)
		end
	end

	TweakDB:SetFlat('Vehicle.vehicle_list.list', unlockableVehicles)
end

local function summonVehicle(vehiclePath)
	local vehicleSystem = Game.GetVehicleSystem()

	local garageVehicleId = GarageVehicleID.Resolve(vehiclePath)
	vehicleSystem:TogglePlayerActiveVehicle(garageVehicleId, gamedataVehicleType.Car, true)
	vehicleSystem:SpawnPlayerVehicle(gamedataVehicleType.Car)
end

-- If you change the vehicle list and reload the mod,
-- you will also have to reload the save for the changes
-- to take effect
registerForEvent('onInit', function()
	unlockVehicles(targetVehicles)
end)

-- You cannot spawn the same vehicle twice with Vehicle System
registerHotkey('SpawnRandomVehicle', 'Spawn a random vehicle', function()
	summonVehicle(targetVehicles[math.random(#targetVehicles)])
end)

-- With instant summon you can control the position (in front of the player)
-- Otherwise the game can spawn a vehicle right in the spot of another one
registerHotkey('ToggleSpawnMode', 'Toggle instant spawn mode', function()
	Game.GetVehicleSystem():ToggleSummonMode()
end)

-- The results of this action are permanent as long
-- as unlocking is done before loading into the game
registerHotkey('EnableAllVehicles', 'Add vehicles to the call list', function()
	for _, targetVehicle in ipairs(targetVehicles) do
		Game.GetVehicleSystem():EnablePlayerVehicle(targetVehicle, true, false)
	end
end)
