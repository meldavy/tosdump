-- user_damage_meter.lua

local damage_meter_info_total = {}

function USER_DAMAGE_METER_ON_INIT(addon, frame)
    addon:RegisterMsg("USER_DAMAGE_CLEAR", "ON_USER_DAMAGE_CLEAR");
end

function USER_DAMAGE_METER_UI_OPEN(frame,msg,strArg,numArg)
    frame:ShowWindow(1)
end

function ON_USER_DAMAGE_CLEAR()
    damage_meter_info_total = {}
end

function ON_USER_DAMAGE_LIST(nameList, damageList)
    local totalDamage
    for i = 1, #nameList do
        if damage ~= '0' then
            damage_meter_info_total[nameList[i]] = damageList[i]
            totalDamage = SumForBigNumberInt64(damageList[i],totalDamage)
        end        
    end
    local frame = ui.GetFrame("user_damage_meter")
    if frame:IsVisible() == 0 then
        frame:ShowWindow(1)
    end
    AUTO_CAST(frame)
    local damageRankGaugeBox = GET_CHILD_RECURSIVELY(frame,"damageRankGaugeBox")
    UPDATE_USER_DAMAGE_METER_GUAGE(frame,damageRankGaugeBox, totalDamage)
end


function UPDATE_USER_DAMAGE_METER_GUAGE(frame, groupbox, totalDamage)
    local font = frame:GetUserConfig('GAUGE_FONT');
    
    index = 1
    for name, damage in pairs(damage_meter_info_total) do
        local ctrlSet = groupbox:GetControlSet('gauge_with_two_text', 'GAUGE_'..index)
        if ctrlSet == nil then
            ctrlSet = groupbox:CreateControlSet('gauge_with_two_text', 'GAUGE_'..index, 0, (index-1)*17);
            groupbox:Resize(groupbox:GetWidth(),groupbox:GetHeight()+17)
        end
        local point = MultForBigNumberInt64(damage,"100")
        point = DivForBigNumberInt64(point,totalDamage)
        local skin = 'gauge_damage_meter_0'..math.min(index,4)
        damage = font..STR_KILO_CHANGE(damage)..'K'
        DAMAGE_METER_GAUGE_SET(ctrlSet,font..name,point,font..damage,skin);
        index = index + 1
    end
end
