-- Author Dajoor.
-- 2018.11.23

-- add to modfolder or  modfolder/scripts add <extraSourceFiles><sourceFile filename="categorizer.lua" /></extraSourceFiles>
-- usage: [<modDesc>] <newcategory name="ITRunner" title="ITRunner" type="TOOL" img="icon_itRunnerPack.dds" /> [</modDesc>]
-- add l10n entry to modDesc
-- [<vehicle><storeData>] <category>NEWCAT</category> [</storeData></vehicle>]

Categorizer = {};

Categorizer.version = 1.1;
Categorizer.modFolder = g_currentModDirectory;
Categorizer.modDescFile = (Categorizer.modFolder.. "modDesc.xml");
Categorizer.doonce = false;


if not fileExists(Categorizer.modDescFile) then
	g_logManager:xmlWarning(modDescFile, "*** Categorizer Error : No Categories File Found!")
	return false -- throw script in any case
else

	print("*** Categorizer loading cats!");
	local modDescFile = loadXMLFile("modDesc", Categorizer.modDescFile);
	
	local i = 0
	while i < 10 do
		local orderId  = 0
		local typeisvalid = false
		
		local ndx = string.format("modDesc.newcategory(%d)", i)
		
		if not hasXMLProperty(modDescFile, ndx) then
			break
		end;
		
		local name = getXMLString(modDescFile, ndx.. "#name")
		if name == nil or name == "" then
			break
		end;
		name = name:upper()
		
		if (g_storeManager:getCategoryByName(name) ~= nil) then
			--g_logManager:xmlWarning(modDescFile, "Invalid category: '%s' exists!", tostring(name))
			break
		end;
		
		local title = getXMLString(modDescFile, ndx.. "#title")
		if title == nil or title == "" then
			title = name
		end;
		title = g_i18n:hasText(title) and g_i18n:getText(title) or title:upper()
		
		local cattype = getXMLString(modDescFile, ndx.. "#type")
		if cattype == nil or cattype == "" then
			g_logManager:xmlWarning(modDescFile, "*** Categorizer Error : No Category Type Defined!")
			break
		else
			cattype = cattype:upper()
			if (cattype == "VEHICLE") then typeisvalid = true end;
			if (cattype == "TOOL") then typeisvalid = true end;
			if (cattype == "PLACEABLE") then typeisvalid = true end;
			if (cattype == "OBJECT") then typeisvalid = true end;
		end;
		
		local img = getXMLString(modDescFile, ndx.. "#img")
		if img == nil or img == "" then
			g_logManager:xmlWarning(modDescFile, "*** Categorizer Error : No Image Defined!")
		end;
		
		if typeisvalid then
			g_storeManager:addCategory(name, title, img, StoreManager.CATEGORY_TYPE[cattype], Categorizer.modFolder)
		end;
		
		i = i + 1
	end;
	delete(modDescFile)
end;
