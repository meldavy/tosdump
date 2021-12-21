function MINIMIZED_MARKET_BUTTON_ON_INIT(addon, frame)
	addon:RegisterMsg("GAME_START", "MINIMIZED_MARKET_BUTTON_OPEN_CHECK");
end

function MINIMIZED_MARKET_BUTTON_OPEN_CHECK(frame)

end

function MINIMIZED_MARKET_BUTTON_CLICK(parent, ctrl)
    local frame = ui.GetFrame('market')
    ON_OPEN_MARKET(frame)
end