-- lib_recipe.lua

local _boost_token_material_list = nil

local function make_premium_boost_token_material_list()
    if _boost_token_material_list ~= nil then
        return
    end

    _boost_token_material_list = {}
    -- StringArg 검사          Premium_boostToken 은 Premium_boostToken02 의 재료
    _boost_token_material_list['Premium_boostToken'] = 'Premium_boostToken02'
    _boost_token_material_list['Premium_boostToken02'] = 'Premium_boostToken03'
    _boost_token_material_list['Premium_boostToken03'] = 'Premium_boostToken06'    
end

make_premium_boost_token_material_list()

-- 재료를 넣어서 완성품을 가져온다. -- 재료가 아닌경우 nil
function GET_PREMIUM_BOOSTTOKEN_TARGET(mat)
    return _boost_token_material_list[mat]
end

function SCR_GET_RECIPE_ITEM(recipeMaterialCls)
     return GET_INVITEMS_BY_TYPE_WORTH_SORTED('IS_VALID_RECIPE_MATERIAL', recipeMaterialCls.ClassID);
end

function SCR_GET_RECIPE_ITEM_BOOSTTOKEN(recipeMaterialCls)
    return GET_INVITEMS_BY_TYPE_WORTH_SORTED('IS_VALID_RECIPE_MATERIAL_FOR_BOOSTTOKEN', recipeMaterialCls.ClassName);
end

-- compareProperty 재료 ClassName
function GET_INVITEMS_BY_TYPE_WORTH_SORTED(compareScript, compareProperty)
	local resultlist = {};
	local invItemList = session.GetInvItemList();
    local CompareFunction = _G[compareScript];
	FOR_EACH_INVENTORY(invItemList, function(invItemList, invItem, CompareFunction, compareProperty, resultlist)
		if invItem ~= nil then
			local itemobj = GetIES(invItem:GetObject());		
            if CompareFunction(compareProperty, itemobj) then                
				resultlist[#resultlist+1] = invItem;
			end
		end
	end, false, CompareFunction, compareProperty, resultlist);
	table.sort(resultlist, SORT_INVITEM_BY_WORTH);
	return resultlist
end

function IS_VALID_RECIPE_MATERIAL_FOR_BOOSTTOKEN(compareProperty, itemObj, pc)
    if compareProperty == nil or itemObj == nil then
        return false;
    end

    -- 기간 지난 것도 안돼
    if itemObj.ItemLifeTimeOver > 0 then
        if pc ~= nil then
            SendSysMsg(pc, 'CannotUseLifeTimeOverItem');
        end
        return false;
    end

    local string_arg = TryGetProp(itemObj, 'StringArg', 'None')
    if string_arg ~= 'None' then
        if compareProperty == string_arg then            
            return true
        end
    end

    -- 네이밍 규칙을 통한 검사
    local itemClassName = itemObj.ClassName;    
    if itemClassName ~= compareProperty and string.find(itemClassName, compareProperty..'_') == nil then            
        return false;
    end
    -- 1분짜리 경험의서는 예외처리 해달라고 하셨음
    if itemClassName == 'Premium_boostToken_test1min' and compareProperty == 'Premium_boostToken' then                
        return false;
    end
    
    return true;
end

function IS_VALID_RECIPE_MATERIAL(compareProperty, itemObj)
    if compareProperty == nil or itemObj == nil then
        return false;
    end
    local itemType = TryGetProp(itemObj, 'ClassID'); -- ies object인 경우
    if itemType == nil then
        itemType = itemObj.type; -- invItem인 경우
    end
    if compareProperty ~= itemType then
        return false;
    end

    return true;
end

function IS_VALID_RECIPE_MATERIAL_BY_NAME(compareProperty, itemObj)
    if compareProperty == nil or itemObj == nil then
        return false;
    end
    if compareProperty ~= itemObj.ClassName then
        return false;
    end

    return true;
end

function GET_MATERIAL_VALIDATION_SCRIPT(recipeCls)
    local validRecipeMaterial = 'IS_VALID_RECIPE_MATERIAL_BY_NAME';
    local getMaterialScript = TryGetProp(recipeCls, 'GetMaterialScript');
    if getMaterialScript == 'SCR_GET_RECIPE_ITEM_BOOSTTOKEN' then
        validRecipeMaterial = 'IS_VALID_RECIPE_MATERIAL_FOR_BOOSTTOKEN';
    end
    return validRecipeMaterial;
end

function GET_INV_ITEM_COUNT_BY_TYPE(pc, itemType, recipeCls)
    local getMaterialScript = TryGetProp(recipeCls, 'GetMaterialScript');
    if getMaterialScript == 'SCR_GET_RECIPE_ITEM_BOOSTTOKEN' then -- 기간제도 합해서 체크해줘야 하는 경우
        return GET_INV_ITEM_COUNT_BY_TYPE_FOR_BOOSTTOKEN(pc, itemType, recipeCls);
    end
    return GetInvItemCountByType(pc, itemType);
end

function GET_INV_ITEM_COUNT_BY_TYPE_FOR_BOOSTTOKEN(pc, itemType, recipeCls)
    local invItemCount = 0;
    local pcInvList = GetInvItemList(pc);
    local materialItemCls = GetClassByType('Item', itemType);
    if materialItemCls == nil then
        return invItemCount;
    end
    local itemClassName = materialItemCls.ClassName;

    if itemClassName == recipeCls.ClassName then -- 제작서인 경우
        return GetInvItemCountByType(pc, itemType);
    end

    -- 경험의서 재료
    local validRecipeMaterial = GET_MATERIAL_VALIDATION_SCRIPT(recipeCls);
    local IsValidRecipeMaterial = _G[validRecipeMaterial];
    if pcInvList == nil or #pcInvList < 1 then
        return invItemCount;
    end

    for i = 1 , #pcInvList do
		local invItem;
		if IsServerSection() == 1 then
			invItem = pcInvList[i];
		else
			invItem = session.GetInvItemByGuid(pcInvList[i]);
		end
        if invItem ~= nil and IsValidRecipeMaterial(itemClassName, invItem) then
            invItemCount = invItemCount + 1;
        end
    end
    return invItemCount;
end

function IS_ALL_MATERIAL_CHECKED(checkList, numCheckList)
    if #checkList < numCheckList then
        print("number of material limit isn't 5?? plz modify item_manufacture.lua!");
        return false;
    end

    for i = 1 , numCheckList do
        if checkList[i] == false then
            return false;
        end
    end
    return true;
end

function GET_RECIPE_MATERIAL_INFO(recipeCls, index,pc)
    local clsName = "Item_"..index.."_1";
	local itemName = recipeCls[clsName];
	if itemName == "None" then
		return nil;
    end
    
    local recipeItemCnt, recipeItemLv = GET_RECIPE_REQITEM_CNT(recipeCls, clsName,pc);
    local dragRecipeItem = GetClass('Item', itemName);

    if itemName == "misc_pvp_mine2" then
        local aObj = GetMyAccountObj()
        local propCount = TryGetProp(aObj, 'MISC_PVP_MINE2', '0')
        if propCount == 'None' then
            propCount = '0'
        end
        return recipeItemCnt, propCount,dragRecipeItem,nil,recipeItemLv,nil
    end

    if itemName == 'misc_silver_gacha_mileage' then
        local aObj = GetMyAccountObj()
        local propCount = TryGetProp(aObj, 'Mileage_SilverGacha', '0')
        if propCount == 'None' then
            propCount = '0'
        end
        return recipeItemCnt, propCount,dragRecipeItem,nil,recipeItemLv,nil
    end
    
    if itemName == 'dummy_GabijaCertificate' then -- 여신의 증표(가비야)
        local aObj = GetMyAccountObj()
        local propCount = TryGetProp(aObj, 'GabijaCertificate', '0')
        if propCount == 'None' then
            propCount = '0'
        end
        return recipeItemCnt, propCount, dragRecipeItem, nil,recipeItemLv,nil
    end

    if itemName == 'dummy_TeamBattleCoin' then -- 팀배코인
        local aObj = GetMyAccountObj()
        local propCount = TryGetProp(aObj, 'TeamBattleCoin', '0')
        if propCount == 'None' then
            propCount = '0'
        end
        return recipeItemCnt, propCount, dragRecipeItem, nil,recipeItemLv,nil
    end

	local invItem = nil;
	local invItemlist = nil;
    local ignoreType = false;
    local getMaterialScript = TryGetProp(recipeCls, 'GetMaterialScript');
    -- itemtradeshop.xml처럼 GetMaterialScript 칼럼이 추가될 필요 없는 레시피 클래스를 위해 디폴트 값 입력
    if getMaterialScript == nil then
        getMaterialScript = 'SCR_GET_RECIPE_ITEM';
    end
    local GetMaterialItemListFunc = _G[getMaterialScript];

	if dragRecipeItem.MaxStack > 1 then
		invItem = session.GetInvItemByType(dragRecipeItem.ClassID);
	else
		invItemlist = GetMaterialItemListFunc(dragRecipeItem); -- 기간제는 스택형 ㄴㄴ라서 비스택형만 대체
        ignoreType = true; -- 개수 셀 때 type만 검사하지 않도록 함
	end

	local invItemCnt = GET_PC_ITEM_COUNT_BY_LEVEL(dragRecipeItem.ClassID, recipeItemLv);
    if ignoreType then
        invItemCnt = #invItemlist;
    end
    
	return recipeItemCnt, invItemCnt, dragRecipeItem, invItem, recipeItemLv, invItemlist;

end