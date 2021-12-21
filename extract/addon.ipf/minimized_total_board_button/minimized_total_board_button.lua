function MINIMIZED_TOTAL_BOARD_BUTTON_ON_INIT(addon, frame)
	addon:RegisterMsg('GAME_START', 'MINIMIZED_TOTAL_BOARD_BUTTON_OPEN_CHECK')
end

function MINIMIZED_TOTAL_BOARD_BUTTON_OPEN_CHECK(frame, msg, argStr, argNum)
	local mapprop = session.GetCurrentMapProp()
	local mapCls = GetClassByType("Map", mapprop.type)
    if session.world.IsIntegrateServer() == true then
        frame:ShowWindow(0)
    else
    	frame:ShowWindow(1)

		local mapprop = session.GetCurrentMapProp()
		local mapCls = GetClassByType("Map", mapprop.type)
	
		local housingPlaceClass = GetClass("Housing_Place", mapCls.ClassName)
		if housingPlaceClass ~= nil then
			local margin = frame:GetMargin()
			frame:SetMargin(margin.left, 225, margin.right, margin.bottom)
		end
	end
end

local function SHOW_MINIMIZED_BUTTON(frame)
	local news_button = ui.GetFrame('minimizedeventbanner')
	local housing_button = ui.GetFrame('minimized_housing_promote_board')
	local party_button = ui.GetFrame('minimized_party_board')

	if frame ~= nil and frame:IsVisible() == 1 then
		frame:ShowWindow(0)
		news_button:ShowWindow(0)
		housing_button:ShowWindow(0)
		party_button:ShowWindow(0)
	else
		frame:ShowWindow(1)
		news_button:ShowWindow(1)
		housing_button:ShowWindow(1)
		party_button:ShowWindow(1)

		local frame_margin = frame:GetMargin()
		local news_margin = news_button:GetMargin()
		local housing_margin = housing_button:GetMargin()
		local party_margin = party_button:GetMargin()
		
		local mapprop = session.GetCurrentMapProp()
		local mapCls = GetClassByType("Map", mapprop.type)
		
		local housingPlaceClass = GetClass("Housing_Place", mapCls.ClassName)
		if housingPlaceClass ~= nil then
			frame:SetMargin(frame_margin.left, 239, frame_margin.right, frame_margin.bottom)
			news_button:SetMargin(news_margin.left, 244, news_margin.right, news_margin.bottom)
			housing_button:SetMargin(housing_margin.left, 239, housing_margin.right, housing_margin.bottom)
			party_button:SetMargin(party_margin.left, 239, party_margin.right, party_margin.bottom)
		else
			frame:SetMargin(frame_margin.left, 181, frame_margin.right, frame_margin.bottom)
			news_button:SetMargin(news_margin.left, 185, news_margin.right, news_margin.bottom)
			housing_button:SetMargin(housing_margin.left, 181, housing_margin.right, housing_margin.bottom)
			party_button:SetMargin(party_margin.left, 181, party_margin.right, party_margin.bottom)
		end
	end

end

function MINIMIZED_TOTAL_BOARD_BUTTON_CLICK(parent, ctrl)
	local frame = ui.GetFrame('minimized_folding_board')
	SHOW_MINIMIZED_BUTTON(frame)
end
