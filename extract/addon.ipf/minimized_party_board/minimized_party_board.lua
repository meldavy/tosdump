function MINIMIZED_PARTY_BOARD_ON_INIT(addon, frame)
	addon:RegisterMsg("GAME_START", "MINIMIZED_PARTY_BOARD_BUTTON_OPEN_CHECK");
end

function MINIMIZED_PARTY_BOARD_BUTTON_OPEN_CHECK(frame)
    local mapprop = session.GetCurrentMapProp()
	if mapprop == nil then
		frame:ShowWindow(0)
		return
	end

	local mapCls = GetClassByType("Map", mapprop.type)
	if mapCls == nil then
		frame:ShowWindow(0)
		return
	end

	local housingPlaceClass = GetClass("Housing_Place", mapCls.ClassName)
    if session.world.IsIntegrateServer() == true or housingPlaceClass ~= nil then
        frame:ShowWindow(0)
    else
    	frame:ShowWindow(1)
	end
end

function MINIMIZED_PARTY_BOARD_CLICK(parent, ctrl)
    ui.ToggleFrame('party_search_board')
end