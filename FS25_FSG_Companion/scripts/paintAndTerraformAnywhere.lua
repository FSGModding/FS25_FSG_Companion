-- paintAnywhere 
-- by modelleicher 28.11.2021
-- allows to terraform, paint ground and foliage anywhere

-- Update 16.11.2022 - remove all collisions from Landscaping Brush so landscaping below triggers and vehicles is also possible 

-- Updated to work with FSG Realism servers

-- paintAndTerraformAnywhere = {};

-- -- remove dynamic and vehicle collisions from Landscaping Brush 
-- CollisionMask.LANDSCAPING = 0

-- -- this seems to very if access is possible for every paint and landscape operation
-- function paintAndTerraformAnywhere:verifyAccess(superFunc, x, y, z)
--   -- Check if enabled
--   if g_fsgSettings.settings:getValue("paintAnywhere") then
--     return nil;
-- 	elseif not self:hasPlayerPermission() then
-- 		return ConstructionBrush.ERROR.NO_PERMISSION
-- 	elseif not g_currentMission.accessHandler:canFarmAccessLand(g_currentMission.player.farmId, x, z, true) then
-- 		return ConstructionBrush.ERROR.LAND_UNOWNED
-- 	elseif PlacementUtil.isInsidePlacementPlaces(g_currentMission.storeSpawnPlaces, x, y, z) then
-- 		return ConstructionBrush.ERROR.STORE_PLACE
-- 	elseif PlacementUtil.isInsidePlacementPlaces(g_currentMission.loadSpawnPlaces, x, y, z) then
-- 		return ConstructionBrush.ERROR.SPAWN_PLACE
-- 	elseif PlacementUtil.isInsideRestrictedZone(g_currentMission.restrictedZones, x, y, z) then
-- 		return ConstructionBrush.ERROR.RESTRICTED_ZONE
-- 	end

-- 	return nil
-- end;
-- ConstructionBrush.verifyAccess = Utils.overwrittenFunction(ConstructionBrush.verifyAccess, paintAndTerraformAnywhere.verifyAccess);

-- -- this also seems to stop painting and terraforming on not-owned land
-- function paintAndTerraformAnywhere.isModificationAreaOnOwnedLand(x, superFunc, z, radius, smoothingDistance, farmlandManager, farmId)
--   if g_fsgSettings.settings:getValue("paintAnywhere") then
--   	return true;
--   else
-- 	  local halfSize = radius + smoothingDistance

--   	return farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x - halfSize, z - halfSize) and farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x - halfSize, z + halfSize) and farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x + halfSize, z - halfSize) and farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x + halfSize, z + halfSize)
--   end
-- end;
-- Landscaping.isModificationAreaOnOwnedLand = Utils.overwrittenFunction(Landscaping.isModificationAreaOnOwnedLand, paintAndTerraformAnywhere.isModificationAreaOnOwnedLand);

-- -- not sure what this prevents as it didn't allow for terraforming through placeables
-- function paintAndTerraformAnywhere:hasObjectOverlapInModificationArea(superFunc, x, y, z)
--   if g_fsgSettings.settings:getValue("paintAnywhere") then
-- 	  return false;
--   else
--     local range = self.radius + self.terrainUnit * 2

--     for _, player in pairs(g_currentMission.players) do
--       if player.isControlled then
--         local pX, _, pZ = getWorldTranslation(player.rootNode)
--         local dX = pX - x
--         local dZ = pZ - z

--         if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
--           local sqrRange = range * range
--           local sqrDistance = dX * dX + dZ * dZ

--           if sqrRange >= sqrDistance then
--             return true
--           end
--         elseif math.abs(dX) <= range and math.abs(dZ) <= range then
--           return true
--         end
--       end
--     end

--     return false
--   end
-- end;
-- Landscaping.hasObjectOverlapInModificationArea = Utils.overwrittenFunction(Landscaping.hasObjectOverlapInModificationArea, paintAndTerraformAnywhere.hasObjectOverlapInModificationArea);

-- -- this allows terraforming through placeables and objects, roads and stuff 
-- function paintAndTerraformAnywhere:setBlockedAreaMap(superFunc, bitVectorMapId, channel)

--   if not g_fsgSettings.settings:getValue("paintAnywhere") then
--     setTerrainDeformationBlockedAreaMap(self.terrainDeformationId, bitVectorMapId, channel)
--   end

-- end;
-- TerrainDeformation.setBlockedAreaMap = Utils.overwrittenFunction(TerrainDeformation.setBlockedAreaMap, paintAndTerraformAnywhere.setBlockedAreaMap);



PlaceTerraformPaintAnywhere = {}

function PlaceTerraformPaintAnywhere:getHasOverlap(superFunc, x, y, z, rotY, checkFunc)
  if g_fsgSettings.settings:getValue("paintAnywhere") then
    return false, nil
  else
    return superFunc(self, x, y, z, rotY, checkFunc)
  end
end

function PlaceTerraformPaintAnywhere:getHasOverlapWithZones(superFunc, zones, x, y, z, rotY)
  if g_fsgSettings.settings:getValue("paintAnywhere") then
    return false
  else
    return superFunc(self, zones, x, y, z, rotY)
  end
end

function PlaceTerraformPaintAnywhere:getHasOverlapWithPlaces(superFunc, places, x, y, z, rotY)
  if g_fsgSettings.settings:getValue("paintAnywhere") then
    return false
  else
    return superFunc(self, places, x, y, z, rotY)
  end
end

function PlaceTerraformPaintAnywhere:getCanBePlacedAt(superFunc, x, y, z, farmId)
  if g_fsgSettings.settings:getValue("paintAnywhere") then
    return true, nil
  else
    return superFunc(self, x, y, z, farmId)
  end
end

function PlaceTerraformPaintAnywhere:isInsidePlacementPlaces(superFunc, places, x, y, z)
  if g_fsgSettings.settings:getValue("paintAnywhere") then
    return false
  else
    return superFunc(self, places, x, y, z)
  end
end

function PlaceTerraformPaintAnywhere:getIsAreaOwnedByFarm(superFunc, places, x, y, z)
  if g_fsgSettings.settings:getValue("paintAnywhere") then
    return true
  else
    return superFunc(self, places, x, y, z)
  end
end

function PlaceTerraformPaintAnywhere:getIsOnOwnedFarmland(superFunc, places, x, y, z)
  if g_fsgSettings.settings:getValue("paintAnywhere") then
    return true
  else
    return superFunc(self, places, x, y, z)
  end
end

function PlaceTerraformPaintAnywhere:verifyAccess(superFunc, x, y, z)
  if g_fsgSettings.settings:getValue("paintAnywhere") then
    return nil
  else
    return superFunc(self, x, y, z)
  end
end

function PlaceTerraformPaintAnywhere:isInsideRestrictedZone(...)
  if g_fsgSettings.settings:getValue("paintAnywhere") then
    return false
  else
    return superFunc(...)
  end
end

function PlaceTerraformPaintAnywhere:isModificationAreaOnOwnedLand(...)
  if g_fsgSettings.settings:getValue("paintAnywhere") then
    return true
  else
    return superFunc(...)
  end
end

function PlaceTerraformPaintAnywhere:hasObjectOverlapInModificationArea(...)
  if g_fsgSettings.settings:getValue("paintAnywhere") then
    return false
  else
    return superFunc(...)
  end
end

PlaceablePlacement.getHasOverlap = Utils.overwrittenFunction(PlaceablePlacement.getHasOverlap, PlaceTerraformPaintAnywhere.getHasOverlap)
PlaceablePlacement.getHasOverlapWithZones = Utils.overwrittenFunction(PlaceablePlacement.getHasOverlapWithZones, PlaceTerraformPaintAnywhere.getHasOverlapWithZones)
PlaceablePlacement.getHasOverlapWithPlaces = Utils.overwrittenFunction(PlaceablePlacement.getHasOverlapWithPlaces, PlaceTerraformPaintAnywhere.getHasOverlapWithPlaces)
PlaceablePlacement.getIsAreaOwnedByFarm = Utils.overwrittenFunction(PlaceablePlacement.getIsAreaOwnedByFarm, PlaceTerraformPaintAnywhere.getIsAreaOwnedByFarm)
PlaceablePlacement.getIsOnOwnedFarmland = Utils.overwrittenFunction(PlaceablePlacement.getIsOnOwnedFarmland, PlaceTerraformPaintAnywhere.getIsOnOwnedFarmland)
Placeable.getCanBePlacedAt = Utils.overwrittenFunction(Placeable.getCanBePlacedAt, PlaceTerraformPaintAnywhere.getCanBePlacedAt)
PlacementUtil.isInsidePlacementPlaces = Utils.overwrittenFunction(PlacementUtil.isInsidePlacementPlaces, PlaceTerraformPaintAnywhere.isInsidePlacementPlaces)
PlacementUtil.isInsideRestrictedZone = Utils.overwrittenFunction(PlacementUtil.isInsideRestrictedZone, PlaceTerraformPaintAnywhere.isInsideRestrictedZone)
ConstructionBrush.verifyAccess = Utils.overwrittenFunction(ConstructionBrush.verifyAccess, PlaceTerraformPaintAnywhere.verifyAccess)
Landscaping.isModificationAreaOnOwnedLand = Utils.overwrittenFunction(Landscaping.isModificationAreaOnOwnedLand, PlaceTerraformPaintAnywhere.isModificationAreaOnOwnedLand)
Landscaping.hasObjectOverlapInModificationArea = Utils.overwrittenFunction(Landscaping.hasObjectOverlapInModificationArea, PlaceTerraformPaintAnywhere.hasObjectOverlapInModificationArea)
