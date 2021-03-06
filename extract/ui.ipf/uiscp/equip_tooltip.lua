-- equip_tooltip.lua

local function replace(text, to_be_replaced, replace_with)
	local retText = text
	local strFindStart, strFindEnd = string.find(text, to_be_replaced)	
    if strFindStart ~= nil then
		local nStringCnt = string.len(text)		
		retText = string.sub(text, 1, strFindStart-1) .. replace_with ..  string.sub(text, strFindEnd+1, nStringCnt)		
    else
        retText = text
	end
	
    return retText
end


function ITEM_TOOLTIP_WEAPON(tooltipframe, invitem, strarg, usesubframe)	
	ITEM_TOOLTIP_EQUIP(tooltipframe, invitem, strarg, usesubframe)
end

function ITEM_TOOLTIP_ARMOR(tooltipframe, invitem, strarg, usesubframe, isForgery)	
	ITEM_TOOLTIP_EQUIP(tooltipframe, invitem, strarg, usesubframe, isForgery) ;
end

local function _CREATE_SEAL_OPTION(box, ypos, step, propName, propValue, drawLine, style, drawLockImg)
	if drawLine == true then
		local labelline = box:CreateControl('labelline', 'line'..step, 5, ypos, box:GetWidth() - 10, 4);
		ypos = ypos + 10;
	end

	local infoTextStyle = '{@st41b}{s18}{#FFCC66}';
	local valueTextStyle = '{@st41b}{s16}{#ffa800}';
	if style ~= nil then
		infoTextStyle = style;
		valueTextStyle = "{@st41b}{s16}{#bfbfbf}";
	end
	
	local infoText = box:CreateControl('richtext', 'infoText'..step, 10, ypos, box:GetWidth(), 30);
	infoText:SetText(infoTextStyle..ScpArgMsg('QUEST_STEPREWARD_MSG2', 'STEP', step)..ClMsg('CollectionMagicText'));
	ypos = ypos + infoText:GetHeight();
	
	local valueText = box:CreateControl('richtext', 'valueText'..step, 20, ypos, box:GetWidth(), 30);
	valueText:SetText(valueTextStyle..GET_OPTION_VALUE_OR_PERCECNT_STRING(propName, propValue));
	ypos = ypos + infoText:GetHeight();
	AUTO_CAST(valueText);
	valueText:AdjustFontSizeByWidth(box:GetWidth() - 20);

	if drawLockImg == true then
		local LOCK_IMG_SIZE = 35;
		local lockImg = box:CreateControl('picture', 'lockImg'..step, 0, 0, LOCK_IMG_SIZE, LOCK_IMG_SIZE);
		AUTO_CAST(lockImg);
		lockImg:SetGravity(ui.RIGHT, ui.TOP);
		lockImg:SetMargin(0, infoText:GetY(), 5, 0);
		lockImg:SetImage('icon_lock_tooltip_2');
		lockImg:SetEnableStretch(1);
	end

	return ypos;
end

local function _CREATE_SEAL_OPTION_HIDE(box, ypos, step, drawLine, sealItemObj)
	local function CreateLine(box, step, ypos)
		local labelline = box:CreateControl('labelline', 'line'..step, 5, ypos, box:GetWidth() - 10, 4);
		ypos = ypos + 10;
		return ypos;
	end

	if sealItemObj.SealType == 'random' then		
		if drawLine == true then
			ypos = CreateLine(box, step, ypos);
		end

		local pic = box:CreateControl('picture', 'sealedPic'..step, 5, ypos, 404, 61);
		AUTO_CAST(pic);
		pic:SetImage('medal_lock_skin');
		pic:SetEnableStretch(1);
	
		ypos = ypos + pic:GetHeight();
	else -- unlock type
		local optionName, optionValue = GetSealUnlockOption(sealItemObj.ClassName, step);		
		if optionName ~= nil then
			if drawLine == true then
				ypos = CreateLine(box, step, ypos);
			end

			ypos = _CREATE_SEAL_OPTION(box, ypos, step, optionName, optionValue, false, '{@st41b}{s18}{#bfbfbf}', true);
		end
	end

	return ypos;
end

local function _DRAW_SEAL_OPTION(tooltipframe, invitem, ypos, mainframename)
	local gBox = GET_CHILD(tooltipframe, mainframename);
	gBox:RemoveChild('tooltip_equipitem_tooltip_seal_type_n_weight');
	if invitem.ClassType ~= 'Seal' or invitem.StringArg == "Seal_Material" then
		return ypos;
	end

	local item_tooltip_seal = gBox:CreateOrGetControlSet('item_tooltip_seal', 'item_tooltip_seal', 0, ypos + 2);	
	local _ypos = 0;
	for i = 1, invitem.MaxReinforceCount do
		local optionName = TryGetProp(invitem, 'SealOption_'..i, 'None');		
		if optionName ~= 'None' then
			_ypos = _CREATE_SEAL_OPTION(item_tooltip_seal, _ypos, i, optionName, invitem['SealOptionValue_'..i], i ~= 1);
		else -- ?????? ??????
			_ypos = _CREATE_SEAL_OPTION_HIDE(item_tooltip_seal, _ypos, i, i ~= 1, invitem);			
		end		
	end
	item_tooltip_seal:Resize(item_tooltip_seal:GetWidth(), _ypos + 7);

	ypos = ypos + item_tooltip_seal:GetHeight();
	return ypos;
end

function ITEM_TOOLTIP_EQUIP(tooltipframe, invitem, strarg, usesubframe, isForgery)    	
	if isForgery == nil then
		isForgery = false;
	end
    
	tolua.cast(tooltipframe, "ui::CTooltipFrame");
    
	local mainframename = 'equip_main'
	local ichorframename = 'equip_main_ichor'
	local addinfoframename = 'equip_main_addinfo'
    
	if usesubframe == "usesubframe" or usesubframe == "usesubframe_recipe" then
		mainframename = 'equip_sub'
		addinfoframename = 'equip_sub_addinfo'
	end
    
	local ypos = 0

	if IS_USE_SET_TOOLTIP(invitem) == 1 then		
		ypos = DRAW_EQUIP_COMMON_TOOLTIP_SMALL_IMG(tooltipframe, invitem, mainframename, isForgery); -- ???????????? ??????????????? ????????? ?????????
    else
		ypos = DRAW_EQUIP_COMMON_TOOLTIP(tooltipframe, invitem, mainframename, isForgery); -- ???????????? ??????????????? ????????? ?????????
		ypos = DRAW_ITEM_TYPE_N_WEIGHT(tooltipframe, invitem, ypos, mainframename) -- ??????, ??????.
	end
	
	ypos = _DRAW_SEAL_OPTION(tooltipframe, invitem, ypos, mainframename); -- ??????

	local basicTooltipProp = 'None';
	if invitem.BasicTooltipProp ~= 'None' and TryGetProp(invitem, 'GroupName', 'None') ~= 'Arcane' then
		local basicTooltipPropList = StringSplit(invitem.BasicTooltipProp, ';');
		for i = 1, #basicTooltipPropList do
			basicTooltipProp = basicTooltipPropList[i];
			ypos = DRAW_EQUIP_ATK_N_DEF(tooltipframe, invitem, ypos, mainframename, strarg, basicTooltipProp); -- ?????????, ?????????, ?????? ????????? 
		end
	end

	local value = IS_TOGGLE_EQUIP_ITEM_TOOLTIP_DESC();    
    if basicTooltipProp ~= 'None' and value ~= 1 then
    		local bg_ypos = ypos -- ??????????????? box ypos
        	local itemGuid = tooltipframe:GetUserValue('TOOLTIP_ITEM_GUID');
        	local isEquiped = 1;
        	if session.GetEquipItemByGuid(itemGuid) == nil then
        		isEquiped = 0
        	end

        	local tooltipMainFrame = GET_CHILD(tooltipframe, mainframename, 'ui::CGroupBox');
        	DRAW_TOOLTIP_SUB_BG(tooltipMainFrame, bg_ypos)

        	ypos = SET_REINFORCE_TEXT(tooltipMainFrame, invitem, ypos, isEquiped, basicTooltipProp);
        	ypos = SET_TRANSCEND_TEXT(tooltipMainFrame, invitem, ypos, isEquiped);
        	ypos = SET_EVOLVED_TEXT(tooltipMainFrame, invitem, ypos, isEquiped);
        	ypos = SET_BUFF_TEXT(tooltipMainFrame, invitem, ypos, strarg);
        	ypos = SET_REINFORCE_BUFF_TEXT(tooltipMainFrame, invitem, ypos);
        
        	local bg_height = ypos - bg_ypos		
        	RESIZE_TOOLTIP_SUB_BG(tooltipMainFrame, bg_ypos, bg_height)
	end
    
	if invitem.InheritanceItemName ~= nil and invitem.InheritanceItemName ~= "None" then
		local inheritanceItem = GetClass('Item', invitem.InheritanceItemName)
		ypos = DRAW_EQUIP_PROPERTY(tooltipframe, invitem, inheritanceItem, ypos, mainframename) -- ?????? ????????????
	else
		ypos = DRAW_EQUIP_PROPERTY(tooltipframe, invitem, nil, ypos, mainframename) -- ?????? ????????????
	end

	if TryGetProp(invitem, 'GroupName', 'None') ~= 'Arcane' then
		ypos = DRAW_EQUIP_SOCKET_COUNT(tooltipframe, invitem, ypos, mainframename);
	end
    
	if IS_NEED_DRAW_GEM_TOOLTIP(invitem) == true then
		ypos = DRAW_EQUIP_SOCKET(tooltipframe, invitem, ypos, mainframename); -- ?????? ??? ??????
    end
    
	-- ** ????????? ??? ?????? ??????
	if IS_NEED_DRAW_AETHER_GEM_TOOPTIP(invitem) == true then
		ypos = DRAW_AETHER_SOCKET_FOR_EQUIP(tooltipframe, invitem, ypos, mainframename) -- ????????? ?????? ????????? ?????? ??? ??????
	end
    
	ypos = DRAW_EQUIP_MEMO(tooltipframe, invitem, ypos, mainframename) -- ?????? ??? ??? ????????? ??????
    ypos = DRAW_EQUIP_DESC(tooltipframe, invitem, ypos, mainframename) -- ?????? ?????????
    
	if IS_USE_SET_TOOLTIP(invitem) ~= 1 then
		ypos = DRAW_AVAILABLE_PROPERTY(tooltipframe, invitem, ypos, mainframename) -- ????????????, ????????????, ??????, ?????? ?????? ??????		
	end

	ypos = DRAW_EQUIP_TRADABILITY(tooltipframe, invitem, ypos, mainframename) -- ?????? ??????
	   
	if TryGetProp(invitem, 'EquipActionType', 'None') == 'EquipCharacterBelonging' and TryGetProp(invitem, 'CharacterBelonging', 0) == 0 then
		ypos = DRAW_EQUIP_BELONGING(tooltipframe, invitem, ypos, mainframename, 'char_belonging') -- ????????? ????????? ??????
	elseif TryGetProp(invitem, 'EquipActionType', 'None') == 'EquipTeamBelonging' and TryGetProp(invitem, 'TeamBelonging', 0) == 0 then
		ypos = DRAW_EQUIP_BELONGING(tooltipframe, invitem, ypos, mainframename, 'team_belonging') -- ????????? ??? ??????
	end

	if IS_USE_SET_TOOLTIP(invitem) == 1 then
    	ypos = DRAW_CANNOT_REINFORCE(tooltipframe, invitem, ypos, mainframename) -- ?????? ??? ????????????
    end

	ypos = DRAW_EQUIP_PR_N_DUR(tooltipframe, invitem, ypos, mainframename) -- ????????? ??? ?????????
	ypos = DRAW_EQUIP_ONLY_PR(tooltipframe, invitem, ypos, mainframename) -- ????????? ??? ?????? ????????? ????????? ?????? (?????? ??????????????? ????????? ????????????)
	ypos = DRAW_EQUIP_VIBORA_REFINE(tooltipframe, invitem, ypos, mainframename)  -- ???????????? ??????(???????????? ??????)
	ypos = DRAW_EQUIP_GODDESS_REFINE(tooltipframe, invitem, ypos, mainframename)  -- ?????? ?????? ??????(???????????? ??????)	
	
    local isHaveLifeTime = TryGetProp(invitem, "LifeTime", 0);	
    
	if 0 == tonumber(isHaveLifeTime) then
		ypos = DRAW_SELL_PRICE(tooltipframe, invitem, ypos, mainframename);
	else
		ypos = DRAW_REMAIN_LIFE_TIME(tooltipframe, invitem, ypos, mainframename);
	end
    
    ypos = DRAW_TOGGLE_EQUIP_DESC(tooltipframe, invitem, ypos, mainframename); -- ????????? ?????? ??????

    -- ?????? ??????????????? (????????? ????????? ??????)
    if IS_NEED_TO_DRAW_SUBFRAME_ICHOR(invitem) == true then
        local ypos_sub = 0

        if invitem.InheritanceItemName ~= nil and invitem.InheritanceItemName ~= "None" then
            local inheritanceItem = GetClass('Item', invitem.InheritanceItemName)
            ypos_sub = DRAW_EQUIP_SUBFRAME_RANDOM_ICHOR(tooltipframe, invitem, ypos_sub, ichorframename) -- ??????????????? ?????? ?????????
            ypos_sub = DRAW_EQUIP_SUBFRAME_FIXED_ICHOR(tooltipframe, invitem, inheritanceItem, ypos_sub, ichorframename) -- ??????????????? ?????? ?????????

        else
            ypos_sub = DRAW_EQUIP_SUBFRAME_RANDOM_ICHOR(tooltipframe, invitem, ypos_sub, ichorframename) -- ??????????????? ?????? ?????????
            ypos_sub = DRAW_EQUIP_SUBFRAME_FIXED_ICHOR(tooltipframe, invitem, nil, ypos_sub, ichorframename) -- ??????????????? ?????? ?????????
        end

        -- ?????????????????? ?????? ?????????????????? ????????? ??? ??????
        if usesubframe == "usesubframe" or usesubframe == "usesubframe_recipe" then
            GET_CHILD(tooltipframe, ichorframename, 'ui::CGroupBox'):ShowWindow(0)
        end
    end

    -- ????????? ???????????????
	DRAW_EQUIP_SET(tooltipframe, invitem, 0, addinfoframename) -- ???????????????
    
    local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')
    gBox:Resize(gBox:GetWidth(), ypos)
end

-- ?????? ??????
function DRAW_EQUIP_COMMON_TOOLTIP(tooltipframe, invitem, mainframename, isForgery)	
	local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')
	gBox:RemoveAllChild()
	
    if invitem.ItemGrade == 0 then -- ?????? ???????????? ????????? ??????: 2~3?????? ??????
        local SkinName  = GET_ITEM_TOOLTIP_SKIN(invitem);
    	gBox:SetSkinName('premium_skin');
    else
        local SkinName  = GET_ITEM_TOOLTIP_SKIN(invitem);
    	gBox:SetSkinName('test_Item_tooltip_equip2');
    end

	local equipCommonCSet = gBox:CreateControlSet('tooltip_equip_common', 'equip_common_cset', 0, 0);
	tolua.cast(equipCommonCSet, "ui::CControlSet");

	local GRADE_FONT_SIZE = equipCommonCSet:GetUserConfig("GRADE_FONT_SIZE"); -- ?????? ???????????? ??? ??????

	-- ????????? ?????? ????????? : grade??????
	local item_bg = GET_CHILD(equipCommonCSet, "item_bg", "ui::CPicture");
	local needAppraisal = TryGetProp(invitem, "NeedAppraisal");
	local needRandomOption = TryGetProp(invitem, "NeedRandomOption")
	local gradeBGName = GET_ITEM_BG_PICTURE_BY_GRADE(invitem.ItemGrade, needAppraisal, needRandomOption)
	item_bg:SetImage(gradeBGName);
	-- ????????? ?????????
	local itemPicture = GET_CHILD(equipCommonCSet, "itempic", "ui::CPicture");
	if (needAppraisal ~= nil and needAppraisal == 1) or (needRandomOption ~= nil and needRandomOption == 1) then
		itemPicture:SetColorTone("FF111111");
	end

	if invitem.TooltipImage ~= nil and invitem.TooltipImage ~= 'None' then
	
    	if invitem.ClassType ~= 'Outer' and invitem.ClassType ~= 'SpecialCostume' then
			imageName = GET_EQUIP_ITEM_IMAGE_NAME(invitem, "TooltipImage")
    		itemPicture:SetImage(imageName);
    		itemPicture:ShowWindow(1);

    	else -- ???????????? ????????????, ??????PC??? ?????? ????????? ???????????????, ??????PC??? ?????? ????????? ?????????????????? ??????
            local gender = 0;
            if GetMyPCObject() ~= nil then
                local pc = GetMyPCObject();
                gender = pc.Gender;
            else
                gender = barrack.GetSelectedCharacterGender();
            end

			-- ???????????? ????????? ???????????? ?????? ????????? ????????? ??????
			if tooltipframe:GetTopParentFrameName() == 'compare' then
				local compare = ui.GetFrame('compare');
				gender = compare:GetUserIValue('COMPARE_PC_GENDER');
			end

			local tempiconname = ''
			local origin = invitem.TooltipImage;
			local reverseIconName = origin:reverse();

			local underBarIndex = string.find(reverseIconName, '_');
			if underBarIndex ~= nil then
                tempiconname = string.sub(reverseIconName, 0, underBarIndex-1);
    			tempiconname = tempiconname:reverse();
    		end
			
            if tempiconname == "both" then
                local bothIndex = string.find(origin, '_both');
                tooltipImg = string.sub(invitem.TooltipImage, 0, bothIndex - 1);
        		itemPicture:SetImage(tooltipImg);
			elseif tempiconname ~= "m" and tempiconname ~= "f" then
				if gender == 1 then
        			tooltipImg = invitem.TooltipImage.."_m"
        			itemPicture:SetImage(tooltipImg);
        		else
        			tooltipImg = invitem.TooltipImage.."_f"
        			itemPicture:SetImage(tooltipImg);
        		end
			else
				itemPicture:SetImage(invitem.TooltipImage);
			end

    	    
    	end
	else
		itemPicture:ShowWindow(0);
	end


	-- ????????? ????????? 
	local itemNowEquip = GET_CHILD(equipCommonCSet, "nowequip");
	if IsEquiped(invitem) == 1 then
		itemNowEquip:ShowWindow(1)
	else
		itemNowEquip:ShowWindow(0)
	end

	-- ?????????
	local forgeryEquip = GET_CHILD_RECURSIVELY(equipCommonCSet, 'forgeryequip');
	if mainframename == 'equip_main' and isForgery == true and tooltipframe:GetTopParentFrameName() == 'inventory' then
		forgeryEquip:ShowWindow(1);
		itemNowEquip:ShowWindow(0);
	else
		forgeryEquip:ShowWindow(0);
	end
	
	-- ???????????? 
	local itemCantRFPicture = GET_CHILD(equipCommonCSet, "cantreinforce", "ui::CPicture");
	local itemCantRFText = GET_CHILD(equipCommonCSet, "cantrf_text", "ui::CPicture");
	if invitem.Reinforce_Type == "None" then
		itemCantRFPicture:ShowWindow(1);
		itemCantRFText:ShowWindow(1);
	else
		itemCantRFPicture:ShowWindow(0);
		itemCantRFText:ShowWindow(0);
	end

	-- ??? ?????????
	--SET_GRADE_TOOLTIP(equipCommonCSet, invitem, GRADE_FONT_SIZE);

	-- ????????? ?????? ??????
	local itemGuid = tooltipframe:GetUserValue('TOOLTIP_ITEM_GUID');
	local isEquipedItem = 0;
	if session.GetEquipItemByGuid(itemGuid) ~= nil then
		isEquipedItem = 1;
	end

	local fullname = GET_FULL_NAME(invitem, true, isEquipedItem);	
	local nameChild = GET_CHILD(equipCommonCSet, "name", "ui::CRichText");
	nameChild:SetText(fullname);
	nameChild:AdjustFontSizeByWidth(nameChild:GetWidth());		-- ?????? ???????????? ??????
	nameChild:SetTextAlign("center","center");				-- ?????? ??????
	
	gBox:Resize(gBox:GetWidth(),gBox:GetHeight()+equipCommonCSet:GetHeight())

	local retypos = equipCommonCSet:GetHeight();

	return retypos;
end

-- ?????? ????????? ?????? ?????? ??????
function DRAW_EQUIP_COMMON_TOOLTIP_SMALL_IMG(tooltipframe, invitem, mainframename, isForgery)
	local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')
	gBox:RemoveAllChild()
	
    if invitem.ItemGrade == 0 then -- ?????? ???????????? ????????? ??????: 2~3?????? ??????
        local SkinName  = GET_ITEM_TOOLTIP_SKIN(invitem);
    	gBox:SetSkinName('premium_skin');
    else
        local SkinName  = GET_ITEM_TOOLTIP_SKIN(invitem);
    	gBox:SetSkinName('test_Item_tooltip_equip2');
    end

	local equipCommonCSet = gBox:CreateControlSet('tooltip_equip_small_img', 'equip_common_cset', 0, 0);
	tolua.cast(equipCommonCSet, "ui::CControlSet");

	local legendTitle = GET_CHILD_RECURSIVELY(equipCommonCSet, "legendTitle")
	legendTitle:ShowWindow(0)

	local evolvedGoddessTitle = GET_CHILD_RECURSIVELY(equipCommonCSet, "evolvedGoddessTitle")
	evolvedGoddessTitle:ShowWindow(0)
--	local GRADE_FONT_SIZE = equipCommonCSet:GetUserConfig("GRADE_FONT_SIZE"); -- ?????? ???????????? ??? ??????
	
	local score = GET_GEAR_SCORE(invitem)
	local score_text = ''
	if score > 0 then
		score_text = ' (' .. score .. ')'
	end

	local itemClass = GetClassByType("Item", invitem.ClassID);
	local gradeText = equipCommonCSet:GetUserConfig("GRADE_TEXT_FONT")
	if itemClass.ItemGrade == 1 then
		gradeText = gradeText .. equipCommonCSet:GetUserConfig("NORMAL_GRADE_TEXT")
	elseif itemClass.ItemGrade == 2 then
		gradeText = gradeText .. equipCommonCSet:GetUserConfig("MAGIC_GRADE_TEXT")
	elseif itemClass.ItemGrade == 3 then
		gradeText = gradeText .. equipCommonCSet:GetUserConfig("RARE_GRADE_TEXT")
	elseif itemClass.ItemGrade == 4 then
		gradeText = gradeText .. equipCommonCSet:GetUserConfig("UNIQUE_GRADE_TEXT")
	elseif itemClass.ItemGrade == 5 then
		gradeText = gradeText .. equipCommonCSet:GetUserConfig("LEGEND_GRADE_TEXT")		
	elseif itemClass.ItemGrade == 6 then
		gradeText = gradeText .. equipCommonCSet:GetUserConfig("GODDESS_GRADE_TEXT")
	end

	gradeText = gradeText .. score_text

	local transcend = TryGetProp(invitem, "Transcend");
	if transcend ~= nil and transcend > 0 then -- ????????? ?????? ?????? title ??????
		if TryGetProp(invitem, "ItemGrade", 0) == 6 then
			if TryGetProp(invitem, "EvolvedItemLv", 0) > TryGetProp(invitem, "UseLv", 0) then
				evolvedGoddessTitle:ShowWindow(1)
			else
				legendTitle:ShowWindow(1)
			end
		else
			legendTitle:ShowWindow(1)
		end
	end

	-- ????????? ?????? ????????? : grade??????
	local item_bg = GET_CHILD(equipCommonCSet, "item_bg", "ui::CPicture");
	local needAppraisal = TryGetProp(invitem, "NeedAppraisal");
	local needRandomOption = TryGetProp(invitem, "NeedRandomOption")
	local gradeBGName = GET_ITEM_BG_PICTURE_BY_GRADE(invitem.ItemGrade, needAppraisal, needRandomOption)
	item_bg:SetImage(gradeBGName);
	-- ????????? ?????????
	local itemPicture = GET_CHILD(equipCommonCSet, "itempic", "ui::CPicture");
	if (needAppraisal ~= nil and needAppraisal == 1) or (needRandomOption ~= nil and needRandomOption == 1) then
		itemPicture:SetColorTone("FF111111");
	end

	-- ???????????? ??????
	local faceID = TryGetProp(invitem, 'BriquettingIndex')
	if faceID > 0 then
	local bri_cls = GetClassByType('Item', faceID)
	if TryGetProp(bri_cls, "ClassType", "None") == "Arcane" and TryGetProp(bri_cls, "StringArg", "None") == "Vibora" then
		local filename = TryGetProp(bri_cls, "FileName", "None")
		local vibora_cls = GetClassByStrProp2('Item', "FileName", filename, "StringArg", "WoodCarving")
		invitem.TooltipImage  = vibora_cls.TooltipImage
	end
	end

	if invitem.TooltipImage ~= nil and invitem.TooltipImage ~= 'None' then
	
    	if invitem.ClassType ~= 'Outer' and invitem.ClassType ~= 'SpecialCostume' then
			imageName = GET_EQUIP_ITEM_IMAGE_NAME(invitem, "TooltipImage")
    		itemPicture:SetImage(imageName);
    		itemPicture:ShowWindow(1);

    	else -- ???????????? ????????????, ??????PC??? ?????? ????????? ???????????????, ??????PC??? ?????? ????????? ?????????????????? ??????
            local gender = 0;
            if GetMyPCObject() ~= nil then
                local pc = GetMyPCObject();
                gender = pc.Gender;
            else
                gender = barrack.GetSelectedCharacterGender();
            end

			-- ???????????? ????????? ???????????? ?????? ????????? ????????? ??????
			if tooltipframe:GetTopParentFrameName() == 'compare' then
				local compare = ui.GetFrame('compare');
				gender = compare:GetUserIValue('COMPARE_PC_GENDER');
			end

			local tempiconname = string.sub(invitem.TooltipImage,string.len(invitem.TooltipImage)-1);
			if tempiconname ~= "_m" and tempiconname ~= "_f" then
				if gender == 1 then
        			tooltipImg = invitem.TooltipImage.."_m"
        			itemPicture:SetImage(tooltipImg);
        		else
        			tooltipImg = invitem.TooltipImage.."_f"
        			itemPicture:SetImage(tooltipImg);
        		end
			else
				itemPicture:SetImage(invitem.TooltipImage);
			end

    	    
    	end
	else
		itemPicture:ShowWindow(0);
	end


	-- ????????? ????????? 
	local itemNowEquip = GET_CHILD(equipCommonCSet, "nowequip");
	if IsEquiped(invitem) == 1 then
		itemNowEquip:ShowWindow(1)
	else
		itemNowEquip:ShowWindow(0)
	end

	-- ?????????
	local forgeryEquip = GET_CHILD_RECURSIVELY(equipCommonCSet, 'forgeryequip');
	if mainframename == 'equip_main' and isForgery == true and tooltipframe:GetTopParentFrameName() == 'inventory' then
		forgeryEquip:ShowWindow(1);
		itemNowEquip:ShowWindow(0);
	else
		forgeryEquip:ShowWindow(0);
	end
	
	-- ????????? ?????? ??????
	local itemGuid = tooltipframe:GetUserValue('TOOLTIP_ITEM_GUID');
	local isEquipedItem = 0;
	if session.GetEquipItemByGuid(itemGuid) ~= nil then
		isEquipedItem = 1;
	end
	local fullname = GET_FULL_NAME(invitem, true, isEquipedItem);	
	if TryGetProp(invitem, 'ExtractProperty', 0) == 1 then
		fullname = fullname .. '{s15}' ..ClMsg('AlreadyExtractedProperty') .. '{/}'
	end
	if TryGetProp(invitem, 'AdditionalOption_1', 'None') ~= 'None' then
		fullname = fullname .. '(' .. ClMsg('Unique1') .. ')'	
	end
	local nameChild = GET_CHILD(equipCommonCSet, "name", "ui::CRichText");
	nameChild:SetText(fullname);
	nameChild:AdjustFontSizeByWidth(nameChild:GetWidth());		-- ?????? ???????????? ??????
	nameChild:SetTextAlign("center","center");				-- ?????? ??????
	
	-- ????????? ?????? ??????
	local gradeName = GET_CHILD_RECURSIVELY(equipCommonCSet, "gradeName")
	if 0 < itemClass.ItemGrade then 
		gradeName:SetText(gradeText)
		gradeName:ShowWindow(1);

		nameChild:SetMargin(0, 23, 0, 0);
	else
		gradeName:ShowWindow(0);

		nameChild:SetMargin(0, 7, 0, 0);
	end	
	
	gBox:Resize(gBox:GetWidth(),gBox:GetHeight()+equipCommonCSet:GetHeight())

	local retxpos = equipCommonCSet:GetWidth();
	local retypos = equipCommonCSet:GetHeight();

	local picxpos = GET_CHILD_RECURSIVELY(equipCommonCSet, "itempic"):GetWidth();
	local typexpos = GET_CHILD_RECURSIVELY(equipCommonCSet, "bg_type"):GetWidth();

	local value_type = GET_CHILD_RECURSIVELY(equipCommonCSet, "value_type", "ui::CRichText");
	value_type:SetTextByKey("type", GET_REQ_TOOLTIP(invitem));
	value_type:AdjustFontSizeByWidth(retxpos-picxpos-typexpos-20);

	local value_level = GET_CHILD_RECURSIVELY(equipCommonCSet, "value_level")

	local equipableLevelFont = ""
	if GETMYPCLEVEL() < invitem.UseLv then
		equipableLevelFont = equipCommonCSet:GetUserConfig("CANNOT_EQUIP_LEVEL_FONT")
	end

	value_level:SetTextByKey("level", equipableLevelFont .. invitem.UseLv ..' ');

	local value_weight = GET_CHILD_RECURSIVELY(equipCommonCSet, "value_weight")
	value_weight:SetTextByKey("weight", invitem.Weight..' ');

	SELECT_JOB_IMAGE(tooltipframe, invitem)


	return retypos;
end

function SELECT_JOB_IMAGE(tooltipframe, invitem)
	local warrior, wizard, archer, cleric, scout = GET_USEJOB_TOOLTIP_SMALL_IMG(invitem)

	_SELECT_JOB_IMAGE(tooltipframe, invitem, warrior, wizard, archer, cleric, scout)

end

function _SELECT_JOB_IMAGE(tooltipframe, invitem, warrior, wizard, archer, cleric, scout)
	local jobImageGbox = GET_CHILD_RECURSIVELY(tooltipframe, "jobImageGbox")

	local warrior_unselect = GET_CHILD_RECURSIVELY(jobImageGbox, "jobimage_warrior_close")
	local warrior_select = GET_CHILD_RECURSIVELY(jobImageGbox, "jobimage_warrior_open")
	local wizard_unselect = GET_CHILD_RECURSIVELY(jobImageGbox, "jobimage_wizard_close")
	local wizard_select = GET_CHILD_RECURSIVELY(jobImageGbox, "jobimage_wizard_open")
	local archer_unselect = GET_CHILD_RECURSIVELY(jobImageGbox, "jobimage_archer_close")
	local archer_select = GET_CHILD_RECURSIVELY(jobImageGbox, "jobimage_archer_open")
	local cleric_unselect = GET_CHILD_RECURSIVELY(jobImageGbox, "jobimage_cleric_close")
	local cleric_select = GET_CHILD_RECURSIVELY(jobImageGbox, "jobimage_cleric_open")
	local scout_unselect = GET_CHILD_RECURSIVELY(jobImageGbox, "jobimage_scout_close")
	local scout_select = GET_CHILD_RECURSIVELY(jobImageGbox, "jobimage_scout_open")

	warrior_unselect:ShowWindow(1 - warrior)
	warrior_select:ShowWindow(warrior)
	wizard_unselect:ShowWindow(1 - wizard)
	wizard_select:ShowWindow(wizard)
	archer_unselect:ShowWindow(1 - archer)
	archer_select:ShowWindow(archer)
	cleric_unselect:ShowWindow(1 - cleric)
	cleric_select:ShowWindow(cleric)
	scout_unselect:ShowWindow(1 - scout)
	scout_select:ShowWindow(scout)

end

function GET_USEJOB_TOOLTIP_SMALL_IMG(invitem)
	local usejob = TryGetProp(invitem,'UseJob')
	if usejob == nil then
		return 0, 0, 0, 0, 0;
	end

	local warrior = 0
	local wizard = 0
	local archer = 0
	local cleric = 0
    local scout = 0
    
	if usejob == "All" then
		warrior = 1
		wizard = 1
		archer = 1
		cleric = 1
		scout = 1
	else
    	local char1 = string.find(usejob, 'Char1')
    
    	if char1 ~= nil then
    		warrior = 1
    	end

    	local char2 = string.find(usejob, 'Char2')
    
    	if char2 ~= nil then
    		wizard = 1
    	end

    	local char3 = string.find(usejob, 'Char3')

    	if char3 ~= nil then
    		archer = 1
    	end

    	local char4 = string.find(usejob, 'Char4')
    
    	if char4 ~= nil then
			cleric = 1
   		end
   		
   		local char5 = string.find(usejob, 'Char5')
   		
    	if char5 ~= nil then
			scout = 1
   		end
	end

	return warrior, wizard, archer, cleric, scout
end




--????????? ?????? ??? ??????
function DRAW_ITEM_TYPE_N_WEIGHT(tooltipframe, invitem, yPos, mainframename)
	
	local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')

	-- ????????? ?????? ??????
	gBox:RemoveChild('tooltip_equip_type_n_weight');

--	local classtype = TryGetProp(invitem, "ClassType"); -- ???????????? ????????????
--	if classtype ~= nil then
--		if classtype == "Outer" then
--			return yPos;
--		end
--	end

	local tooltip_equip_type_n_weight_Cset = gBox:CreateOrGetControlSet('tooltip_equip_type_n_weight', 'tooltip_equip_type_n_weight', 0, yPos);

	local typeChild = GET_CHILD(tooltip_equip_type_n_weight_Cset,'type','ui::CRichText');
	typeChild:SetText(GET_REQ_TOOLTIP(invitem));
	typeChild:ShowWindow(1);

	local weightChild = GET_CHILD(tooltip_equip_type_n_weight_Cset,'weight','ui::CRichText');
	weightChild:SetTextByKey("weight",invitem.Weight..' ');
	weightChild:ShowWindow(1);

	gBox:Resize(gBox:GetWidth(),gBox:GetHeight()+tooltip_equip_type_n_weight_Cset:GetHeight())
	return tooltip_equip_type_n_weight_Cset:GetHeight() + tooltip_equip_type_n_weight_Cset:GetY();
end

local function _GET_SOCKET_ADD_VALUE(item, invItem, i)    
	
    if invItem:IsAvailableSocket(i) == false then
        return;
	end
	
	local gem = invItem:GetEquipGemID(i);
    if gem == 0 then
        return;
    end
    
	local gemExp = invItem:GetEquipGemExp(i);
	local roastingLv = invItem:GetEquipGemRoastingLv(i);
    local props = {};
    local gemclass = GetClassByType("Item", gem);
    local lv = GET_ITEM_LEVEL_EXP(gemclass, gemExp);
    local prop = geItemTable.GetProp(gem);
    local socketProp = prop:GetSocketPropertyByLevel(lv);
    local type = item.ClassID;
    local benefitCnt = socketProp:GetPropCountByType(type);
    for i = 0 , benefitCnt - 1 do
        local benefitProp = socketProp:GetPropAddByType(type, i);
        props[#props + 1] = {benefitProp:GetPropName(), benefitProp.value}
    end
    
    local penaltyCnt = socketProp:GetPropPenaltyCountByType(type);
    local penaltyLv = lv - roastingLv;
    if 0 > penaltyLv then
        penaltyLv = 0;
    end
    local socketPenaltyProp = prop:GetSocketPropertyByLevel(penaltyLv);
    for i = 0 , penaltyCnt - 1 do
        local penaltyProp = socketPenaltyProp:GetPropPenaltyAddByType(type, i);
        local value = penaltyProp.value
        penaltyProp:GetPropName()
        props[#props + 1] = {penaltyProp:GetPropName(), penaltyProp.value}
    end
    return props;
end

local function _GET_ITEM_SOCKET_ADD_VALUE(targetPropName, item)
	local invItem, where = GET_INV_ITEM_BY_ITEM_OBJ(item);
	if invItem == nil then
		return 0;
	end

    local value = 0;
    local sockets = {};
    if item.MaxSocket > 100 then item.MaxSocket = 0 end
    for i=0, item.MaxSocket - 1 do
        sockets[#sockets + 1] = _GET_SOCKET_ADD_VALUE(item, invItem, i);
    end

    for i = 1, #sockets do
        local props = sockets[i];
        for j = 1, #props do
			local prop = props[j]
            if prop[1] == targetPropName or ( (prop[1] == "PATK") and (targetPropName == "ATK")) then
                value = value + prop[2];
			end
        end
    end
    return value;
end

--????????? ??? ?????????
function DRAW_EQUIP_ATK_N_DEF(tooltipframe, invitem, yPos, mainframename, strarg, basicProp)
	
	local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')
	gBox:RemoveChild('tooltip_equip_atk_n_def');
	local tooltip_equip_atk_n_def_Cset = gBox:CreateOrGetControlSet('tooltip_equip_atk_n_def', 'tooltip_equip_atk_n_def'..basicProp, 0, yPos);
	
	local typeiconname = nil
	local typestring = nil
	local arg1 = nil
	local arg2 = nil
	local reinforceaddvalue = 0
	local socketaddvalue = 0
	
	-- ?????? ?????? ?????????
	local pc = GetMyPCObject();
	local ignoreReinf = TryGetProp(pc, 'IgnoreReinforce', 0);
	local bonusReinf = TryGetProp(pc, 'BonusReinforce', 0);
	local overReinf = TryGetProp(pc, 'OverReinforce', 0);
	-- ?????? ???????????? ????????? ?????????????????? ????????? ??????????????? ????????? ?????????
	local abil_flag = false;
	if overReinf < 0 then
		overReinf = -overReinf;
		abil_flag = true;
	end

	local itemGuid = tooltipframe:GetUserValue('TOOLTIP_ITEM_GUID');
	local isEquiped = 1;
	if session.GetEquipItemByGuid(itemGuid) == nil then
		isEquiped = 0
	end

	local equipGroup = TryGetProp(invitem, 'EquipGroup');
	if equipGroup ~= 'SubWeapon' or isEquiped == 0 then
		if abil_flag == true and (equipGroup == 'SHIRT' or equipGroup == 'PANTS' or equipGroup == 'GLOVES' or equipGroup == 'BOOTS') then
			-- ?????? ?????? ???????????? ?????? ?????? ?????? ?????? ??????
		else
			overReinf = 0;
		end
	end
    if TryGetProp(invitem, 'GroupName') ~= 'Weapon' or isEquiped == 0 then
		bonusReinf = 0; 
	end

	if isEquiped == 0 then
		ignoreReinf = 0;
	end
	local refreshScpStr = TryGetProp(invitem, 'RefreshScp');
	if refreshScpStr ~= nil and refreshScpStr ~= 'None' then
		local refreshScp = _G[refreshScpStr];
		refreshScp(invitem, nil, ignoreReinf, bonusReinf + overReinf);
	end

	if basicProp == 'ATK' then
	    typeiconname = 'test_sword_icon'
		typestring = ScpArgMsg("Melee_Atk")
		if TryGetProp(invitem, 'EquipGroup') == "SubWeapon" and TryGetProp(invitem, 'ClassType') ~= "Trinket" then
			typestring = ScpArgMsg("PATK_SUB")
		end
		reinforceaddvalue = math.floor( GET_REINFORCE_ADD_VALUE_ATK(invitem, ignoreReinf, bonusReinf + overReinf, basicProp) )
		socketaddvalue =  _GET_ITEM_SOCKET_ADD_VALUE(basicProp, invitem);		
		arg1 = invitem.MINATK - reinforceaddvalue + socketaddvalue;
		arg2 = invitem.MAXATK - reinforceaddvalue + socketaddvalue;
	elseif basicProp == 'MATK' then
	    typeiconname = 'test_sword_icon'
		typestring = ScpArgMsg("Magic_Atk")
		reinforceaddvalue = math.floor( GET_REINFORCE_ADD_VALUE_ATK(invitem, ignoreReinf, bonusReinf + overReinf, basicProp) )
		socketaddvalue =  _GET_ITEM_SOCKET_ADD_VALUE("ADD_MATK", invitem)
		arg1 = invitem.MATK - reinforceaddvalue + socketaddvalue;
		arg2 = invitem.MATK - reinforceaddvalue + socketaddvalue;
	else
		typeiconname = 'test_shield_icon'
		typestring = ScpArgMsg(basicProp);
		if invitem.RefreshScp ~= 'None' then
			local scp = _G[invitem.RefreshScp];
			if scp ~= nil then
				scp(invitem);
			end
		end
		
		reinforceaddvalue = GET_REINFORCE_ADD_VALUE(basicProp, invitem, ignoreReinf, bonusReinf + overReinf);
		socketaddvalue =  _GET_ITEM_SOCKET_ADD_VALUE(basicProp, invitem)
		arg1 = TryGetProp(invitem, basicProp) - reinforceaddvalue;
		arg2 = TryGetProp(invitem, basicProp) - reinforceaddvalue;
	end
	  
	SET_DAMAGE_TEXT(tooltip_equip_atk_n_def_Cset, typestring, typeiconname, arg1, arg2, 1, reinforceaddvalue);
	yPos = yPos + tooltip_equip_atk_n_def_Cset:GetHeight();
	
	gBox:Resize(gBox:GetWidth(),  yPos);
	return yPos;
end

function DRAW_TOOLTIP_SUB_BG(gBox, bg_ypos)
	local bg_gbox = gBox:CreateOrGetControl('groupbox', "tooltip_sub_bg", 0, bg_ypos, gBox:GetWidth(), 0);
	if bg_gbox == nil then
		return
	end

	bg_gbox:SetSkinName("test_Item_tooltip_bg");
	bg_gbox = tolua.cast(bg_gbox, "ui::CGroupBox");
	bg_gbox:EnableScrollBar(0)
	bg_gbox:ShowWindow(1);
end


function RESIZE_TOOLTIP_SUB_BG(gBox, bg_ypos, bg_height)
	local bg_gbox = gBox:CreateOrGetControl('groupbox', "tooltip_sub_bg", 0, bg_ypos, gBox:GetWidth(), 0);
	if bg_gbox == nil then
		return
	end

	bg_gbox:Resize(gBox:GetWidth(), bg_height)
end

function IS_NEED_TO_DRAW_TOOLTIP_PROPERTY(list, list2, invitem, basicTooltipPropList)
	for i = 1, #list do
		local propName = list[i];
		local propValue = TryGetProp(invitem, propName, 0);		
		if propValue ~= 0 then
            local checkPropName = propName;
            if propName == 'MINATK' or propName == 'MAXATK' then
                checkPropName = 'ATK';
            end
            if EXIST_ITEM(basicTooltipPropList, checkPropName) == false then
                return true;
            end
		end
	end

	for i = 1, #list2 do
		local propName = list2[i];
		local propValue = invitem[propName];
		if propValue ~= 0 then
			return true;
		end
	end

	for i = 1, 3 do
		local propName = "HatPropName_"..i;
		local propValue = "HatPropValue_"..i;
		if invitem[propValue] ~= 0 and invitem[propName] ~= "None" then
			return true;
		end
	end

	local maxRandomOptionCnt = 6;
	for i = 1, maxRandomOptionCnt do
		if TryGetProp(invitem, 'RandomOptionGroup_'..i, 'None') ~= 'None' then
			return true
		end
	end

	if TryGetProp(invitem, 'RandomOptionRare', 'None') ~= 'None' then
		return true;
	end

	if TryGetProp(invitem, 'IsAwaken', 0) ~= 0 then
		return true;
	end

	return false;
end

function DRAW_EQUIP_SUBFRAME_RANDOM_ICHOR(tooltipframe, invitem, yPos, mainframename)
    local gBox = GET_CHILD(tooltipframe, mainframename, 'ui::CGroupBox')
    gBox:RemoveChild('tooltip_equip_property_random');
    
	local tooltip_equip_property_CSet = gBox:CreateOrGetControlSet('tooltip_equip_property_random', 'tooltip_equip_property_random', 0, yPos);
    local property_gbox = GET_CHILD(tooltip_equip_property_CSet, 'property_gbox', 'ui::CGroupBox');

    -- ???????????? ??????????????? ???????????? ????????? ??????
    if DRAW_EQUIP_RANDOM_ICHOR(invitem, property_gbox, 0) == 0 then
        gBox:RemoveChild('tooltip_equip_property_random')
        return yPos
    end
    
	tooltip_equip_property_CSet:Resize(tooltip_equip_property_CSet:GetWidth(), tooltip_equip_property_CSet:GetHeight() + property_gbox:GetHeight() + property_gbox:GetY())

	gBox:Resize(gBox:GetWidth(), gBox:GetHeight() + tooltip_equip_property_CSet:GetHeight())
	return tooltip_equip_property_CSet:GetHeight() + tooltip_equip_property_CSet:GetY()
end

function DRAW_EQUIP_SUBFRAME_FIXED_ICHOR(tooltipframe, invitem, inheritanceItem, yPos, mainframename)
    local gBox = GET_CHILD(tooltipframe, mainframename, 'ui::CGroupBox')
    gBox:RemoveChild('tooltip_equip_property_fixed');
    
	local tooltip_equip_Cset = 'tooltip_equip_property_fixed'
	if TryGetProp(invitem, 'StringArg', 'None') == 'TOSHeroEquip' then
		tooltip_equip_Cset = 'tooltip_equip_property_TOSHero'
	elseif IS_LEFT_SUBFRAME_ACC(invitem) == true then
		tooltip_equip_Cset = 'tooltip_equip_property_Luciferi'
	end

	local tooltip_equip_property_CSet = gBox:CreateOrGetControlSet(tooltip_equip_Cset, tooltip_equip_Cset, 0, yPos);
    local property_gbox = GET_CHILD(tooltip_equip_property_CSet, 'property_gbox', 'ui::CGroupBox');

    -- ???????????? ??????????????? ???????????? ????????? ??????
    if DRAW_EQUIP_FIXED_ICHOR(invitem, inheritanceItem, property_gbox, 0) == 0 then
        gBox:RemoveChild('tooltip_equip_property_fixed')
        return yPos
    end
    
	tooltip_equip_property_CSet:Resize(tooltip_equip_property_CSet:GetWidth(), tooltip_equip_property_CSet:GetHeight() + property_gbox:GetHeight() + property_gbox:GetY())

	gBox:Resize(gBox:GetWidth(), gBox:GetHeight() + tooltip_equip_property_CSet:GetHeight())
	return tooltip_equip_property_CSet:GetHeight() + tooltip_equip_property_CSet:GetY()
end

function IS_NEED_TO_DRAW_SUBFRAME_ICHOR(invitem)
    local itemGrade = TryGetProp(invitem, "ItemGrade")
    local targetGroup = TryGetProp(invitem, "EquipGroup")
	local useLv = TryGetProp(invitem, "UseLv", 1)
	local stringArg = TryGetProp(invitem, "StringArg", "None")
	if itemGrade > 4 and (useLv >= 360 or stringArg == "TOSHeroEquip" or IS_GROWTH_ITEM(invitem) == true) then
        -- ????????? ?????? ?????? ??????
        if targetGroup == "THWeapon" or targetGroup == "SubWeapon" or targetGroup == "Weapon" then
            return true
        end
    
        -- ????????? ?????? ?????? ?????????
        if targetGroup == "SHIRT" or targetGroup == "PANTS" or targetGroup == "GLOVES" or targetGroup == "BOOTS" then
            return true
        end
    end

	if IS_LEFT_SUBFRAME_ACC(invitem) == true then
		return true
	end

    return false
end

-- ???????????? ?????? ?????? ?????? ??????
function DRAW_EQUIP_PROPERTY(tooltipframe, invitem, inheritanceItem, yPos, mainframename, drawLableline)
	local gBox = GET_CHILD(tooltipframe, mainframename, 'ui::CGroupBox')
	gBox:RemoveChild('tooltip_equip_property');

    -- ???????????? ??????
    local tooltip_equip_property_CSet = gBox:CreateOrGetControlSet('tooltip_equip_property', 'tooltip_equip_property', 0, yPos);
    
    -- ???????????? ?????? (????????? ????????? ??????)
    local labelline = GET_CHILD(tooltip_equip_property_CSet, 'labelline');
    if drawLableline == false then
        tooltip_equip_property_CSet:SetOffset(tooltip_equip_property_CSet:GetX(), tooltip_equip_property_CSet:GetY() - 10);
        labelline:ShowWindow(0);
    else
        labelline:ShowWindow(1);
    end

    local inner_yPos = 0;
	local property_gbox = GET_CHILD(tooltip_equip_property_CSet, 'property_gbox', 'ui::CGroupBox');
	
    -- ????????? ?????? ?????? (??????, ?????????) ?????????????????? ????????? ?????? ???????????? ??????
    if IS_NEED_TO_DRAW_SUBFRAME_ICHOR(invitem) == false then
        inner_yPos = DRAW_EQUIP_RANDOM_ICHOR(invitem, property_gbox, inner_yPos) -- ?????? ?????????
        inner_yPos = DRAW_EQUIP_FIXED_ICHOR(invitem, inheritanceItem, property_gbox, inner_yPos) -- ?????? ?????????
    end

    inner_yPos = DRAW_EQUIP_HAIR_ENCHANT(invitem, property_gbox, inner_yPos) -- ?????? ????????? ??????
	inner_yPos = DRAW_EQUIP_AWAKEN_AND_ENCHANT(invitem, property_gbox, inner_yPos) -- ??????, ????????? ??????

    -- ???????????? ??????????????? ???????????? ????????? ??????
    if inner_yPos == 0 then
        gBox:RemoveChild('tooltip_equip_property')
        return yPos
    end
    
	tooltip_equip_property_CSet:Resize(tooltip_equip_property_CSet:GetWidth(),tooltip_equip_property_CSet:GetHeight() + property_gbox:GetHeight() + property_gbox:GetY());

	gBox:Resize(gBox:GetWidth(),gBox:GetHeight() + tooltip_equip_property_CSet:GetHeight())
	return tooltip_equip_property_CSet:GetHeight() + tooltip_equip_property_CSet:GetY();
end

-- ?????? ????????? ??????
function DRAW_EQUIP_HAIR_ENCHANT(invitem, property_gbox, inner_yPos)
    local init_yPos = inner_yPos;

    for i = 1, 3 do
        local propName = "HatPropName_"..i;
        local propValue = "HatPropValue_"..i;
        if invitem[propValue] ~= 0 and invitem[propName] ~= "None" then
            local opName = string.format("[%s] %s", ClMsg("EnchantOption"), ScpArgMsg(invitem[propName]));
            local strInfo = ABILITY_DESC_PLUS(opName, invitem[propValue]);
            inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, strInfo, 0, inner_yPos);
        end
    end

    if init_yPos < inner_yPos then
        inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, " ", 0, inner_yPos);
    end

    return inner_yPos
end

-- ?????? ??? ????????? ??????
function DRAW_EQUIP_AWAKEN_AND_ENCHANT(invitem, property_gbox, inner_yPos)
    local init_yPos = inner_yPos;

    if invitem.IsAwaken == 1 then
        local opName = string.format("[%s] %s", ClMsg("AwakenOption"), ScpArgMsg(invitem.HiddenProp));
        local strInfo = AWAKEN_ABILITY_DESC_PLUS(opName, invitem.HiddenPropValue);
        inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, strInfo, 0, inner_yPos);
    end

	if invitem.ReinforceRatio > 100 then
		local opName = ClMsg("ReinforceOption");
		local strInfo = ABILITY_DESC_PLUS(opName, math.floor(10 * invitem.ReinforceRatio/100));
        inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, strInfo.."0%"..ClMsg("ReinforceOptionAtk"), 0, inner_yPos);
	end

    inner_yPos = ADD_RANDOM_OPTION_RARE_TEXT(property_gbox, invitem, inner_yPos);
        
    if init_yPos < inner_yPos then
        inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, " ", 0, inner_yPos);
    end

    return inner_yPos
end

local growth_except_list = { MSTA = true }

-- ?????? ?????????
function DRAW_EQUIP_RANDOM_ICHOR(invitem, property_gbox, inner_yPos)
    local init_yPos = inner_yPos;

	local growth_rate = 1
	if IS_GROWTH_ITEM(invitem) == true then
		growth_rate = GET_ITEM_GROWTH_RATE(invitem)
	end

    for i = 1, MAX_OPTION_EXTRACT_COUNT do
        local propGroupName = "RandomOptionGroup_"..i;
        local propName = "RandomOption_"..i;
        local propValue = "RandomOptionValue_"..i;
        local clientMessage = 'None'

        local propItem = invitem

        if propItem[propGroupName] == 'ATK' then
            clientMessage = 'ItemRandomOptionGroupATK'
        elseif propItem[propGroupName] == 'DEF' then
            clientMessage = 'ItemRandomOptionGroupDEF'
        elseif propItem[propGroupName] == 'UTIL_WEAPON' then
            clientMessage = 'ItemRandomOptionGroupUTIL'
        elseif propItem[propGroupName] == 'UTIL_ARMOR' then
            clientMessage = 'ItemRandomOptionGroupUTIL'
        elseif propItem[propGroupName] == 'UTIL_SHILED' then
            clientMessage = 'ItemRandomOptionGroupUTIL'
        elseif propItem[propGroupName] == 'STAT' then
            clientMessage = 'ItemRandomOptionGroupSTAT'
        end
        
        if propItem[propValue] ~= 0 and propItem[propName] ~= "None" then
            local opName = string.format("%s %s", ClMsg(clientMessage), ScpArgMsg(propItem[propName]));
			local _, max = GET_RANDOM_OPTION_VALUE_VER2(invitem, propItem[propName])	
			
			local strInfo = nil
			if max ~= nil then
				local current_value = propItem[propValue]						
				if growth_except_list[propName] ~= true and growth_rate > 0 and growth_rate < 1 then
					current_value = math.floor(current_value * growth_rate)
					if current_value <= 0 then
						current_value = 1
					end
				end
				if max == current_value then
					strInfo = ABILITY_DESC_NO_PLUS(opName, propItem[propValue], 1);
				else
					strInfo = ABILITY_DESC_NO_PLUS(opName, propItem[propValue], 0);
				end
				
				if max ~= nil and max ~= current_value and (keyboard.IsKeyPressed('LALT') == 1 or keyboard.IsKeyDown('LALT') == 1) then
					strInfo = strInfo .. ' {@st66b}{#e28500}{ol}(' .. max .. ')'
				end
			else
				local current_value = propItem[propValue]
				if growth_rate > 0 and growth_rate < 1 then
					current_value = math.floor(current_value * growth_rate)
					if current_value <= 0 then
						current_value = 1
					end
				end
				strInfo = ABILITY_DESC_NO_PLUS(opName, current_value, 0);
			end

            inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, strInfo, 0, inner_yPos);
            margin = true;
        end
    end

    if init_yPos < inner_yPos then
        inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, " ", 0, inner_yPos);
    end

    return inner_yPos
end

-- ?????? ?????????
function DRAW_EQUIP_FIXED_ICHOR(invitem, inheritanceItem, property_gbox, inner_yPos)
    local init_yPos = inner_yPos;

	local growth_rate = 1
	if IS_GROWTH_ITEM(invitem) == true then
		growth_rate = GET_ITEM_GROWTH_RATE(invitem)
	end

    -- ?????? ????????? ??????
    if inheritanceItem ~= nil then
        invitem = inheritanceItem
    end

    -- ?????? ????????? ??????
    local list = {};
    local basicList = GET_EQUIP_TOOLTIP_PROP_LIST(invitem);
    local basicTooltipPropList = StringSplit(invitem.BasicTooltipProp, ';');

    for i = 1, #basicTooltipPropList do
        local basicTooltipProp = basicTooltipPropList[i];
        list = GET_CHECK_OVERLAP_EQUIPPROP_LIST(basicList, basicTooltipProp, list);
    end

    -- ???????????? ????????? ??????
	local randomOptionProp = {};
	for i = 1, MAX_OPTION_EXTRACT_COUNT do
		if invitem['RandomOption_'..i] ~= 'None' then
			randomOptionProp[invitem['RandomOption_'..i]] = invitem['RandomOptionValue_'..i];
		end
    end

    local class = GetClassByType("Item", invitem.ClassID);

	-- ?????? ????????? ??????
	if inheritanceItem ~= nil then
		local name = inheritanceItem.Name
		local additional_option = TryGetProp(invitem, 'AdditionalOption_1', 'None')			
		if additional_option ~= 'None' then	
			name = name .. '(' .. ClMsg("Unique1") .. ')'
		end
		inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, '{@st42_yellow}{s15}'.. name, 0, inner_yPos);
		inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, ' ', 0, 8);
	end

    -- ?????? ????????? ??????
    for i = 1, #list do
        local propName = list[i];
        local propValue = TryGetProp(class, propName, 0);
		if growth_except_list[propName] ~= true and growth_rate > 0 and growth_rate < 1 then
		local growth_value = math.floor(propValue * growth_rate)
		if propValue > 0 and growth_value <= 0 then
			growth_value = 1
		end
		propValue = growth_value
	end
        local needToShow = true;

        for j = 1, #basicTooltipPropList do
            if basicTooltipPropList[j] == propName then
                needToShow = false;
            end
        end

        if needToShow == true and propValue ~= 0 and randomOptionProp[propName] == nil then -- ?????? ???????????? ????????? ??????????????? ????????? ???????????? ??????
            if invitem.GroupName == 'Weapon' then
                if propName ~= "MINATK" and propName ~= 'MAXATK' then
                    local strInfo = ABILITY_DESC_PLUS(ScpArgMsg(propName), propValue);					
                    inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, strInfo, 0, inner_yPos);
                end
            elseif  invitem.GroupName == 'Armor' then
                if invitem.ClassType == 'Gloves' then
                    if propName ~= "HR" then
                        local strInfo = ABILITY_DESC_PLUS(ScpArgMsg(propName), propValue);
                        inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, strInfo, 0, inner_yPos);
                    end
                elseif invitem.ClassType == 'Boots' then
                    if propName ~= "DR" then
                        local strInfo = ABILITY_DESC_PLUS(ScpArgMsg(propName), propValue);
                        inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, strInfo, 0, inner_yPos);
                    end
                else
                    if propName ~= "DEF" then
                        local strInfo = ABILITY_DESC_PLUS(ScpArgMsg(propName), propValue);
                        inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, strInfo, 0, inner_yPos);
                    end
                end
            else
                local strInfo = ABILITY_DESC_PLUS(ScpArgMsg(propName), propValue);
                inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, strInfo, 0, inner_yPos);
            end
        end
    end

    -- ?????? ????????? ??????
    if invitem.OptDesc ~= nil and invitem.OptDesc ~= 'None' and TryGetProp(invitem, 'StringArg', 'None') ~= 'Vibora' then
		inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, invitem.OptDesc, 0, inner_yPos);
    end

    -- ?????? ????????? ?????? (????????????)
    if invitem.OptDesc ~= nil and (invitem.OptDesc == 'None' or invitem.OptDesc == '') and (TryGetProp(invitem, 'StringArg', 'None') == 'Vibora' or (TryGetProp(invitem, 'StringArg', 'None') == 'pvp_Mine' and TryGetProp(invitem, 'AdditionalOption_1', 'None') ~= "None")) then
        local opt_desc = invitem.OptDesc
        if opt_desc == 'None' then
            opt_desc = ''
        end
        
        for idx = 1, MAX_VIBORA_OPTION_COUNT do			
            local additional_option = TryGetProp(invitem, 'AdditionalOption_' .. tostring(idx), 'None')			
            if additional_option ~= 'None' then
                local tooltip_str = 'tooltip_' .. additional_option					
                local cls_message = GetClass('ClientMessage', tooltip_str)
                if cls_message ~= nil then
					opt_desc = opt_desc .. ClMsg(tooltip_str)					
                end
            end
        end

        inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, opt_desc, 0, inner_yPos);
    end

	-- ????????? ??????
    if TryGetProp(invitem, 'StringArg', 'None') == 'TOSHeroEquip' then
	    local opt_desc = invitem.OptDesc
	    if opt_desc == 'None' then
	        opt_desc = ''
	    end
	
	    for idx = 1, 3 do			
	        local TOSHeroEquipOption = TryGetProp(invitem, 'TOSHeroEquipOption_' .. tostring(idx), 'None')
			if TOSHeroEquipOption ~= 'None' then
	            local cls_TOShero = GetClass('TOSHeroEquipOption', TOSHeroEquipOption)
				if cls_TOShero == nil then return end

				local Desc = TryGetProp(cls_TOShero, 'EffectDesc', ' ')

				local name = TryGetProp(cls_TOShero, "ClassName", "None")
				if (name == 'Tear1_Ballista' or name == 'Tear1_Ballista_2' or  name == 'Tear2_Ballista' or  name =='Tear3_Ballista') and (keyboard.IsKeyPressed('LALT') == 1 or keyboard.IsKeyDown('LALT') == 1) then
					Desc = Desc..ClMsg('TOSHeroEquipTooltip_Ballista')
				elseif (name == 'Tear1_Ballista' or name == 'Tear1_Ballista_2' or  name == 'Tear2_Ballista' or  name =='Tear3_Ballista') then
					Desc = Desc..ClMsg('TOSHeroEquipTooltip_Ballista_ALT')
					end

				inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, Desc, 0, inner_yPos)
	        end
	    end
	end

    if init_yPos < inner_yPos then
        inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, " ", 0, inner_yPos);
    end

    return inner_yPos
end

-- ?????? ??? ?????? ??????
function DRAW_EQUIP_MEMO(tooltipframe, invitem, yPos, mainframename)

	local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')
	gBox:RemoveChild('tooltip_equip_memo');

	local memo = invitem.Memo
	if memo == "None" then -- ?????? ????????? ????????? ??????. ????????? ????????? ??? ????????? ?????????
		return yPos
	end

	memo = ScpArgMsg("ItIsMemo") ..memo
	
	local tooltip_equip_property_CSet = gBox:CreateOrGetControlSet('tooltip_equip_memo', 'tooltip_equip_memo', 0, yPos);
	local property_gbox = GET_CHILD(tooltip_equip_property_CSet,'property_gbox','ui::CGroupBox')
		
	local inner_yPos = 0;
	inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, memo, 0, inner_yPos);
	
	local BOTTOM_MARGIN = tooltipframe:GetUserConfig("BOTTOM_MARGIN"); -- ??? ????????? ??????
	tooltip_equip_property_CSet:Resize(tooltip_equip_property_CSet:GetWidth(),tooltip_equip_property_CSet:GetHeight() + property_gbox:GetHeight() + property_gbox:GetY() + BOTTOM_MARGIN);

	gBox:Resize(gBox:GetWidth(),gBox:GetHeight() + tooltip_equip_property_CSet:GetHeight())
	return tooltip_equip_property_CSet:GetHeight() + tooltip_equip_property_CSet:GetY();
end

-- ???????????? ?????? ?????? ?????? ?????? (???????????? +1 ??????)
function DRAW_EQUIP_DESC(tooltipframe, invitem, yPos, mainframename)

	local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')
	gBox:RemoveChild('tooltip_equip_desc');

	local desc = GET_ITEM_TOOLTIP_DESC(invitem);
	
	desc = DRAW_COLLECTION_INFO(invitem, desc)

	if desc == "" or desc == " " then -- ?????? ?????? ????????? ????????? ??????. ????????? ????????? ??? ????????? ?????????
		return yPos
	end
	
    local value = IS_TOGGLE_EQUIP_ITEM_TOOLTIP_DESC();
    if value == 1 then
        return yPos
    end
	
	local tooltip_equip_property_CSet = gBox:CreateOrGetControlSet('tooltip_equip_desc', 'tooltip_equip_desc', 0, yPos - 2);
	local property_gbox = GET_CHILD(tooltip_equip_property_CSet,'property_gbox','ui::CGroupBox')
		
	local inner_yPos = 0;
	inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, desc, 0, inner_yPos);

	local BOTTOM_MARGIN = tooltipframe:GetUserConfig("BOTTOM_MARGIN"); -- ??? ????????? ??????
	tooltip_equip_property_CSet:Resize(tooltip_equip_property_CSet:GetWidth(),tooltip_equip_property_CSet:GetHeight() + property_gbox:GetHeight() + property_gbox:GetY() + BOTTOM_MARGIN);

	gBox:Resize(gBox:GetWidth(),gBox:GetHeight() + tooltip_equip_property_CSet:GetHeight())
	return tooltip_equip_property_CSet:GetHeight() + tooltip_equip_property_CSet:GetY();
end

-- ?????? tooltip_equip_desc
function EQUIP_ARK_DESC(class_name, invitem)
	class_name = replace(class_name, 'PVP_', '')

	local tooltip_type = 1
	local desc = ""

	local func_str = string.format('get_tooltip_%s_arg%d', class_name, 2)		
	local tooltip_func = _G[func_str]  -- get_tooltip_Ark_str_arg1 ?????????
	if tooltip_func ~= nil then
		local tooltiptype, option, level, value, base_value = tooltip_func()		
		tooltip_type = tooltiptype
	end	
	
	if tooltip_type == 3 then
		local msg = class_name .. '_desc{base1}{base2}'
		local base1 = ''
		local base2 = ''
		local func_str = string.format('get_tooltip_%s_arg%d', class_name, 2)
		local tooltip_func = _G[func_str]  -- get_tooltip_Ark_str_arg1 ?????????
		if tooltip_func ~= nil then
			local tooltiptype, option, level, value, base_value = tooltip_func()			
			base1 = base_value
		end	
		local func_str = string.format('get_tooltip_%s_arg%d', class_name, 3)		
		local tooltip_func = _G[func_str]  -- get_tooltip_Ark_str_arg1 ?????????
		if tooltip_func ~= nil then
			local tooltiptype, option, level, value, base_value = tooltip_func()						
			base2 = base_value
		end	
		desc = ScpArgMsg(msg, 'base1', base1, 'base2', base2)		
	else
		local func_str = string.format('get_tooltip_%s_arg%d', class_name, 3)		
		local tooltip_func = _G[func_str]  -- get_tooltip_Ark_str_arg3 ?????????
		if tooltip_func ~= nil then
			local tooltiptype, option, level, value, base_value, msg = tooltip_func()			
			if tooltiptype == 4 then -- 3?????? ????????? base??? 1?????? ??????
				local base1 = base_value				
				desc = ScpArgMsg(msg, 'base1', base1)
			else
				desc = GET_ITEM_TOOLTIP_DESC(invitem);
			end
			
		else
			desc = GET_ITEM_TOOLTIP_DESC(invitem);
		end	
	end
	return desc
end
function DRAW_EQUIP_ARK_DESC(tooltipframe, invitem, yPos, mainframename)
	local class_name = TryGetProp(invitem, 'ClassName', 'None')
	local tooltip_type = 1

	local desc = ""
	
	
	desc = EQUIP_ARK_DESC(class_name,invitem);

	local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')
	gBox:RemoveChild('tooltip_equip_desc');

	if desc == "" then -- ?????? ?????? ????????? ????????? ??????. ????????? ????????? ??? ????????? ?????????
		return yPos
	end

    local value = IS_TOGGLE_EQUIP_ITEM_TOOLTIP_DESC();
    if value == 1 then
        return yPos
    end
	
	local tooltip_equip_property_CSet = gBox:CreateOrGetControlSet('tooltip_equip_desc', 'tooltip_equip_desc', 0, yPos);
	local property_gbox = GET_CHILD(tooltip_equip_property_CSet,'property_gbox','ui::CGroupBox')
		
	local inner_yPos = 0;
	inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, desc, 0, inner_yPos);

	local BOTTOM_MARGIN = tooltipframe:GetUserConfig("BOTTOM_MARGIN"); -- ??? ????????? ??????
	tooltip_equip_property_CSet:Resize(tooltip_equip_property_CSet:GetWidth(),tooltip_equip_property_CSet:GetHeight() + property_gbox:GetHeight() + property_gbox:GetY() + BOTTOM_MARGIN);

	gBox:Resize(gBox:GetWidth(),gBox:GetHeight() + tooltip_equip_property_CSet:GetHeight())
	return tooltip_equip_property_CSet:GetHeight() + tooltip_equip_property_CSet:GetY();
end

-- ?????? ??????
function DRAW_EQUIP_SOCKET_COUNT(tooltipframe, invitem, yPos, addinfoframename)
	local value = IS_TOGGLE_EQUIP_ITEM_TOOLTIP_DESC();
    if value == 1 then
        return yPos
    end

    if invitem.MaxSocket > 100 then invitem.MaxSocket = 0 end
    if invitem.MaxSocket == 0 then
    	return yPos
    end

	local maxSocket = invitem.MaxSocket
	if maxSocket > invitem.MaxSocket_COUNT then
		maxSocket = invitem.MaxSocket_COUNT
	end

	local gBox = GET_CHILD(tooltipframe, addinfoframename,'ui::CGroupBox')
	gBox:RemoveChild('tooltip_equip_socket');
	
	local tooltip_equip_socket_CSet = gBox:CreateOrGetControlSet('tooltip_equip_socket', 'tooltip_equip_socket', 0, yPos);

	local socket_gbox= GET_CHILD(tooltip_equip_socket_CSet,'socket_gbox','ui::CGroupBox')
	local socket_value = GET_CHILD_RECURSIVELY(tooltip_equip_socket_CSet, 'socket_value')
	tolua.cast(tooltip_equip_socket_CSet, "ui::CControlSet");
	socket_value:SetTextByKey("curCount", 0)
	socket_value:SetTextByKey("maxCount", maxSocket)
	return tooltip_equip_socket_CSet:GetHeight() + tooltip_equip_socket_CSet:GetY();
end

function DRAW_EQUIP_SOCKET(tooltipframe, itemObj, yPos, addinfoframename)
	local value = IS_TOGGLE_EQUIP_ITEM_TOOLTIP_DESC();
    if value == 1 then
        return yPos;
	end
	
	local invitem = GET_INV_ITEM_BY_ITEM_OBJ(itemObj);
	if invitem == nil then
		return yPos;
	end

	local gBox = GET_CHILD(tooltipframe, addinfoframename,'ui::CGroupBox')
	local tooltip_equip_socket_CSet = GET_CHILD_RECURSIVELY(gBox, 'tooltip_equip_socket');
	local socket_gbox= GET_CHILD(tooltip_equip_socket_CSet,'socket_gbox','ui::CGroupBox')
	local socket_value = GET_CHILD_RECURSIVELY(tooltip_equip_socket_CSet, 'socket_value')

	tolua.cast(tooltip_equip_socket_CSet, "ui::CControlSet");
	local DEFAULT_POS_Y = tooltip_equip_socket_CSet:GetUserConfig("DEFAULT_POS_Y")
	local inner_yPos = DEFAULT_POS_Y;

	local function _ADD_ITEM_SOCKET_PROP(GroupCtrl, invitem, socket, gem, gemExp, gemLv, yPos )
		if GroupCtrl == nil then
			return 0;
		end
	
		local cnt = GroupCtrl:GetChildCount();
		
		local ControlSetObj = GroupCtrl:CreateControlSet('tooltip_item_prop_socket', "ITEM_PROP_" .. cnt , 0, yPos);
		local ControlSetCtrl = tolua.cast(ControlSetObj, 'ui::CControlSet');
	
		local socket_image = GET_CHILD(ControlSetCtrl, "socket_image", "ui::CPicture");
		local socket_property_text = GET_CHILD(ControlSetCtrl, "socket_property", "ui::CRichText");
		local gradetext = GET_CHILD_RECURSIVELY(ControlSetCtrl,"grade","ui::CRichText");
	
		local NEGATIVE_COLOR = ControlSetObj:GetUserConfig("NEGATIVE_COLOR")
		local POSITIVE_COLOR = ControlSetObj:GetUserConfig("POSITIVE_COLOR")
		if gem == 0 then
			local socketCls = GetClassByType("Socket", socket);
			socketicon = socketCls.SlotIcon
			local socket_image_name = socketCls.SlotIcon
			socket_image:SetImage(socket_image_name)		
			socket_property_text:ShowWindow(0)
			gradetext:ShowWindow(0)
		else
	
			local gemclass = GetClassByType("Item", gem);
			local socket_image_name = gemclass.Icon
	
			if gemclass.ClassName == 'gem_circle_1' then
				socket_image_name = 'test_tooltltip_red'
			elseif gemclass.ClassName == 'gem_square_1' then
				socket_image_name = 'test_tooltltip_blue'
			elseif gemclass.ClassName == 'gem_diamond_1' then
				socket_image_name = 'test_tooltltip_green'
			elseif gemclass.ClassName == 'gem_star_1' then
				socket_image_name = 'test_tooltltip_yellow'
			elseif gemclass.ClassName == 'gem_White_1' then
				socket_image_name = 'test_tooltltip_white'
			end
	
			socket_image:SetImage(socket_image_name)		
			local lv = GET_ITEM_LEVEL_EXP(gemclass, gemExp);
			
			local prop = geItemTable.GetProp(gem);
			
			local desc = "";
			local socketProp = prop:GetSocketPropertyByLevel(lv);
			local type = invitem.ClassID;
			local cnt = socketProp:GetPropCountByType(type);
			gradetext:SetText("Lv " .. lv)
			gradetext:ShowWindow(1)
	
			for i = 0 , cnt - 1 do
				local addProp = socketProp:GetPropAddByType(type, i);
	
				local tempvalue = addProp.value
	
				local plma_mark = POSITIVE_COLOR .. "{img green_up_arrow 16 16}"..'{/}';
				if tempvalue < 0 then
					plma_mark = NEGATIVE_COLOR .. "{img red_down_arrow 16 16}"..'{/}';
					tempvalue = tempvalue * -1
				end
	
				if addProp:GetPropName() == "OptDesc" then
					desc = addProp:GetPropDesc().." ";
				else
					desc = desc .. ScpArgMsg(addProp:GetPropName()) .. plma_mark .. tempvalue.." ";
				end
	
			end
	
			local cnt2 = socketProp:GetPropPenaltyCountByType(type);
	
			local penaltyLv = lv - gemLv;
			if 0 > penaltyLv then
				penaltyLv = 0;
			end
			local socketPenaltyProp = prop:GetSocketPropertyByLevel(penaltyLv);
			for i = 0 , cnt2 - 1 do
				local addProp = socketPenaltyProp:GetPropPenaltyAddByType(type, i);
				local tempvalue = addProp.value
				local plma_mark = POSITIVE_COLOR .. "{img green_up_arrow 16 16}"..'{/}';
	
				if tempvalue < 0 then
					plma_mark = NEGATIVE_COLOR .. "{img red_down_arrow 16 16}"..'{/}';			
				end
	
				if gemLv > 0 then
					if 0 < penaltyLv then
						desc = desc .. "{nl}" .. ScpArgMsg(addProp:GetPropName()) .. plma_mark .. tempvalue.." ";
					end
				else
					desc = desc .. "{nl}" .. ScpArgMsg(addProp:GetPropName()) .. plma_mark .. tempvalue.." ";
				end
			end
				
			socket_property_text:SetText(desc);
			socket_property_text:ShowWindow(1);
			ControlSetCtrl:Resize(ControlSetCtrl:GetWidth(), math.max(ControlSetCtrl:GetHeight(), socket_property_text:GetHeight()));
		end
	
		GroupCtrl:ShowWindow(1)
		GroupCtrl:Resize(GroupCtrl:GetWidth(), GroupCtrl:GetHeight() + ControlSetObj:GetHeight() + 7)
		return ControlSetCtrl:GetHeight() + ControlSetCtrl:GetY() + 5;
	end	

	local curCount = 0;	
    if itemObj.MaxSocket > 100 then itemObj.MaxSocket = 0 end
	for i = 0, itemObj.MaxSocket - 1 do
		if invitem:IsAvailableSocket(i) == true then
			curCount = curCount + 1
			inner_yPos = _ADD_ITEM_SOCKET_PROP(socket_gbox, itemObj, 
											GET_COMMON_SOCKET_TYPE(), 
											invitem:GetEquipGemID(i), 
											invitem:GetEquipGemExp(i),
											invitem:GetEquipGemRoastingLv(i),
											inner_yPos);
		end
	end

	socket_value:SetTextByKey("curCount", curCount)

	local BOTTOM_MARGIN = tooltipframe:GetUserConfig("BOTTOM_MARGIN"); -- ??? ????????? ??????
	tooltip_equip_socket_CSet:Resize(tooltip_equip_socket_CSet:GetWidth(), socket_gbox:GetHeight() + socket_gbox:GetY() + BOTTOM_MARGIN);

	gBox:Resize(gBox:GetWidth(),gBox:GetHeight() + tooltip_equip_socket_CSet:GetHeight())
	return tooltip_equip_socket_CSet:GetHeight() + tooltip_equip_socket_CSet:GetY();
end

-- ** ?????? ????????? ??? ?????? ?????????
function DRAW_AETHER_SOCKET_FOR_EQUIP(tooltipframe, itemObj, yPos, addinfoframename)
	local value = IS_TOGGLE_EQUIP_ITEM_TOOLTIP_DESC()
    if value == 1 then
        return yPos;
	end
	
	local gBox = GET_CHILD(tooltipframe, addinfoframename, 'ui::CGroupBox')
	gBox:RemoveChild('tooltip_relic_socket');
	
	local tooltip_equip_socket_CSet = gBox:CreateOrGetControlSet('tooltip_equip_property', 'tooltip_relic_socket', 0, yPos);
	
	local invitem = GET_INV_ITEM_BY_ITEM_OBJ(itemObj);
	if invitem == nil then
		return yPos;
	end

	local gBox = GET_CHILD(tooltipframe, addinfoframename, 'ui::CGroupBox');
	local tooltip_equip_socket_CSet = GET_CHILD_RECURSIVELY(gBox, 'tooltip_relic_socket');
	local socket_gbox = GET_CHILD(tooltip_equip_socket_CSet, 'property_gbox', 'ui::CGroupBox');
	
	tolua.cast(tooltip_equip_socket_CSet, 'ui::CControlSet');
	local inner_yPos = 0;

	local function _ADD_ITEM_SOCKET_PROP(GroupCtrl, invitem, gemID, gemLv, yPos)
		if GroupCtrl == nil then return 0; end

		local cnt = GroupCtrl:GetChildCount();
		local ControlSetObj = GroupCtrl:CreateControlSet('tooltip_item_prop_socket_aether', 'ITEM_PROP_' .. cnt , 0, yPos);
		local ControlSetCtrl = tolua.cast(ControlSetObj, 'ui::CControlSet');
	
		local socket_image = GET_CHILD(ControlSetCtrl, 'socket_image', 'ui::CPicture');
		local socket_property_text = GET_CHILD(ControlSetCtrl, 'socket_property', 'ui::CRichText');
		local gradetext = GET_CHILD_RECURSIVELY(ControlSetCtrl, 'grade', 'ui::CRichText');
		local socket_stat_text = GET_CHILD(ControlSetCtrl, "socket_stat", "ui::CRichText");
		if gemID == 0 then
			local socket_image_name = "freegemslot_image";
			socket_image:SetImage(socket_image_name);

			local socket_type_str = 'Gem_Aether';
			local empty_socket_name	= ScpArgMsg('EMPTY_RELIC_GEM_SOCKET', 'NAME', ClMsg(socket_type_str));
			socket_property_text:SetText(empty_socket_name);
			gradetext:ShowWindow(0);
			socket_stat_text:ShowWindow(0);
		else
			local gemclass = GetClassByType('Item', gemID);
			local socket_image_name = gemclass.Icon
			local gemclass = GetClassByType("Item", gemID);
			if gemclass ~= nil then
				if gemclass.ClassName == "Gem_High_STR" then
					socket_image_name = "test_tooltltip_red2";
				elseif gemclass.ClassName == "Gem_High_INT" then
					socket_image_name = "test_tooltltip_blue2";
				elseif gemclass.ClassName == "Gem_High_DEX" then
					socket_image_name = "test_tooltltip_green2";
				elseif gemclass.ClassName == "Gem_High_MNA" then
					socket_image_name = "test_tooltltip_yellow2";
				elseif gemclass.ClassName == "Gem_High_CON" then
					socket_image_name = "test_tooltltip_white2";
				end
			end
			socket_image:SetImage(socket_image_name);
			
			gradetext:SetText('Lv ' .. gemLv);
			gradetext:ShowWindow(1)

			-- ??????
			local string_arg = TryGetProp(gemclass, "StringArg");
			local fun_str = "get_aether_gem_"..string_arg.."_prop";
			local func = _G[fun_str];
			local prop_name, prop_value = func(gemLv);
			if prop_name == "STR" or prop_name == "CON" or prop_name == "INT" or prop_name == "MNA" or prop_name == "DEX" then
				if prop_value ~= 0 then
					local stat_text = "";
					if prop_value < 0 then
						stat_text = string.format(" %s "..ScpArgMsg("PropDown").."%d", ScpArgMsg(prop_name), math.abs(prop_value));
					else
						stat_text = string.format(" %s "..ScpArgMsg("PropUp").."%d", ScpArgMsg(prop_name), math.abs(prop_value));
					end
					socket_stat_text:SetText(stat_text);
					socket_stat_text:ShowWindow(1);
				end
			end
			
			local desc = GET_RELIC_GEM_NAME_WITH_FONT(gemclass);
			socket_property_text:SetText(desc);
			socket_property_text:ShowWindow(1);
		end
		ControlSetCtrl:Resize(ControlSetCtrl:GetWidth(), math.max(ControlSetCtrl:GetHeight() + 20, socket_property_text:GetHeight()));
		GroupCtrl:ShowWindow(1);
		GroupCtrl:Resize(GroupCtrl:GetWidth(), GroupCtrl:GetHeight() + ControlSetObj:GetHeight() + 7);
		return ControlSetCtrl:GetHeight() + ControlSetCtrl:GetY() + 5;
	end	

	local BOTTOM_MARGIN = 10;
	for i = itemObj.MaxSocket_COUNT, itemObj.MaxSocket_COUNT + 1 do
		if invitem:IsAvailableSocket(i) == true then
			local gem_class_id = invitem:GetEquipGemID(i);
			local gem_lv = invitem:GetEquipGemLv(i);
			inner_yPos = _ADD_ITEM_SOCKET_PROP(socket_gbox, itemObj, gem_class_id, gem_lv, inner_yPos);
		
			if gem_class_id ~= 0 then
				local gem_class = GetClassByType('Item', gem_class_id);
				local gem_type = relic_gem_type[TryGetProp(gem_class, 'GemType', 'None')];
				if gem_type == 0 then
					inner_yPos = _RELIC_GEM_SPEND_RP_OPTION(socket_gbox, inner_yPos, gem_class_id);
					inner_yPos = _RELIC_GEM_RELEASE_OPTION(socket_gbox, inner_yPos, gem_class_id);
				elseif gem_type == 1 then
					inner_yPos = _RELIC_GEM_SPEND_RP_OPTION(socket_gbox, inner_yPos, gem_class_id);
				end
				
				--inner_yPos = _RELIC_GEM_OPTION_BY_LV(socket_gbox, inner_yPos, gem_type, 1, gem_class.ClassName, gem_lv);
			end
		end
	end

	inner_yPos = inner_yPos + BOTTOM_MARGIN;
	
	socket_gbox:Resize(socket_gbox:GetWidth(), inner_yPos);
	tooltip_equip_socket_CSet:Resize(tooltip_equip_socket_CSet:GetWidth(), socket_gbox:GetHeight() + socket_gbox:GetY() + BOTTOM_MARGIN);

	gBox:Resize(gBox:GetWidth(), gBox:GetHeight() + tooltip_equip_socket_CSet:GetHeight());
	return tooltip_equip_socket_CSet:GetHeight() + tooltip_equip_socket_CSet:GetY();
end


-- ??????????????? ??????
function DRAW_EQUIP_MAGICAMULET(subframe, invitem, yPos,addinfoframename)

	local gBox = GET_CHILD(subframe, addinfoframename,'ui::CGroupBox')
	gBox:RemoveChild('tooltip_equip_magicamulet');
	
	local CSet = gBox:CreateOrGetControlSet('tooltip_equip_magicamulet', 'tooltip_equip_magicamulet', 0, yPos);
	local amulet_gbox= GET_CHILD(CSet,'magicamulet_gbox','ui::CGroupBox')

	local inner_yPos = 0;


	for i=0, invitem.MaxSocket_MA-1 do
		if invitem['MagicAmulet_' .. i] > 0 then

			local amuletitemclass = GetClassByType('Item',invitem['MagicAmulet_' .. i]);

			local each_amulet_cset = amulet_gbox:CreateControlSet('tooltip_item_prop_magicamulet', 'tooltip_item_prop_magicamulet'..i, 0, inner_yPos);
			local amulet_image = GET_CHILD(each_amulet_cset,'amulet_image','ui::CPicture')
			local amulet_name = GET_CHILD(each_amulet_cset,'amulet_name','ui::CRichText')
			local amulet_desc = GET_CHILD(each_amulet_cset,'amulet_desc','ui::CRichText')
			local labelline = each_amulet_cset:GetChild("labelline")
			
			if yPos == 0 and i == 0 then
				labelline:ShowWindow(0)
			else
				labelline:ShowWindow(1)
			end

			amulet_image:SetImage(amuletitemclass.Icon)
			amulet_name:SetText(amuletitemclass.Name)
			amulet_desc:SetText(amuletitemclass.Desc)

			inner_yPos = inner_yPos + each_amulet_cset:GetHeight()

		end
	end

	amulet_gbox:Resize(amulet_gbox:GetOriginalWidth(),inner_yPos);

	local BOTTOM_MARGIN = subframe:GetUserConfig("BOTTOM_MARGIN"); -- ??? ????????? ??????
	CSet:Resize(CSet:GetWidth(),CSet:GetHeight() + amulet_gbox:GetHeight() + amulet_gbox:GetY() + BOTTOM_MARGIN);

	gBox:Resize(gBox:GetWidth(),gBox:GetHeight() + CSet:GetHeight())
	return CSet:GetHeight() + CSet:GetY();
end

--?????? ?????????
function DRAW_EQUIP_SET(tooltipframe, invitem, ypos, mainframename)
	local gBox = GET_CHILD(tooltipframe,mainframename,'ui::CGroupBox');
	gBox:RemoveChild('tooltip_set');

	local tooltip_CSet = gBox:CreateControlSet('tooltip_set', 'tooltip_set', 0, ypos);
	tolua.cast(tooltip_CSet, "ui::CControlSet");
	local set_gbox_type= GET_CHILD(tooltip_CSet,'set_gbox_type','ui::CGroupBox')
	local set_gbox_prop= GET_CHILD(tooltip_CSet,'set_gbox_prop','ui::CGroupBox')

	local inner_yPos = 0;
	local inner_xPos = 0;
	local DEFAULT_POS_Y = tooltip_CSet:GetUserConfig("DEFAULT_POS_Y")
	inner_yPos = DEFAULT_POS_Y;
	inner_xPos = 0;

	-- ??????????????? ?????? ?????? ????????? ?????? ??????


	-- ??????????????? ????????? ???????????? ??????
	
	local isUseLegendSet = 0	
	if invitem.LegendGroup == nil or invitem.LegendGroup == 'None' then
		isUseLegendSet = 0
	else
		isUseLegendSet = 1
	end

	local EntireHaveCount = 0;
	local setList = {'RH', 'LH', 'SHIRT', 'PANTS', 'GLOVES', 'BOOTS'}
	local setFlagList = {RH_flag, LH_flag, SHIRT_flag, PANTS_flag, GLOVES_flag, BOOTS_flag}
	local setItemCount = 0
	setItemCount, setFlagList[1], setFlagList[2], setFlagList[3], setFlagList[4], setFlagList[5], setFlagList[6] = CHECK_EQUIP_SET_ITEM(invitem)
	if isUseLegendSet == 1 then
		if invitem.LegendPrefix == nil or invitem.LegendPrefix == "None" then
			return ypos
		end

		for i = 1, setItemCount do
			local setItemTextCset = set_gbox_type:CreateControlSet('eachitem_in_setitemtooltip', 'setItemText'..i, inner_xPos, inner_yPos);
			tolua.cast(setItemTextCset, "ui::CControlSet");
			local setItemName = GET_CHILD_RECURSIVELY(setItemTextCset, "setitemtext")
			if setFlagList[i] == 0 then
				setItemName:SetTextByKey("font", tooltip_CSet:GetUserConfig("NOT_HAVE_ITEM_FONT"))
			else 
				setItemName:SetTextByKey("font", tooltip_CSet:GetUserConfig("HAVE_ITEM_FONT"))
				EntireHaveCount = EntireHaveCount + 1
			end

			local prefixCls = GetClass('LegendSetItem', invitem.LegendPrefix)

			local temp = ""
			if prefixCls ~= nil then
				temp = prefixCls.Name
			end
			local setItemText = temp .. ' ' .. tooltip_CSet:GetUserConfig(setList[i] .. '_SET_TEXT')
			setItemName:SetTextByKey("itemname", setItemText)
			local heightMargin = setItemTextCset:GetUserConfig("HEIGHT_MARGIN")
			inner_yPos = inner_yPos + heightMargin;
		end
	else
		local itemProp = geItemTable.GetProp(invitem.ClassID);

		local set = itemProp.setInfo;
		if set == nil then
			return ypos;
		end
		local cnt =	set:GetItemCount();
		local clsID = 0
		local HaveCount = 0;
		for i = 0, cnt - 1 do
			local itemClsName = set:GetItemClassName(i)
			local itemCls = GetClass("Item", itemClsName)

			if itemCls ~= nil then
				local setItemName = set:GetItemName(i)

				local setItemTextCset = set_gbox_type:CreateControlSet('eachitem_in_setitemtooltip', 'setItemText'..i, inner_xPos, inner_yPos);
				tolua.cast(setItemTextCset, "ui::CControlSet");
				local setItemName = GET_CHILD_RECURSIVELY(setItemTextCset, "setitemtext")

				if itemCls.ClassID ~= clsID then
					HaveCount = 0
				end

				local count = GET_EQP_ITEM_CNT(itemCls.ClassID)
				count = count - HaveCount

				if count == 0 then
					setItemName:SetTextByKey("font", tooltip_CSet:GetUserConfig("NOT_HAVE_ITEM_FONT"))
					HaveCount = 0
				else 
					setItemName:SetTextByKey("font", tooltip_CSet:GetUserConfig("HAVE_ITEM_FONT"))
					EntireHaveCount = EntireHaveCount + 1
					HaveCount = HaveCount + 1
					clsID = itemCls.ClassID
				end

				setItemName:SetTextByKey("itemname", itemCls.Name)
				local heightMargin = setItemTextCset:GetUserConfig("HEIGHT_MARGIN")
				inner_yPos = inner_yPos + heightMargin;
			end
		end
	end
	set_gbox_type:Resize(set_gbox_type:GetWidth(), inner_yPos)
	
	local USE_SETOPTION_FONT = tooltip_CSet:GetUserConfig("USE_SETOPTION_FONT")
	local NOT_USE_SETOPTION_FONT = tooltip_CSet:GetUserConfig("NOT_USE_SETOPTION_FONT")

	inner_yPos = DEFAULT_POS_Y

	if isUseLegendSet == 1 then
		local prefixCls = GetClass('LegendSetItem', invitem.LegendPrefix)
		local max_option_count = TryGetProp(prefixCls, 'MaxOptionCount', 5)
		if prefixCls ~= nil then
			for i = 0, (max_option_count - 3) do		-- 3 4 5 
			local index = 'EffectDesc_' .. i+ 3
		--	local setEffect = set:GetSetEffect(i);

				local color = USE_SETOPTION_FONT
				if EntireHaveCount >= i + 3 then
					color = NOT_USE_SETOPTION_FONT
				end

				local setTitle = ScpArgMsg("Auto_{s16}{Auto_1}{Auto_2}_SeTeu_HyoKwa__{nl}", "Auto_1",color, "Auto_2",i + 3);
				local setDesc = string.format("{s16}%s%s", color, prefixCls[index]);

				local each_text_CSet = set_gbox_prop:CreateControlSet('tooltip_set_each_prop_text', 'each_text_CSet'..i, inner_xPos, inner_yPos);
				tolua.cast(each_text_CSet, "ui::CControlSet");
				local set_text = GET_CHILD(each_text_CSet,'set_prop_Text','ui::CRichText')
				set_text:SetTextByKey("setTitle",setTitle)
				set_text:SetTextByKey("setDesc",setDesc)

				local labelline = GET_CHILD_RECURSIVELY(each_text_CSet, 'labelline')
				local y_margin = each_text_CSet:GetUserConfig("TEXT_Y_MARGIN")
				local testRect = set_text:GetMargin();
				each_text_CSet:Resize(each_text_CSet:GetWidth(), set_text:GetHeight() + testRect.top);				
				inner_yPos = inner_yPos + each_text_CSet:GetHeight() + y_margin;
			end
		end
	else
		local itemProp = geItemTable.GetProp(invitem.ClassID);

		local set = itemProp.setInfo;
		if set == nil then
			return ypos;
		end
		local cnt =	set:GetItemCount();
		for i = 0, cnt - 1 do
		
			local setEffect = set:GetSetEffect(i);
			if setEffect ~= nil then
				local color = USE_SETOPTION_FONT
				if EntireHaveCount >= i + 1 then
					color = NOT_USE_SETOPTION_FONT
				end

				local setTitle = ScpArgMsg("Auto_{s16}{Auto_1}{Auto_2}_SeTeu_HyoKwa__{nl}", "Auto_1",color, "Auto_2",i + 1);
				local setDesc = string.format("{s16}%s%s", color, setEffect:GetDesc());
		
				local each_text_CSet = set_gbox_prop:CreateControlSet('tooltip_set_each_prop_text', 'each_text_CSet'..i, inner_xPos, inner_yPos);
				tolua.cast(each_text_CSet, "ui::CControlSet");
				local y_margin = each_text_CSet:GetUserConfig("TEXT_Y_MARGIN")
				local set_text = GET_CHILD(each_text_CSet,'set_prop_Text','ui::CRichText')
				set_text:SetTextByKey("setTitle",setTitle)
				set_text:SetTextByKey("setDesc",setDesc)
				local labelline = GET_CHILD_RECURSIVELY(each_text_CSet, 'labelline')
				local testRect = set_text:GetMargin();
				each_text_CSet:Resize(each_text_CSet:GetWidth(), set_text:GetHeight() + testRect.top);
				inner_yPos = inner_yPos + each_text_CSet:GetHeight() + y_margin;
			end
		end
	end

	-- ??? ????????? ??????
	local BOTTOM_MARGIN = tooltipframe:GetUserConfig("BOTTOM_MARGIN");
	set_gbox_prop:Resize( set_gbox_prop:GetWidth() ,inner_yPos  + BOTTOM_MARGIN)
	set_gbox_prop:SetOffset(set_gbox_prop:GetX(),set_gbox_type:GetY()+set_gbox_type:GetHeight())
	tooltip_CSet:Resize(tooltip_CSet:GetWidth(), set_gbox_prop:GetHeight() + set_gbox_prop:GetY() + BOTTOM_MARGIN);
	gBox:Resize(gBox:GetWidth(),gBox:GetHeight() + tooltip_CSet:GetHeight())
	return tooltip_CSet:GetHeight() + tooltip_CSet:GetY();

end

function CHECK_EQUIP_SET_ITEM(invitem, group, prefix)
	local legendGroup = TryGetProp(invitem, "LegendGroup", "None");
	if group ~= nil then
		legendGroup = group;
	end

	local invframe = ui.GetFrame("inventory")

	local RHflag = 0
	local LHflag = 0
	local SHIRTflag = 0
	local PANTSflag = 0
	local GLOVESflag = 0
	local BOOTSflag = 0

	local setItemCount = 0
	if legendGroup == nil or legendGroup == 'None' then
		local itemProp = geItemTable.GetProp(invitem.ClassID);
		local set = itemProp.setInfo;
		if set == nil then
			return 0, 0,0,0,0,0,0
		end
	else
		RHflag, LHflag, SHIRTflag, PANTSflag, GLOVESflag, BOOTSflag = GET_PREFIX_SET_ITEM_FLAG(invitem, prefix)
-- ??????????????? ??? ????????????
		setItemCount = 6
	end

	return setItemCount, RHflag, LHflag, SHIRTflag, PANTSflag, GLOVESflag, BOOTSflag
end

function GET_PREFIX_SET_ITEM_FLAG(invitem, prefix)
	local frame = ui.GetFrame("inventory");
	if frame == nil then
		frame = ui.GetFrame("barrack_charlist")
	end

	local legendPrefix = TryGetProp(invitem, "LegendPrefix", "None");
	if prefix ~= nil then
		legendPrefix = prefix;
	end

	local prefixCls = GetClass('LegendSetItem', legendPrefix)
	if prefixCls == nil then
		return 0, 0, 0, 0, 0, 0;
	end

	local equipTable = {"RH", "LH", "SHIRT", "PANTS", "GLOVES", "BOOTS"};
	local returnValue = {0 , 0, 0, 0, 0, 0};
	for i = 1, #equipTable do
		local slot = GET_CHILD_RECURSIVELY(frame, equipTable[i])
		local slotIcon = slot:GetIcon()
		if slotIcon ~= nil then
			local slotIconInfo = slotIcon:GetInfo()
			local slotItem = GET_ITEM_BY_GUID(slotIconInfo:GetIESID())
			if slotItem ~= nil then
				local obj = GetIES(slotItem:GetObject())
				if prefixCls.ClassName == TryGetProp(obj, 'LegendPrefix') then		
					returnValue[i] = 1;
				else
					returnValue[i] = 0;
				end
			end
		end
	end

	return returnValue[1], returnValue[2], returnValue[3], returnValue[4], returnValue[5], returnValue[6]
end



function CHECK_EQUIP_SET_ITEM_SLOT(invitem, slotName)
	local frame = ui.GetFrame("inventory")
	local flag = 0
	local prefixCls = GetClass('LegendSetItem', invitem.LegendPrefix)
	if prefixCls == nil then
		return flag
	end
	local legendSetName = prefixCls.ClassName
	local slot = GET_CHILD_RECURSIVELY(frame, slotName)
	local slotIcon = slot:GetIcon()
	if slotIcon ~= nil then
		local slotIconInfo = slotIcon:GetInfo()
		local slotItem = GET_ITEM_BY_GUID(slotIconInfo:GetIESID())
		local obj = GetIES(slotItem:GetObject())
		if obj.LegendPrefix == legendSetName then
			flag = 1
		end
	end
	return flag
end

--?????? ????????????(??????, ????????????, ?????? ??????)
function DRAW_AVAILABLE_PROPERTY(tooltipframe, invitem, yPos,mainframename)

	local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')
	gBox:RemoveChild('tooltip_available_property');
	
	local tooltip_available_property_CSet = gBox:CreateControlSet('tooltip_available_property', 'tooltip_available_property', 0, yPos);
	tolua.cast(tooltip_available_property_CSet, "ui::CControlSet");

	local levelNusejob_text = GET_CHILD(tooltip_available_property_CSet,'levelNusejob','ui::CRichText')
	local maxSocekt_text = GET_CHILD(tooltip_available_property_CSet,'maxSocket','ui::CRichText')	

	--???????????? ??????
	if invitem.UseLv > 1 then
		levelNusejob_text:SetTextByKey("level",invitem.UseLv..ScpArgMsg("EQUIP_LEVEL"));
	else
		levelNusejob_text:SetTextByKey("level",ScpArgMsg("UNLIMITED_ITEM_LEVEL"));
	end

	--???????????? ??????
	levelNusejob_text:SetTextByKey("usejob",GET_USEJOB_TOOLTIP(invitem));

	maxSocekt_text:SetOffset(maxSocekt_text:GetX(),levelNusejob_text:GetY() + levelNusejob_text:GetHeight() + 5)

	local itemClass = GetClassByType("Item", invitem.ClassID);

	--???????????? ??????
    local maxSocket = SCR_GET_MAX_SOKET(invitem);
	if maxSocket <= 0 then
		maxSocekt_text:SetText(ScpArgMsg("CantAddSocket"))
	else
		if itemClass.NeedAppraisal == 1 then
			local needAppraisal = TryGetProp(invitem, "NeedAppraisal");
			if nil ~= needAppraisal and needAppraisal == 1 then
				maxSocekt_text:SetTextByKey("socketcount","{@st66d_y}????{/}");
			else
				maxSocekt_text:SetTextByKey("socketcount","{@st66d_y}"..maxSocket.."{/}");
			end
		else
			maxSocekt_text:SetTextByKey("socketcount",maxSocket);
		end
	end

	local BOTTOM_MARGIN = tooltipframe:GetUserConfig("BOTTOM_MARGIN"); -- ??? ????????? ??????
	tooltip_available_property_CSet:Resize(tooltip_available_property_CSet:GetWidth(),maxSocekt_text:GetY() + maxSocekt_text:GetHeight() + BOTTOM_MARGIN);

	gBox:Resize(gBox:GetWidth(),gBox:GetHeight() + tooltip_available_property_CSet:GetHeight())
	return tooltip_available_property_CSet:GetHeight() + tooltip_available_property_CSet:GetY();
end

function DRAW_COLLECTION_INFO(invitem, desc)
	local item_name = TryGetProp(invitem, 'ClassName', 'None')

	if is_collection_item(item_name) == false then
		return desc
	end

	local text = '{@st41b}{#00ee00}'	
	local col_list = get_collection_name_by_item(item_name)

	for k, v in pairs(col_list) do
		text = text .. k .. '{nl}'
	end

	desc = desc .. '{nl} {nl}' .. text

	return desc
end

function DRAW_EQUIP_TRADABILITY(tooltipframe, invitem, yPos, mainframename)
	local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')
	gBox:RemoveChild('tooltip_equip_tradability');
	
	local CSet = gBox:CreateControlSet('tooltip_equip_tradability', 'tooltip_equip_tradability', 0, yPos - 2);
	tolua.cast(CSet, "ui::CControlSet");

	TOGGLE_TRADE_OPTION(CSet, invitem, 'option_npc', 'option_npc_text', 'ShopTrade')
	TOGGLE_TRADE_OPTION(CSet, invitem, 'option_market', 'option_market_text', 'MarketTrade')
	TOGGLE_TRADE_OPTION(CSet, invitem, 'option_teamware', 'option_teamware_text', 'TeamTrade')
	TOGGLE_TRADE_OPTION(CSet, invitem, 'option_trade', 'option_trade_text', 'UserTrade')

    local bottomMargin = CSet:GetUserConfig("BOTTOM_MARGIN");
	CSet:Resize(CSet:GetWidth(), CSet:GetHeight() + bottomMargin)
	gBox:Resize(gBox:GetWidth(), gBox:GetHeight() + CSet:GetHeight())
	return yPos + CSet:GetHeight();
end

-- ?????? ??? ????????????
function DRAW_CANNOT_REINFORCE(tooltipframe, invitem, yPos, mainframename)

	local decomposeAble_flag = 0;
	local reinforce_flag = 0
	local transcend_flag = 0
	local extract_flag = 0
	local socket_flag = 0
	local briquet_flag = 0;
	local briquet_Valid_flag = 0
	local exchange_flag = TryGetProp(invitem, 'Rebuildchangeitem', 0);
	local text = ""

	if TryGetProp(invitem, 'DecomposeAble', 0) == "NO" then
		decomposeAble_flag = 1;
	end

	if REINFORCE_ABLE_131014(invitem) == 0 then
		reinforce_flag = 1
	end
	
	if IS_SEAL_ITEM(invitem) == true then		
		if invitem.MaxReinforceCount > GET_CURRENT_SEAL_LEVEL(invitem) then
			reinforce_flag = 0;
		end
	end

	if IS_TRANSCEND_ABLE_ITEM(invitem) == 0 then
		transcend_flag = 1
	end    

	if IS_VALID_LOOK_ITEM(invitem) == false then
	    briquet_flag = 1;
	end
    
	local itemClass = GetClassByType("Item", invitem.ClassID);
	if (itemClass ~= nil and itemClass.Extractable == 'No') or IS_ENABLE_EXTRACT_OPTION(invitem) ~= true then
		extract_flag = 1
	end

    if TryGetProp(itemClass, "BriquetingAble", "No") == "No" or TryGetProp(itemClass, "StringArg", "None") == "WoodCarving" then
        briquet_Valid_flag = 1
    end

    if invitem.MaxSocket > 100 then invitem.MaxSocket = 0 end
	if invitem.MaxSocket == 0 then
		socket_flag = 1
	end

	local awaken_flag = 0;
	if IS_ENABLE_GIVE_HIDDEN_PROP_ITEM(invitem) == false then
		awaken_flag = 1;
	end
	
	local enchant_flag = 0
	if IS_ENABLE_APPLY_JEWELL_TOOLTIPTEXT(invitem) == false then
	    enchant_flag = 1
	end

	local arklvup_flag = 0
	if TryGetProp(invitem, 'EnableArkLvup', 0) == 1 then
	    arklvup_flag = 1
	end
	
	if TryGetProp(invitem, 'ItemGrade', 0) >= 6 and (GET_EQUIP_GROUP_NAME(invitem) == 'Weapon' or GET_EQUIP_GROUP_NAME(invitem) == 'Armor') then
		awaken_flag = 0
		reinforce_flag = 0
		enchant_flag = 0
	end

	local character_belonging = TryGetProp(invitem, 'CharacterBelonging', 0)

	if reinforce_flag == 0 and transcend_flag == 0 and extract_flag == 0 and socket_flag == 0 and briquet_flag == 0 and exchange_flag == 0 and awaken_flag == 0 and decomposeAble_flag == 0 and enchant_flag == 0 and arklvup_flag == 0 and character_belonging == 0 then
		return yPos
	end
	
	local gBox = GET_CHILD_RECURSIVELY(tooltipframe, mainframename)
	gBox:RemoveChild('tooltip_equip_cannot_reinforce');

	local CSet = gBox:CreateControlSet('tooltip_equip_cannot_reinforce', 'tooltip_equip_cannot_reinforce', 0, yPos);
	tolua.cast(CSet, "ui::CControlSet");

	local socket_text = GET_CHILD_RECURSIVELY(CSet, 'socket_text');

	local function _APPEND_LIMITATION_TEXT(flag, text, targetText, appendComma)
		if flag == 0 then
			return text;
		end

		local _text = text..targetText;
		if appendComma ~= false then
			_text = _text..', ';
		end
		return _text;
	end
	
	text = _APPEND_LIMITATION_TEXT(1, text, CSet:GetUserConfig("TEXT_FONT"), false);
	if TryGetProp(invitem, 'GroupName', 'None') == 'Ark' then
		text = _APPEND_LIMITATION_TEXT(character_belonging, text, ClMsg('CharacterBelongingArkItem'))
	end
	text = _APPEND_LIMITATION_TEXT(decomposeAble_flag, text, CSet:GetUserConfig("DECOMPOSEABLE_TEXT"));
	text = _APPEND_LIMITATION_TEXT(reinforce_flag, text, CSet:GetUserConfig("REINFORCE_TEXT"));
	text = _APPEND_LIMITATION_TEXT(transcend_flag, text, CSet:GetUserConfig("TRANSCEND_TEXT"));
	text = _APPEND_LIMITATION_TEXT(extract_flag, text, CSet:GetUserConfig("EXTRACT_TEXT"));
	text = _APPEND_LIMITATION_TEXT(socket_flag, text, CSet:GetUserConfig("SOCKET_TEXT"));
	text = _APPEND_LIMITATION_TEXT(briquet_flag, text, CSet:GetUserConfig("BRIQUET_TEXT"));
	text = _APPEND_LIMITATION_TEXT(briquet_Valid_flag, text, CSet:GetUserConfig("BRIQUET_VALID_TEXT"));
	text = _APPEND_LIMITATION_TEXT(exchange_flag, text, CSet:GetUserConfig("EXCHANGE_TEXT"));
	text = _APPEND_LIMITATION_TEXT(awaken_flag, text, CSet:GetUserConfig("AWAKEN_TEXT"));
	text = _APPEND_LIMITATION_TEXT(enchant_flag, text, CSet:GetUserConfig("ENCHANT_TEXT"))
	text = _APPEND_LIMITATION_TEXT(arklvup_flag, text, CSet:GetUserConfig("ARKLVUP_VALID_TEXT"))		

	if TryGetProp(invitem, 'StringArg', 'None') == 'TOSHeroEquip' or TryGetProp(invitem, 'StringArg', 'None') == 'TOSHeroEquipNeck' then
		text = '{@st42_gray}{s14}'..ClMsg(TryGetProp(GetClass('ClientMessage', 'TOSHeroEquipTooltip_OnlyUse'), 'ClassName', 'None'))
	end

	if text:sub(-#', ') == ', ' then
		text = text:sub(0, text:len() - 2);
	end

	socket_text:SetText(text);

	local bottomMargin = CSet:GetUserConfig("BOTTOM_MARGIN");

	local DEFAULT_HEIGHT = 50
	local height = math.max(DEFAULT_HEIGHT,socket_text:GetHeight()+12)
	CSet:Resize(CSet:GetWidth(),height)
	return yPos + CSet:GetHeight();
end

--?????? ??? ?????????
function DRAW_EQUIP_PR_N_DUR(tooltipframe, invitem, yPos, mainframename)	

	local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')
	gBox:RemoveChild('tooltip_pr_n_dur');

	local itemClass = GetClassByType("Item", invitem.ClassID);
	if (invitem.GroupName ~= "Armor" and invitem.GroupName ~= "Weapon" ) or invitem.EquipGroup == "WING" then -- ????????? ????????? ?????? ???
		if invitem.BasicTooltipProp == "None" then			
    		return yPos;
		end
	end

	local classtype = TryGetProp(invitem, "ClassType"); -- ???????????? ????????????
	if classtype ~= nil then
		if (classtype == "Outer") 
		or (classtype == "Hat") 
		or (classtype == "Hair") 
		or (classtype == "Seal") 
		or ((itemClass.PR == 0) and (invitem.MaxDur <= 0)) then
			return yPos;
		end
		
		local isHaveLifeTime = TryGetProp(invitem, "LifeTime", 0);	
		if isHaveLifeTime ~= nil then
            isHaveLifeTime = tonumber(isHaveLifeTime)
			if ((isHaveLifeTime > 0) and (invitem.MaxDur <= 0))  then
				return yPos;
			end;
		end
	end
	
	local CSet = gBox:CreateControlSet('tooltip_pr_n_dur', 'tooltip_pr_n_dur', 0, yPos);
	tolua.cast(CSet, "ui::CControlSet");

	local inf_value = CSet:GetUserConfig("INF_VALUE")

	local pr_gauge = GET_CHILD(CSet,'pr_gauge','ui::CGauge')
	local mpr = invitem.MaxPR;
	if 0 == mpr then
		mpr = itemClass.PR;
	end

	pr_gauge:SetPoint(invitem.PR, mpr);

	local dur_gauge = GET_CHILD(CSet,'dur_gauge','ui::CGauge')
	local temparg1 = math.floor(invitem.Dur/100);
	local temparg2 = math.floor(invitem.MaxDur/100);
	if  invitem.MaxDur == -1 then
		dur_gauge:SetPoint(inf_value, inf_value);
	else
		dur_gauge:SetPoint(temparg1, temparg2);
	end

	if itemClass.NeedAppraisal == 1 or itemClass.NeedRandomOption == 1 then
		local needAppraisal = TryGetProp(invitem, "NeedAppraisal");
		local needRandomOption = TryGetProp(invitem, "NeedRandomOption");
		if needAppraisal ~= nil and  needAppraisal == 0 and itemClass.NeedAppraisal == 1 then -- ???????????????
			pr_gauge:SetStatFont(0, "yellow_14_b")
		elseif  needRandomOption == 1 or needAppraisal == 1 then --??????????????????
		    if needAppraisal == 1 then 
			    pr_gauge:SetTextStat(0, "{@st66d_y}????{/}")
            end
            
			local picture = CSet:CreateControl('picture', 'appraisalPic', 0, dur_gauge:GetY(), 400, 46);
		--	picture:SetGravity(ui.CENTER_VERT, ui.TOP)
			picture:ShowWindow(1);
			picture = tolua.cast(picture, "ui::CPicture");
			picture:SetImage("USsentiment_message");

			local rect = picture:CreateControl('richtext', 'appraisalStr', 200, 40, ui.CENTER_VERT, ui.CENTER_HORZ, 0, 0, 0, 0);
			rect = tolua.cast(rect, "ui::CRichText");
			rect:SetText('{@st66b}'..ScpArgMsg("AppraisalItem"))
			rect:SetTextAlign("center","center");
			CSet:Resize(CSet:GetWidth(),CSet:GetHeight() + picture:GetHeight() - 30);
		end
	end

	local extraMarginY = 0;

	local dur_text = GET_CHILD(CSet,'dur_text');
	local pr_text = GET_CHILD(CSet,'pr_text');

	if invitem.MaxDur <= 0 then
		dur_text:ShowWindow(0);
		dur_gauge:ShowWindow(0);
		pr_gauge:SetPos(pr_gauge:GetOffsetX(), 10);
		pr_text:SetPos(pr_text:GetOffsetX(), 20);
		extraMarginY = 0;
	else
		dur_text:ShowWindow(1);
		dur_gauge:ShowWindow(1);
	end
	
	if itemClass.PR <= 0 then
		pr_text:ShowWindow(0);
		pr_gauge:ShowWindow(0);
		dur_gauge:SetPos(dur_gauge:GetOffsetX(), 10);
		dur_text:SetPos(dur_text:GetOffsetX(), 20);
		extraMarginY = 0;
	else
		pr_text:ShowWindow(1);
		pr_gauge:ShowWindow(1);
	end

	local BOTTOM_MARGIN = tooltipframe:GetUserConfig("BOTTOM_MARGIN"); -- ??? ????????? ??????
	CSet:Resize(CSet:GetWidth(),CSet:GetHeight() + BOTTOM_MARGIN - extraMarginY);

	gBox:Resize(gBox:GetWidth(),gBox:GetHeight() + CSet:GetHeight()- extraMarginY)
	return CSet:GetHeight() + CSet:GetY() - extraMarginY;
end

--???????????? ??? ????????? ???????????? ?????? ???
function DRAW_EQUIP_ONLY_PR(tooltipframe, invitem, yPos, mainframename)

	local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')
	gBox:RemoveChild('tooltip_only_pr');

	local itemClass = GetClassByType("Item", invitem.ClassID);

	local classtype = TryGetProp(invitem, "ClassType"); -- ???????????? ????????????
		
	if classtype ~= nil then
		if (classtype ~= "Hat" and invitem.BasicTooltipProp ~= "None")
		or (itemClass.PR == 0) 
		or (classtype == "Outer")
		or (classtype == "Seal")
		or (itemClass.ItemGrade == 0 and classtype == "Hair") then
			return yPos;
		end;
	end

	local CSet = gBox:CreateControlSet('tooltip_only_pr', 'tooltip_only_pr', 0, yPos);
	tolua.cast(CSet, "ui::CControlSet");

	local pr_gauge = GET_CHILD(CSet,'pr_gauge','ui::CGauge')
	pr_gauge:SetPoint(invitem.PR, itemClass.PR);

	local BOTTOM_MARGIN = tooltipframe:GetUserConfig("BOTTOM_MARGIN"); -- ??? ????????? ??????
	CSet:Resize(CSet:GetWidth(),CSet:GetHeight() + BOTTOM_MARGIN);

	gBox:Resize(gBox:GetWidth(),gBox:GetHeight() + CSet:GetHeight())
	return CSet:GetHeight() + CSet:GetY();
end

-- ???????????? ??????
function DRAW_EQUIP_VIBORA_REFINE(tooltipframe, invitem, yPos, mainframename)	
	if TryGetProp(invitem, 'UPGRADE_TRY_COUNT', 0) == 0 then
		return yPos
	end

	local is_vibora = false
	local current_vibora_lv = 2
	
	-- ???????????? ??????
	if TryGetProp(invitem, 'StringArg', 'None') == 'Vibora' and (TryGetProp(invitem, 'NumberArg1', 0) >= 2 and TryGetProp(invitem, 'NumberArg1', 0) < MAX_VIBORA_LEVEL) then
		is_vibora = true		
		current_vibora_lv = TryGetProp(invitem, 'NumberArg1', 0)
	end

	if is_vibora == false and TryGetProp(invitem, 'GroupName', 'None') == 'Icor' then
		local cls = GetClass('Item', TryGetProp(invitem, 'InheritanceItemName', 'None'))
		if cls ~= nil then
			if TryGetProp(cls, 'StringArg', 'None') == 'Vibora' and (TryGetProp(cls, 'NumberArg1', 0) >= 2 and TryGetProp(cls, 'NumberArg1', 0) < MAX_VIBORA_LEVEL) then		
				current_vibora_lv = TryGetProp(cls, 'NumberArg1', 0)
				is_vibora = true
			end	
		end
	end

	if is_vibora == false and TryGetProp(invitem, 'InheritanceItemName', 'None') ~= 'None' then
		local cls = GetClass('Item', TryGetProp(invitem, 'InheritanceItemName', 'None'))
		if cls ~= nil then
			if TryGetProp(cls, 'StringArg', 'None') == 'Vibora' and (TryGetProp(cls, 'NumberArg1', 0) >= 2 and TryGetProp(cls, 'NumberArg1', 0) < MAX_VIBORA_LEVEL) then		
				current_vibora_lv = TryGetProp(cls, 'NumberArg1', 0)
				is_vibora = true
			end	
		end
	end	
	
	if is_vibora == true then
		local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')
		gBox:RemoveChild('tooltip_refine');

		local CSet = gBox:CreateControlSet('tooltip_refine', 'tooltip_refine', 0, yPos);
		tolua.cast(CSet, "ui::CControlSet");
		
		local pr_gauge = GET_CHILD(CSet,'pr_gauge','ui::CGauge')
		pr_gauge:SetPoint(TryGetProp(invitem, 'UPGRADE_TRY_COUNT', 0), GET_UPGRADE_VIBORA_MAX_COUNT(current_vibora_lv + 1));

		local BOTTOM_MARGIN = tooltipframe:GetUserConfig("BOTTOM_MARGIN"); -- ??? ????????? ??????
		CSet:Resize(CSet:GetWidth(),CSet:GetHeight() + BOTTOM_MARGIN);
		
		gBox:Resize(gBox:GetWidth(),gBox:GetHeight() + CSet:GetHeight())	
		return CSet:GetHeight() + CSet:GetY();
	else
		return yPos
	end
end

-- ?????? ?????? ??????
function DRAW_EQUIP_GODDESS_REFINE(tooltipframe, invitem, yPos, mainframename)		
	if TryGetProp(invitem, 'UPGRADE_GODDESS_TRY_COUNT', 0) == 0 then
		return yPos
	end
	
	local is_goddess = false
	local current_lv = 2
	
	-- ?????? ?????? ??????
	if (TryGetProp(invitem, 'StringArg', 'None') == 'evil' or TryGetProp(invitem, 'StringArg', 'None') == 'goddess') 
		and TryGetProp(invitem, 'NumberArg1', 0) >= 1 and TryGetProp(invitem, 'NumberArg1', 0) < MAX_GODDESS_LEVEL then
		is_goddess = true		
		current_lv = TryGetProp(invitem, 'NumberArg1', 0)
	end

	if is_goddess == false and TryGetProp(invitem, 'GroupName', 'None') == 'Icor' then
		local cls = GetClass('Item', TryGetProp(invitem, 'InheritanceItemName', 'None'))
		if cls ~= nil then
			if (TryGetProp(cls, 'StringArg', 'None') == 'evil' or TryGetProp(cls, 'StringArg', 'None') == 'goddess') 
			and TryGetProp(cls, 'NumberArg1', 0) >= 1 and TryGetProp(cls, 'NumberArg1', 0) < MAX_GODDESS_LEVEL then
				current_lv = TryGetProp(cls, 'NumberArg1', 0)
				is_goddess = true
			end	
		end
	end

	if is_goddess == false and TryGetProp(invitem, 'InheritanceItemName', 'None') ~= 'None' then
		local cls = GetClass('Item', TryGetProp(invitem, 'InheritanceItemName', 'None'))
		if cls ~= nil then
			if (TryGetProp(cls, 'StringArg', 'None') == 'evil' or TryGetProp(cls, 'StringArg', 'None') == 'goddess') 
			and TryGetProp(cls, 'NumberArg1', 0) >= 1 and TryGetProp(cls, 'NumberArg1', 0) < MAX_GODDESS_LEVEL then
				current_lv = TryGetProp(cls, 'NumberArg1', 0)
				is_goddess = true
			end	
		end
	end

	if is_goddess == true then		
		local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')
		gBox:RemoveChild('tooltip_refine');

		local CSet = gBox:CreateControlSet('tooltip_refine', 'tooltip_refine', 0, yPos);
		tolua.cast(CSet, "ui::CControlSet");
		
		local pr_gauge = GET_CHILD(CSet,'pr_gauge','ui::CGauge')
		pr_gauge:SetPoint(TryGetProp(invitem, 'UPGRADE_GODDESS_TRY_COUNT', 0), GET_UPGRADE_GODDESS_MAX_COUNT(current_lv + 1));

		local BOTTOM_MARGIN = tooltipframe:GetUserConfig("BOTTOM_MARGIN"); -- ??? ????????? ??????
		CSet:Resize(CSet:GetWidth(),CSet:GetHeight() + BOTTOM_MARGIN);
		
		gBox:Resize(gBox:GetWidth(),gBox:GetHeight() + CSet:GetHeight())	
		return CSet:GetHeight() + CSet:GetY();
	else
		return yPos
	end
end

-- ????????? ??????
function DRAW_TOGGLE_EQUIP_DESC(tooltipframe, invitem, yPos, mainframename)
	local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')
	gBox:RemoveChild('tooltip_toggle_desc');

	local tooltip_toggle_CSet = gBox:CreateControlSet('tooltip_toggle_desc', 'tooltip_toggle_desc', 0, yPos);
	tolua.cast(tooltip_toggle_CSet, "ui::CControlSet");
	local toggle_desc_text = GET_CHILD(tooltip_toggle_CSet, 'toggle_desc_text', 'ui::CRichText');

    local toggleText = ClMsg('Show');
    if IS_TOGGLE_EQUIP_ITEM_TOOLTIP_DESC() ~= 1 then
        toggleText = ClMsg('Close');
	end
    toggle_desc_text:SetTextByKey('Toggle', toggleText);

	gBox:Resize(gBox:GetWidth(), gBox:GetHeight() + tooltip_toggle_CSet:GetHeight())
	return tooltip_toggle_CSet:GetHeight() + tooltip_toggle_CSet:GetY();
end

function IS_USE_SET_TOOLTIP(invitem)
	local itemClass = GetClassByType("Item", invitem.ClassID);
	local type = itemClass.ClassType;
	if type == nil then
		return 0
	end

	if type == 'Helmet' 
		or type == 'Armband' 
		or type == 'Hair' 
		or type == 'Lens' 
		or type == 'Outer' 
		or type == 'Hat' 
		or type == 'Artefact' 
		or type == 'Wing'
		or type == 'SpecialCostume'
		or type == 'EffectCostume' then
		return 0
	else
		return 1
	end

end

----------------- ?????? ????????? tooltip -----------------
-- ?????? ?????? ?????? text ?????? 
local function _CREATE_ARK_LV(gBox, ypos, step, class_name, curlv)
	local margin = 5;

	class_name = replace(class_name, 'PVP_', '')

	local func_str = string.format('get_tooltip_%s_arg%d', class_name, step)
    local tooltip_func = _G[func_str]  -- get_tooltip_Ark_str_arg1 ?????????
	if tooltip_func ~= nil then
		local tooltip_type, status, interval, add_value, summon_atk, client_msg, unit = tooltip_func();		
		local option_active_lv = nil
		local option_active_func_str = string.format('get_%s_option_active_lv', class_name)
		local option_active_func = _G[option_active_func_str]
		if option_active_func ~= nil then
			option_active_lv = option_active_func();			
		end

		local option = status        
		local grade_count = math.floor(curlv / interval);
		if tooltip_type == 3 then
			add_value = add_value * grade_count
		else
			add_value = math.floor(add_value * grade_count);		
		end
		
		if add_value <= 0 and (option_active_lv == nil or curlv < option_active_lv)then			
			return ypos;
		end
		
		local strInfo = ABILITY_DESC_PLUS(ScpArgMsg(option), add_value)
		
		if tooltip_type == 2 then
			local add_msg =  string.format(", %s "..ScpArgMsg("PropUp").."%.1f", ScpArgMsg('SUMMON_ATK'), math.abs(add_value / 200)) .. '%'
			strInfo = strInfo .. ' ' .. add_msg
		elseif tooltip_type == 3 then
			if unit == nil then				
				strInfo = string.format(" - %s "..ScpArgMsg("PropUp").."%d", ScpArgMsg(option), add_value + summon_atk) .. '%'								
			else
				strInfo = string.format(" - %s "..ScpArgMsg("PropUp").."%d", ScpArgMsg(option), add_value + summon_atk) .. unit				
			end
		elseif tooltip_type == 4 then
			if unit == nil then
				strInfo = string.format(" - %s "..ScpArgMsg("PropUp").."%d", ScpArgMsg(option), add_value + summon_atk) .. '%'
			else
				strInfo = string.format(" - %s "..ScpArgMsg("PropUp").."%d", ScpArgMsg(option), add_value + summon_atk) .. unit				
			end
		end		
		
		local infoText = gBox:CreateControl('richtext', 'infoText'..step, 15, ypos, gBox:GetWidth(), 30);
		infoText:SetText(strInfo);		
		infoText:SetFontName("brown_16");
		ypos = ypos + infoText:GetHeight() + margin;
	end

	return ypos;
end

-- ?????? text ?????? 
local function _CREATE_ARK_OPTION(gBox, ypos, step, class_name)
	local margin = 5;

	class_name = replace(class_name, 'PVP_', '')

	local func_str = string.format('get_tooltip_%s_arg%d', class_name, step)
    local tooltip_func = _G[func_str]  -- get_tooltip_Ark_str_arg1 ?????????
	if tooltip_func ~= nil then
		local tooltip_type, status, interval, add_value, summon_atk, client_msg, unit = tooltip_func();
		local option = status
		local infoText = gBox:CreateControl('richtext', 'infoText'..step, 15, ypos, gBox:GetWidth(), 30);
		local text = ''
		if tooltip_type == 1 then
			text = ScpArgMsg("ArkOptionText{Option}{interval}{addvalue}", "Option", ClMsg(option), "interval", interval, "addvalue", add_value)
		elseif tooltip_type == 2 then
			text = ScpArgMsg("ArkOptionText{Option}{interval}{addvalue}{option2}{addvalue2}", "Option", ClMsg(option), "interval", interval, "addvalue", add_value, 'option2', ClMsg(summon_atk), 'addvalue2', string.format('%.1f', add_value / 200))
		elseif tooltip_type == 3 then			
			if client_msg == nil then
				text = ScpArgMsg("ArkOptionText3{Option}{interval}{addvalue}", "Option", ClMsg(option), "interval", interval, "addvalue", add_value)				
			else
				text = ScpArgMsg(client_msg, "Option", ClMsg(option), "interval", interval, "addvalue", add_value)				
			end
		elseif tooltip_type == 4 then			
			text = ScpArgMsg("ArkOptionText4{Option}{interval}{addvalue}", "Option", ClMsg(option), "interval", interval, "addvalue", add_value)
		end
		
		infoText:SetText(text);
		infoText:SetFontName("brown_16_b");
		ypos = ypos + infoText:GetHeight() + margin;
	end

	return ypos;
end

function ITEM_TOOLTIP_ARK(tooltipframe, invitem, strarg, usesubframe)
	if invitem.ClassType ~= 'Ark' then return end

	tolua.cast(tooltipframe, "ui::CTooltipFrame");
	local mainframename = 'equip_main'
	local ypos = 0

	ypos = DRAW_EQUIP_COMMON_TOOLTIP_SMALL_IMG(tooltipframe, invitem, mainframename); -- ???????????? ??????????????? ????????? ?????????

	ypos = DRAW_ARK_LV(tooltipframe, invitem, ypos, mainframename); 			-- ??????, ????????? ?????? ?????? ?????? ?????? ???

	ypos = DRAW_ARK_OPTION(tooltipframe, invitem, ypos, mainframename); 		-- ?????? ??????
	
	if TryGetProp(invitem, 'EnableArkLvup', 0) == 0 then
		ypos = DRAW_ARK_EXP(tooltipframe, invitem, ypos, mainframename)				-- ?????? ?????????
	end

	ypos = DRAW_EQUIP_MEMO(tooltipframe, invitem, ypos, mainframename); 		-- ????????? ?????? ??? ????????? ??????
	ypos = DRAW_EQUIP_ARK_DESC(tooltipframe, invitem, ypos, mainframename); 		-- ?????? ?????????

	ypos = DRAW_EQUIP_TRADABILITY(tooltipframe, invitem, ypos, mainframename); 	-- ?????? ??????
	ypos = DRAW_CANNOT_REINFORCE(tooltipframe, invitem, ypos, mainframename); 	-- ?????? ??? ????????????

	local isHaveLifeTime = TryGetProp(invitem, "LifeTime", 0);					-- ?????????
	if 0 == tonumber(isHaveLifeTime) then
		ypos = DRAW_SELL_PRICE(tooltipframe, invitem, ypos, mainframename);
	else
		ypos = DRAW_REMAIN_LIFE_TIME(tooltipframe, invitem, ypos, mainframename);
	end
	
	ypos = ypos + 3;
    ypos = DRAW_TOGGLE_EQUIP_DESC(tooltipframe, invitem, ypos, mainframename); -- ????????? ?????? ??????

    local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')
    gBox:Resize(gBox:GetWidth(), ypos)
end

-- ?????? ?????? ??????, ????????? ?????? ?????? ?????? ?????? 
function DRAW_ARK_LV(tooltipframe, invitem, ypos, mainframename)
	local class_name = TryGetProp(invitem, 'ClassName', 'None')	
	if class_name == 'None' then return; end

	class_name = replace(class_name, 'PVP_', '')

	local gBox = GET_CHILD(tooltipframe, mainframename);
	if gBox == nil then return; end

	local CSet = gBox:CreateOrGetControlSet('tooltip_ark_lv', 'tooltip_ark_lv', 0, ypos);

	-- ?????? ??????
	local curlv = TryGetProp(invitem, 'ArkLevel', 1)
	local lvtext = GET_CHILD(CSet, 'lv', 'ui::CRichText');
	lvtext:SetTextByKey("value", curlv);

	-- ????????? ?????? ?????? ?????? text
	local _ypos = 43;			-- offset
	for i = 1, max_ark_option_count do 	-- ????????? ?????? 10??? ????????? ?????????		
		_ypos = _CREATE_ARK_LV(CSet, _ypos, i, class_name, curlv);
	end
	
	CSet:Resize(CSet:GetWidth(), _ypos + 5);
	ypos = ypos + CSet:GetHeight() + 5;

	return ypos;
end

-- ?????? ????????? ?????? ????????? 
function DRAW_ARK_OPTION(tooltipframe, invitem, ypos, mainframename)
	local class_name = TryGetProp(invitem, 'ClassName', 'None')
	if class_name == 'None' then return; end

	class_name = replace(class_name, 'PVP_', '')

	local gBox = GET_CHILD(tooltipframe, mainframename);
	if gBox == nil then return; end

	local CSet = gBox:CreateOrGetControlSet('item_tooltip_ark', 'item_tooltip_ark', 0, ypos);
	
	local margin = 5;
	local _ypos = margin;

	for i = 1, max_ark_option_count do 	-- ????????? ?????? 10??? ????????? ?????????
		_ypos = _CREATE_ARK_OPTION(CSet, _ypos, i, class_name);
	end

	CSet:Resize(CSet:GetWidth(), _ypos + 3);
	ypos = ypos + CSet:GetHeight();

	return ypos;
end

-- ?????? ?????? ?????? ????????? ????????? 
function DRAW_ARK_EXP(tooltipframe, invitem, ypos, mainframename)
	local gBox = GET_CHILD(tooltipframe, mainframename);
	if gBox == nil then return; end
	
	local margin = 5;
	local CSet = gBox:CreateOrGetControlSet('tooltip_ark_exp', 'tooltip_ark_exp', 0, ypos);

	local curexp = TryGetProp(invitem, 'ArkExp', 0)
	local isnextexp, nextexp = shared_item_ark.get_next_lv_exp(invitem)	
	
	if shared_item_ark.is_max_lv(invitem) == 'YES' then		-- max ????????? ??????
		isnextexp, nextexp = shared_item_ark.get_current_lv_exp(invitem)
		curexp = nextexp		
	end
	local gauge = GET_CHILD(CSet,'gauge','ui::CGauge')
		gauge:SetPoint(curexp, nextexp);

	CSet:Resize(CSet:GetWidth(),CSet:GetHeight());
	ypos = ypos + CSet:GetHeight() + margin;

	return ypos;
end
----------------- ?????? ????????? tooltip -----------------

-- ?????? tooltip --
local relic_text_margin = 10

local function _CREATE_RELIC_LV_OPTION(gBox, ypos, step, class_name, curlv)
	local margin = 5

	class_name = replace(class_name, 'PVP_', '')

	local func_str = string.format('get_tooltip_%s_arg%d', class_name, step)
	local tooltip_func = _G[func_str]
	if tooltip_func ~= nil then
		local value, name, interval, type = tooltip_func()
		local total = value * math.floor(curlv / interval)
		local msg = string.format('RelicOptionLongText%s', type)
		local strInfo = ScpArgMsg(msg, 'name', ClMsg(name), 'total', total, 'interval', interval, 'value', value)

		local infoText = gBox:CreateControl('richtext', 'infoText'..step, relic_text_margin, ypos, gBox:GetWidth() - relic_text_margin, 30)
		infoText:SetTextFixWidth(1)
		infoText:SetText(strInfo)
		infoText:SetFontName('brown_16')
		ypos = ypos + infoText:GetHeight() + margin
		
		local item = GetClass('Item', class_name)
		local value2 = math.max(1, math.floor(curlv/2))
		local msg2 = string.format('RelicOptionEnableEquipGemLevel', type)
		local strInfo2 = ScpArgMsg(msg2, 'value', value2)
		
		local infoText2 = gBox:CreateControl('richtext', 'infoText2'..step, relic_text_margin, ypos, gBox:GetWidth() - relic_text_margin, 40)
		infoText2:SetTextFixWidth(1)
		infoText2:SetText(strInfo2)
		infoText2:SetFontName('brown_16')
		ypos = ypos + infoText2:GetHeight() + margin
	end

	return ypos
end

function ITEM_TOOLTIP_RELIC(tooltipframe, invitem, strarg, usesubframe)	
	if invitem.ClassType ~= 'Relic' then return end

	tolua.cast(tooltipframe, 'ui::CTooltipFrame')
	local mainframename = 'equip_main'
	local ypos = 0

	ypos = DRAW_EQUIP_COMMON_TOOLTIP_SMALL_IMG(tooltipframe, invitem, mainframename) -- ???????????? ??????????????? ????????? ?????????

	ypos = DRAW_RELIC_LV_OPTION(tooltipframe, invitem, ypos, mainframename) -- ??????, ??????
	ypos = DRAW_RELIC_EXP(tooltipframe, invitem, ypos, mainframename) -- ?????????
	ypos = DRAW_RELIC_SOCKET(tooltipframe, invitem, ypos, mainframename)
	ypos = DRAW_EQUIP_RELIC_DESC(tooltipframe, invitem, ypos, mainframename) -- ?????? ?????????

	ypos = DRAW_EQUIP_TRADABILITY(tooltipframe, invitem, ypos, mainframename) -- ?????? ??????
	ypos = DRAW_CANNOT_REINFORCE(tooltipframe, invitem, ypos, mainframename) -- ?????? ??? ????????????

	local isHaveLifeTime = TryGetProp(invitem, 'LifeTime', 0) -- ?????????
	if 0 == tonumber(isHaveLifeTime) then
		ypos = DRAW_SELL_PRICE(tooltipframe, invitem, ypos, mainframename)
	else
		ypos = DRAW_REMAIN_LIFE_TIME(tooltipframe, invitem, ypos, mainframename)
	end
	
	ypos = ypos + 3
    ypos = DRAW_TOGGLE_EQUIP_DESC(tooltipframe, invitem, ypos, mainframename) -- ????????? ?????? ??????

    local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')
    gBox:Resize(gBox:GetWidth(), ypos)
end

function DRAW_RELIC_LV_OPTION(tooltipframe, invitem, ypos, mainframename)	
	local margin = 5

	local class_name = TryGetProp(invitem, 'ClassName', 'None')	
	if class_name == 'None' then return end

	local item = GET_INV_ITEM_BY_ITEM_OBJ(invitem)
	if item == nil then return end

	class_name = replace(class_name, 'PVP_', '')

	local gBox = GET_CHILD(tooltipframe, mainframename)
	if gBox == nil then return end

	local CSet = gBox:CreateOrGetControlSet('tooltip_ark_lv', 'tooltip_relic_lv', 0, ypos)

	-- ?????? ??????
	local curlv = TryGetProp(invitem, 'Relic_LV', 1)
	local lvtext = GET_CHILD(CSet, 'lv', 'ui::CRichText')
	lvtext:SetTextByKey('value', curlv)

	-- ????????? ?????? ?????? ?????? text
	local _ypos = 43 -- offset
	for i = 1, max_relic_option_count do -- shared
		_ypos = _CREATE_RELIC_LV_OPTION(CSet, _ypos, i, class_name, curlv)
	end
	
	CSet:Resize(CSet:GetWidth(), _ypos + margin)
	ypos = ypos + CSet:GetHeight() + margin

	return ypos
end

function DRAW_RELIC_EXP(tooltipframe, invitem, ypos, mainframename)
	local gBox = GET_CHILD(tooltipframe, mainframename)
	if gBox == nil then return end
	
	local margin = 5
	local CSet = gBox:CreateOrGetControlSet('tooltip_relic_exp', 'tooltip_relic_exp', 0, ypos)

	if app.IsBarrackMode() == true then
		invitem.Relic_LV = TryGetProp(GetMyAccountObj(), 'Relic_LV', 1)
		invitem.Relic_EXP = TryGetProp(GetMyAccountObj(), 'Relic_EXP', 0)
	end

	local cur_lv = shared_item_relic.get_current_lv(invitem)
	local cur_exp = shared_item_relic.get_current_exp(invitem)
	local cur_lv_exp = shared_item_relic.get_current_lv_exp(invitem)
	local next_exp = shared_item_relic.get_current_lv_exp_interval(invitem)
	local cur_exp = cur_exp - cur_lv_exp
	if shared_item_relic.is_max_lv(invitem) == 'YES' then -- ????????? full
		cur_exp = next_exp
	end	

	local gauge = GET_CHILD(CSet, 'gauge', 'ui::CGauge')
	gauge:SetPoint(cur_exp, next_exp)

	CSet:Resize(CSet:GetWidth(),CSet:GetHeight())
	ypos = ypos + CSet:GetHeight() + margin

	return ypos
end

function DRAW_RELIC_SOCKET(tooltipframe, itemObj, yPos, addinfoframename)
	local value = IS_TOGGLE_EQUIP_ITEM_TOOLTIP_DESC()
    if value == 1 then
        return yPos
	end

	local gBox = GET_CHILD(tooltipframe, addinfoframename, 'ui::CGroupBox')
	gBox:RemoveChild('tooltip_relic_socket')
	
	local tooltip_equip_socket_CSet = gBox:CreateOrGetControlSet('tooltip_equip_property', 'tooltip_relic_socket', 0, yPos)
	
	local invitem = GET_INV_ITEM_BY_ITEM_OBJ(itemObj)
	if invitem == nil then
		return yPos
	end

	local gBox = GET_CHILD(tooltipframe, addinfoframename, 'ui::CGroupBox')
	local tooltip_equip_socket_CSet = GET_CHILD_RECURSIVELY(gBox, 'tooltip_relic_socket')
	local socket_gbox = GET_CHILD(tooltip_equip_socket_CSet, 'property_gbox', 'ui::CGroupBox')

	tolua.cast(tooltip_equip_socket_CSet, 'ui::CControlSet')
	local inner_yPos = 0

	local function _GET_EMPTY_SOCKET_IMAGE(type)
		local image = 'freegemslot_image'
		if type == 0 then
			image = 'socket_cyan'
		elseif type == 1 then
			image = 'socket_magenta'
		elseif type == 2 then
			image = 'socket_black'
		end
	
		return image
	end

	local function _ADD_ITEM_SOCKET_PROP(GroupCtrl, invitem, socket, gemID, gemLv, yPos)
		if GroupCtrl == nil then
			return 0
		end

		local cnt = GroupCtrl:GetChildCount()

		local ControlSetObj = GroupCtrl:CreateControlSet('tooltip_item_prop_socket', 'ITEM_PROP_' .. cnt , 0, yPos)
		local ControlSetCtrl = tolua.cast(ControlSetObj, 'ui::CControlSet')
	
		local socket_image = GET_CHILD(ControlSetCtrl, 'socket_image', 'ui::CPicture')
		local socket_property_text = GET_CHILD(ControlSetCtrl, 'socket_property', 'ui::CRichText')
		local gradetext = GET_CHILD_RECURSIVELY(ControlSetCtrl, 'grade', 'ui::CRichText')
	
		local NEGATIVE_COLOR = ControlSetObj:GetUserConfig('NEGATIVE_COLOR')
		local POSITIVE_COLOR = ControlSetObj:GetUserConfig('POSITIVE_COLOR')
		if gemID == 0 then
			local socket_image_name = _GET_EMPTY_SOCKET_IMAGE(socket)
			socket_image:SetImage(socket_image_name)

			local socket_type_str = 'Gem_Relic_Cyan'
			for _name, _type in pairs(relic_gem_type) do
				if _type == socket then
					socket_type_str = _name
					break
				end
			end
			local empty_socket_name	= ScpArgMsg('EMPTY_RELIC_GEM_SOCKET', 'NAME', ClMsg(socket_type_str))
			socket_property_text:SetText(empty_socket_name)
				
			gradetext:ShowWindow(0)
		else
			local gemclass = GetClassByType('Item', gemID)
			local socket_image_name = gemclass.Icon
			socket_image:SetImage(socket_image_name)		
			
			gradetext:SetText('Lv ' .. gemLv)
			gradetext:ShowWindow(1)
			
			local desc = GET_RELIC_GEM_NAME_WITH_FONT(gemclass)
			socket_property_text:SetText(desc)
			socket_property_text:ShowWindow(1)
			ControlSetCtrl:Resize(ControlSetCtrl:GetWidth(), math.max(ControlSetCtrl:GetHeight(), socket_property_text:GetHeight()))
		end
	
		GroupCtrl:ShowWindow(1)
		GroupCtrl:Resize(GroupCtrl:GetWidth(), GroupCtrl:GetHeight() + ControlSetObj:GetHeight() + 7)
		return ControlSetCtrl:GetHeight() + ControlSetCtrl:GetY() + 5
	end	

	local curCount = 0
	local BOTTOM_MARGIN = 10
	for i = 0, max_relic_gem_socket_count - 1 do
		local gem_class_id = invitem:GetEquipGemID(i)
		local gem_lv = invitem:GetEquipGemLv(i)
		inner_yPos = _ADD_ITEM_SOCKET_PROP(socket_gbox, itemObj, i, gem_class_id, gem_lv, inner_yPos)

		if gem_class_id ~= 0 then
			local gem_class = GetClassByType('Item', gem_class_id)
			local gem_type = relic_gem_type[TryGetProp(gem_class, 'GemType', 'None')]
			if gem_type == 0 then
				inner_yPos = _RELIC_GEM_SPEND_RP_OPTION(socket_gbox, inner_yPos, gem_class_id)
				inner_yPos = _RELIC_GEM_RELEASE_OPTION(socket_gbox, inner_yPos, gem_class_id)
			elseif gem_type == 1 then
				inner_yPos = _RELIC_GEM_SPEND_RP_OPTION(socket_gbox, inner_yPos, gem_class_id)
			end
			
			for i = 1, max_relic_option_count do
				inner_yPos = _RELIC_GEM_OPTION_BY_LV(socket_gbox, inner_yPos, gem_type, i, gem_class.ClassName, gem_lv)
			end
		end
		
		inner_yPos = inner_yPos + BOTTOM_MARGIN
		curCount = curCount + 1
	end
	
	socket_gbox:Resize(socket_gbox:GetWidth(), inner_yPos)
	tooltip_equip_socket_CSet:Resize(tooltip_equip_socket_CSet:GetWidth(), socket_gbox:GetHeight() + socket_gbox:GetY() + BOTTOM_MARGIN)

	gBox:Resize(gBox:GetWidth(), gBox:GetHeight() + tooltip_equip_socket_CSet:GetHeight())
	return tooltip_equip_socket_CSet:GetHeight() + tooltip_equip_socket_CSet:GetY()
end

function DRAW_EQUIP_RELIC_DESC(tooltipframe, invitem, yPos, mainframename)
	local class_name = TryGetProp(invitem, 'ClassName', 'None')
	local tooltip_type = 1

	local desc = ''
	
	class_name = replace(class_name, 'PVP_', '')
	
	local func_str = string.format('get_tooltip_%s_arg%d', class_name, 2)
	local tooltip_func = _G[func_str]  -- get_tooltip_Ark_str_arg1 ?????????
	if tooltip_func ~= nil then
		local tooltiptype, option, level, value, base_value = tooltip_func()
		tooltip_type = tooltiptype
	end	
	
	if tooltip_type == 3 then
		local msg = class_name .. '_desc{base1}{base2}'
		local base1 = ''
		local base2 = ''
		local func_str = string.format('get_tooltip_%s_arg%d', class_name, 2)
		local tooltip_func = _G[func_str]  -- get_tooltip_Ark_str_arg1 ?????????
		if tooltip_func ~= nil then
			local tooltiptype, option, level, value, base_value = tooltip_func()
			base1 = base_value
		end
		local func_str = string.format('get_tooltip_%s_arg%d', class_name, 3)
		local tooltip_func = _G[func_str]  -- get_tooltip_Ark_str_arg1 ?????????
		if tooltip_func ~= nil then
			local tooltiptype, option, level, value, base_value = tooltip_func()
			base2 = base_value
		end
		desc = ScpArgMsg(msg, 'base1', base1, 'base2', base2)
	else
		local func_str = string.format('get_tooltip_%s_arg%d', class_name, 3)
		local tooltip_func = _G[func_str]  -- get_tooltip_Ark_str_arg3 ?????????
		if tooltip_func ~= nil then
			local tooltiptype, option, level, value, base_value, msg = tooltip_func()
			if tooltiptype == 4 then -- 3?????? ????????? base??? 1?????? ??????
				local base1 = base_value
				desc = ScpArgMsg(msg, 'base1', base1)
			else
				desc = GET_ITEM_TOOLTIP_DESC(invitem)
			end
		else
			desc = GET_ITEM_TOOLTIP_DESC(invitem)
		end
	end

	local gBox = GET_CHILD(tooltipframe, mainframename,'ui::CGroupBox')
	gBox:RemoveChild('tooltip_equip_desc')

	if desc == '' then -- ?????? ?????? ????????? ????????? ??????. ????????? ????????? ??? ????????? ?????????
		return yPos
	end

    local value = IS_TOGGLE_EQUIP_ITEM_TOOLTIP_DESC()
    if value == 1 then
        return yPos
    end
	
	local tooltip_equip_property_CSet = gBox:CreateOrGetControlSet('tooltip_equip_desc', 'tooltip_equip_desc', 0, yPos)
	local property_gbox = GET_CHILD(tooltip_equip_property_CSet,'property_gbox','ui::CGroupBox')
		
	local inner_yPos = 0
	inner_yPos = ADD_ITEM_PROPERTY_TEXT(property_gbox, desc, 0, inner_yPos)

	local BOTTOM_MARGIN = tooltipframe:GetUserConfig('BOTTOM_MARGIN'); -- ??? ????????? ??????
	tooltip_equip_property_CSet:Resize(tooltip_equip_property_CSet:GetWidth(),tooltip_equip_property_CSet:GetHeight() + property_gbox:GetHeight() + property_gbox:GetY() + BOTTOM_MARGIN)

	gBox:Resize(gBox:GetWidth(),gBox:GetHeight() + tooltip_equip_property_CSet:GetHeight())
	
	return tooltip_equip_property_CSet:GetHeight() + tooltip_equip_property_CSet:GetY()
end

function DRAW_EQUIP_BELONGING(tooltipframe, invitem, yPos, mainframename, type)
	local text = '{@st41b}{#00eeee}' .. ClMsg('EquipCharacterBelonging')
	if type == 'char_belonging' then
		text = '{@st41b}{#00eeee}' .. ClMsg('EquipCharacterBelonging')
	elseif type == 'team_belonging' then
		text = '{@st41b}{#00eeee}' .. ClMsg('EquipTeamBelonging')
	end
	
	local gBox = GET_CHILD_RECURSIVELY(tooltipframe, mainframename)
	gBox:RemoveChild('tooltip_equip_belonging_richtxt');

	local CSet = gBox:CreateControlSet('tooltip_equip_belonging_richtxt', 'tooltip_equip_belonging_richtxt', 0, yPos);
	tolua.cast(CSet, "ui::CControlSet");
	
	local _text = GET_CHILD_RECURSIVELY(CSet, 'text');
	_text:SetText(text)	
	_text:SetTextAlign('right', 'center')
	return yPos + CSet:GetHeight();
end