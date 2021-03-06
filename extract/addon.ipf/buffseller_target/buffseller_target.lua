
function BUFFSELLER_TARGET_ON_INIT(addon, frame)


end

function TARGET_AUTOSELL_LIST(groupName, sellType, handle)
	if sellType == AUTO_SELL_BUFF or sellType == AUTO_SELL_ORACLE_SWITCHGENDER then
		TARGET_BUFF_AUTOSELL_LIST(groupName, sellType, handle);
	else
		TARGET_PERSONALSHOP_LIST(groupName, sellType, handle);
	end

end

function TARGET_BUFF_AUTOSELL_LIST(groupName, sellType, handle)
	local frame = ui.GetFrame("buffseller_target");
	frame:ShowWindow(1);

	frame:SetUserValue("HANDLE", handle);
	frame:SetUserValue("GROUPNAME", groupName);
	frame:SetUserValue("SELLTYPE", sellType);
	local ctrlsetType = "buffseller_target";
	local ctrlsetUpdateFunc = UPDATE_BUFFSELLER_SLOT_TARGET;
	
	local titleName = session.autoSeller.GetTitle(groupName);
	local gbox = frame:GetChild("gbox");
	gbox:RemoveAllChild();
	
	local cnt = session.autoSeller.GetCount(groupName);
	for i = 0 , cnt - 1 do
		local info = session.autoSeller.GetByIndex(groupName, i);
		local ctrlSet = gbox:CreateControlSet(ctrlsetType, "CTRLSET_" .. i,  ui.CENTER_HORZ, ui.TOP, 0, 0, 0, 0);
		ctrlsetUpdateFunc(ctrlSet, info);
		ctrlSet:SetUserValue("TYPE", info.classID);
		ctrlSet:SetUserValue("INDEX", i);
	end

	GBOX_AUTO_ALIGN(gbox, 10, 10, 10, true, false);
	frame:ShowWindow(1);
	REGISTERR_LASTUIOPEN_POS(frame);
end

function UPDATE_BUFFSELLER_SLOT_TARGET(ctrlSet, info)
	local buffCls = GetClassByType('Buff', info.classID);
	SET_BUFFSELLER_CTRLSET(ctrlSet, buffCls.ClassName, info.level, 'Pardoner_SpellShop', info.price, info.remainCount);
end

function BUY_BUFF_AUTOSELL(ctrlSet, btn)

	local frame = ctrlSet:GetTopParentFrame();
	local sellType = frame:GetUserIValue("SELLTYPE");
	local groupName = frame:GetUserValue("GROUPNAME");
	local index = ctrlSet:GetUserIValue("INDEX");
	local itemInfo = session.autoSeller.GetByIndex(groupName, index);
	local buycount =  GET_CHILD(ctrlSet, "price");
	if itemInfo == nil then
		return;
	end

	local cnt = 1;
	if buycount ~= nil then
		cnt = buycount:GetNumber();
	end
	
	if cnt < 1 then
		cnt = 1;
	end

	local totalPrice = itemInfo.price * cnt;
	if IsGreaterThanForBigNumber(totalPrice, GET_TOTAL_MONEY_STR()) == 1 then
		ui.SysMsg(ClMsg("NotEnoughMoney"));
		return;
	end
	
	local strscp = string.format( "EXEC_BUY_AUTOSELL(%d, %d, %d, %d)", frame:GetUserIValue("HANDLE"), index, cnt, sellType);
--	local msg = ClMsg("ReallyBuy?")
	local msg = ScpArgMsg("ReallyBuy?{Price}", "Price", GET_COMMAED_STRING(totalPrice));
	ui.MsgBox(msg, strscp, "None");
end

function EXEC_BUY_AUTOSELL(handle, index, cnt, sellType)
	session.autoSeller.Buy(handle, index, cnt, sellType);
end






