local addon, Taxi = ...
local waypoint = nil
local pointList = {}
local interval = 1
local itemList = Taxi.list
local next = next

if not TaxiOptions then
    TaxiOptions = {
        enabled = true,
		type = "treasure",
    }
end

local frame = CreateFrame("Frame")

local function RemoveWaypoint()
    if waypoint then
		TomTom:RemoveWaypoint(waypoint)
		waypoint = nil
	end
end

local function CreateWaypoint(point)
	if waypoint then
		local m, f, x, y = unpack(waypoint)
		if m == point.zone and f == point.level and x == point.treasure.x and y == point.treasure.y then
			return
		end
	end
	
    local title = point.treasure.desc

    if point.treasure.item and not (point.treasure.item == "") then
        if (point.treasure.item == "824" or point.treasure.item == "823") then
            local currency = GetCurrencyInfo(point.treasure.item)
            if currency then
                title = title.."\nLoot: " .. currency;
            end
        else
            local item = select(2, GetItemInfo(point.treasure.item))

            if item then
                title = title.."\nLoot: " .. item;
            end
        end
    end

    if point.treasure.info and not (point.treasure.info == "") then
        title = title.."\nLoot Info: " .. point.treasure.info;
    end

	RemoveWaypoint()
    waypoint = TomTom:AddMFWaypoint(tonumber(point.zone), tonumber(point.level), tonumber(point.treasure.x), tonumber(point.treasure.y), {title = title, persistent = nil, minimap = true, world = true, silent = true, crazy = true, cleardistance = 0})
end

local function ClearPointList()
	for zone, zoneList in pairs(pointList) do
		for level, levelList in pairs(zoneList) do
			for index, point in pairs(levelList) do
				TomTom:RemoveWaypoint(point)
			end
		end
	end
	pointList = {}
end

local function GetClosest(zone, level, list)
    local dist = 999999999
    local closest = nil
	
    for k, v in pairs(list) do
		local point = TomTom:AddMFWaypoint(tonumber(zone), tonumber(level), tonumber(v.x), tonumber(v.y), {title = v.desc, persistent = nil, minimap = false, world = TaxiOptions.showAll, silent = true, crazy = false, cleardistance = 0, distCheck = true})
		local pointDist = TomTom:GetDistanceToWaypoint(point)
		
		if TaxiOptions.showAll then
			table.insert(pointList[zone][level], point)
		else
			if point.distCheck then
				TomTom:RemoveWaypoint(point)
			end
		end
		
		if pointDist and pointDist < dist then
			dist = pointDist
			closest = {zone = zone, level = level, treasure = v}
		end
    end
    
    if closest then
		CreateWaypoint(closest)
	else
		RemoveWaypoint()
    end
end

local function onUpdate(self,elapsed)
	-- TaxiOptions.reformat = nil
    -- if not TaxiOptions.test then
		-- TaxiOptions.test = {}
		-- for type, typeList in pairs(itemList) do
			-- TaxiOptions.test[type] = {}
			-- for continent, continentList in pairs(typeList) do
				-- TaxiOptions.test[type][continent] = {}
				-- for zone, zoneList in pairs(continentList) do
					-- TaxiOptions.test[type][continent][zone] = {}
					-- for level, levelList in pairs(zoneList) do
						-- TaxiOptions.test[type][continent][zone][level] = {}
						-- for index, item in pairs(levelList) do
							-- if not TaxiOptions.test[type][continent][zone][level] then
								-- TaxiOptions.test[type][continent][zone][level] = {}
							-- end
							
							-- local obj = {x = item.x, y = item.y, item = item.item, info = item.info, checks = {}, desc = item.desc}
							
							-- if item.checks["quest"] then
								-- obj.checks.quest = {}
								-- table.insert(obj.checks.quest, item.checks["quest"])
							-- end
							
							-- if item.checks["item"] then
								-- obj.checks.item = {}
								-- table.insert(obj.checks.item, item.checks["item"])
							-- end
							
							-- table.insert(TaxiOptions.test[type][continent][zone][level], obj)
						-- end
					-- end
				-- end
			-- end
		-- end
	-- end
	
    interval = interval + elapsed

	if interval >= 1 and not WorldMapFrame:IsVisible() then
		interval = 0
		if WorldMapFrame:IsVisible() then
			local zone = GetCurrentMapAreaID()
			local level = GetCurrentMapDungeonLevel()
			
			if not pointList[zone] or not pointList[zone][level] then
				ClearPointList()
			end
		else
			if itemList then
				if itemList[TaxiOptions.type] then
					local continent = GetCurrentMapContinent()
					if itemList[TaxiOptions.type][continent] then
						local zone = GetCurrentMapAreaID()
						if itemList[TaxiOptions.type][continent][zone] then
							local level = GetCurrentMapDungeonLevel()
							if itemList[TaxiOptions.type][continent][zone][level] then
								for index, item in pairs(itemList[TaxiOptions.type][continent][zone][level]) do
									if item.checks.quest then
										for k, v in pairs(item.checks.quest) do
											if IsQuestFlaggedCompleted(v) then
												itemList[TaxiOptions.type][continent][zone][level][index] = nil
												break
											end
										end
									end
									
									if item.checks["item"] then
										for k, v in pairs(item.checks.quest) do
											if GetItemCount(v) > 0 then
												itemList[TaxiOptions.type][continent][zone][level][index] = nil
												break
											end
										end
									end
								end
								
								if next(itemList[TaxiOptions.type][continent][zone][level]) == nil then
									itemList[TaxiOptions.type][continent][zone][level] = nil
									
									if next(itemList[TaxiOptions.type][continent][zone]) == nil then
										itemList[TaxiOptions.type][continent][zone] = nil
										
										if next(itemList[TaxiOptions.type][continent]) == nil then
											itemList[TaxiOptions.type][continent] = nil
											
											if next(itemList[TaxiOptions.type]) == nil then
												itemList[TaxiOptions.type] = nil
											end
										end
									end
								else
									ClearPointList()
									pointList[zone] = {}
									pointList[zone][level] = {}
									
									GetClosest(zone, level, itemList[TaxiOptions.type][continent][zone][level])
									return
								end
							end
						end
					end
				end
			end
			ClearPointList()
			RemoveWaypoint()
		end
    end
end

local function onEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName ~= addon then return end
        if TaxiOptions.enabled then
            frame:SetScript("OnUpdate", onUpdate)
        else
            frame:SetScript("OnUpdate", nil)
        end
    else
		RemoveWaypoint()
		ClearPointList()
    end
end

frame:SetScript("OnEvent", onEvent)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGOUT")

SLASH_TAXI1 = "/taxi"

SlashCmdList["TAXI"] = function(msg)
	local tokens = {}
	for token in msg:gmatch("%S+") do table.insert(tokens, token) end
	
	if table.getn(tokens) > 0 then
		if tokens[1] == "type" then
			if tokens[2] and itemList[tokens[2]] then
				TaxiOptions.type = tokens[2]
				DEFAULT_CHAT_FRAME:AddMessage(string.format("Type set to: %s", TaxiOptions.type))
				RemoveWaypoint()
				ClearPointList()
			else
				DEFAULT_CHAT_FRAME:AddMessage(string.format("Current type is %s", TaxiOptions.type))
				DEFAULT_CHAT_FRAME:AddMessage("Available types are:")
				for k, v in pairs(itemList) do
					DEFAULT_CHAT_FRAME:AddMessage(string.format("    %s", k))
				end
			end
		elseif tokens[1] == "show" then
			TaxiOptions.showAll = not TaxiOptions.showAll
			if TaxiOptions.showAll then
				DEFAULT_CHAT_FRAME:AddMessage("Showing all points on the map")
			else
				DEFAULT_CHAT_FRAME:AddMessage("No longer showing all points on the map")
				ClearPointList()
			end
		else
			DEFAULT_CHAT_FRAME:AddMessage("Usage:")
			DEFAULT_CHAT_FRAME:AddMessage("    /taxi")
			DEFAULT_CHAT_FRAME:AddMessage("        - turns the addons on and off")
			DEFAULT_CHAT_FRAME:AddMessage("    /taxi type [type]")
			DEFAULT_CHAT_FRAME:AddMessage("        - switch between waypoint types (mount, rare, treasure)")
			DEFAULT_CHAT_FRAME:AddMessage("    /taxi show")
			DEFAULT_CHAT_FRAME:AddMessage("        - toggle showing all possible points on the map ")
		end
	elseif TaxiOptions.enabled then
        frame:SetScript("OnUpdate", nil)
        TaxiOptions.enabled = false
        if waypoint then
            TomTom:RemoveWaypoint(waypoint)
        end
        DEFAULT_CHAT_FRAME:AddMessage("TreasureTaxi disabled")
    else
        frame:SetScript("OnUpdate", onUpdate)
        TaxiOptions.enabled = true
        DEFAULT_CHAT_FRAME:AddMessage("TreasureTaxi enabled")
    end
end
