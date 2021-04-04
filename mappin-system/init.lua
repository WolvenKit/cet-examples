registerHotkey('PlaceCustomMapPin', 'Place a map pin at player\'s position', function()
	local mappinData = NewObject('gamemappinsMappinData')
	mappinData.mappinType = TweakDBID.new('Mappins.DefaultStaticMappin')
	mappinData.variant = Enum.new('gamedataMappinVariant', 'FastTravelVariant')
	mappinData.visibleThroughWalls = true
	
	local position = Game.GetPlayer():GetWorldPosition()
	
	Game.GetMappinSystem():RegisterMappin(mappinData, position)
end)

registerHotkey('PlaceObjectMapPin', 'Place a map pin on the target', function()
	local target = Game.GetTargetingSystem():GetLookAtObject(Game.GetPlayer(), false, false)
	
	if target then
		local mappinData = NewObject('gamemappinsMappinData')
		mappinData.mappinType = TweakDBID.new('Mappins.DefaultStaticMappin')
		mappinData.variant = Enum.new('gamedataMappinVariant', 'FastTravelVariant')
		mappinData.visibleThroughWalls = true
		
		local slot = CName.new('poi_mappin')

		-- Move the pin a bit up relative to the target
		-- Approx. position over the NPC head
		local offset = Vector3.new(0, 0, 2)
		
		Game.GetMappinSystem():RegisterMappinWithObject(mappinData, target, slot, offset)
	end
end)
