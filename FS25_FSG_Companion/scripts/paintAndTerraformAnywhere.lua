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
