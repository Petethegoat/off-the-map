--Don't center world map
mwse.memory.writeNoOperation{ address = 0x5EC191, length = 0x5EC1A0 - 0x5EC191 }
mwse.memory.writeNoOperation{ address = 0x5EC1CE, length = 0x5EC1DC - 0x5EC1CE }

--Don't center local map
--mwse.memory.writeNoOperation{ address = 0x5EC051, length = 0x5EC065 - 0x5EC051 }

local externMapPlugin = include("uiexp_map_extension")
local function tryDrawMapLabel()
	externMapPlugin.tryDrawMapLabel()
end

if (externMapPlugin == nil) then
	-- nop down to cell1 = cell in RecordsHandler::mapDrawCell - works in vanilla, not with map expansion
	mwse.log("[Off The Map] No UI Expansion detected, applying vanilla map override.")
	mwse.memory.writeNoOperation{ address = 0x4C81E0, length = 0x4C83C5 - 0x4C81E0}
else
	mwse.memory.writeFunctionCall{
		address = 0x4E32FB,
		length = 0x4E3303 - 0x4E32FB,
		signature = { returns = "void" },
		call = tryDrawMapLabel,
	}
end

--- @param e uiActivatedEventData
local function onMenuMulti(e)
	e.element:findChild("MenuMulti_map").visible = false
end
event.register(tes3.event.uiActivated, onMenuMulti, { filter = "MenuMulti" })

-- duplicate here to make sure it works on new game.
local function onMenuMap(e)
	local mapMenu = tes3ui.findMenu("MenuMap")
	if not mapMenu then return end

	local player = mapMenu:findChild("MenuMap_world_player")
	-- silly hack to make it invisible permanently.
	player.scaleMode = true
	player.width = 0
	player.height = 0
end
event.register(tes3.event.uiActivated, onMenuMap, { filter = "MenuMap" })

--- @param e menuEnterEventData
local function onMenuMode(e)
	local mapMenu = tes3ui.findMenu("MenuMap")
	if not mapMenu then return end

	mapMenu:findChild("MenuMap_switch").visible = false
	local uiExpButton = mapMenu:findChild("UIEXP:MapSwitch")
	if uiExpButton ~= nil then
		uiExpButton.visible = false
		uiExpButton.parent.children[3].visible = false
	end
end
event.register(tes3.event.menuEnter, onMenuMode, { priority = -1000 })

--- @param e loadedEventData
local function loadedCallback(e)
	if tes3.player.data.offTheMap == nil then return end
	local mapMenu = tes3ui.findMenu("MenuMap")
	if not mapMenu then return end

	local player = mapMenu:findChild("MenuMap_world_player")
	-- silly hack to make it invisible permanently.
	player.scaleMode = true
	player.width = 0
	player.height = 0

	if externMapPlugin ~= nil then
		local zoomBar = mapMenu:findChild("UIEXP:MapControls").children[2]
		zoomBar.widget.current = tes3.player.data.offTheMap.zoom
		zoomBar:triggerEvent(tes3.uiEvent.partScrollBarChanged)

		local worldMap = mapMenu:findChild("MenuMap_world_panel")
		worldMap.childOffsetX = tes3.player.data.offTheMap.x
		worldMap.childOffsetY = tes3.player.data.offTheMap.y

		worldMap:getTopLevelMenu():updateLayout()
	end
end
event.register(tes3.event.loaded, loadedCallback)

--- @param e saveEventData
local function saveCallback(e)
	local mapMenu = tes3ui.findMenu("MenuMap")
	if not mapMenu then return end

	local worldMap = mapMenu:findChild("MenuMap_world_panel")
	tes3.player.data.offTheMap = {}
	local data = tes3.player.data.offTheMap
	data.x = worldMap.childOffsetX
	data.y = worldMap.childOffsetY

	if externMapPlugin ~= nil then
		local zoomBar = mapMenu:findChild("UIEXP:MapControls").children[2]
		data.zoom = zoomBar.widget.current
	end
end
event.register(tes3.event.save, saveCallback)