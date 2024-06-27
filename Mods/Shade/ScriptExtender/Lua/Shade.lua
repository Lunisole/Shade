--[[
--The sad shade of my former function :( :( :( :( :(
function BackstabbingCheck(target, caster, distance)
    local anglemin = ((3*math.pi)/4)
    local anglemax = ((5*math.pi)/4)
    local quatx = Ext.Entity.Get(target).Bound.Bound.RotationQuat[2]
    local quatz = Ext.Entity.Get(target).Bound.Bound.RotationQuat[4]
    local quatmatrix = {1-2*0*0-2*quatz*quatz,2*quatx*0-2*0*quatz,2*quatx*quatz+2*0*0,2*quatx*0+2*0*quatz,1-2*quatx*quatx-2*quatz*quatz,2*0*quatz-2*0*quatx,2*quatx*quatz-2*0*0,2*0*quatz+2*0*quatx,1-2*quatx*quatx-2*0*0}
    local orient = Ext.Math.Mul({0,0,1},quatmatrix)
    local normalized = Ext.Math.Normalize(distance)
    local DP = Ext.Math.Dot(orient,normalized)
    local result = Ext.Math.Acos(DP)
    if (anglemin<=result and result<=anglemax) then
        isbackstabbing = 1
        print("Backstabbing")
    else
        isbackstabbing = 0
        print("Not Backstabbing")
    end
end
]]

-- The absolute core function of the class. It's this function wich determines if a character is in the back of another one or not.
function BackstabbingCheck(target, caster, distance)
    -- If the character doesn't have backstab extended passive then use those anglemin/max
    local anglemin = (3*math.pi)/4
    local anglemax = (5*math.pi)/4
    targetzsteering = math.cos(Ext.Entity.Get(target).Steering.field_C)
    targetxsteering = math.sin(Ext.Entity.Get(target).Steering.field_C)
    orient = {targetxsteering,0,targetzsteering}
    local normalized = Ext.Math.Normalize(distance)
    local DP = Ext.Math.Dot(orient,normalized)
    local result = Ext.Math.Acos(DP)
    if (anglemin<=result and result<=anglemax) then
        isbackstabbing = 1
        print("Backstabbing")
    else
        isbackstabbing = 0
        print("Not Backstabbing")
    end
end

-- The second core function of the class. Iterates every entity in a combat with a character (shade) and calculates its distance to the character (shade).
function BackstabbingApply(shade, backstabbingmaxdistance)
    for k, v in pairs(Osi.DB_Is_InCombat:Get(nil, Osi.CombatGetGuidFor(Ext.Entity.Get(shade).Uuid.EntityUuid))) do
        local selfx = Ext.Entity.Get(shade).Bound.Bound.Translate[1]
        local selfz = Ext.Entity.Get(shade).Bound.Bound.Translate[3]
        local targetx = Ext.Entity.Get(v[1]).Bound.Bound.Translate[1]
        local targetz = Ext.Entity.Get(v[1]).Bound.Bound.Translate[3]
        local distance = {targetx-selfx,0,targetz-selfz}
        if Ext.Math.Length(distance) <= backstabbingmaxdistance then
            Osi.RemoveStatus(v[1],"BACKSTABBING_TECHNICAL_200001")
            BackstabbingCheck(v[1],shade, distance)
            if isbackstabbing == 1 then
                Osi.ApplyStatus(v[1],"BACKSTABBING_TECHNICAL_200001",5.0,1)
            end
        end
    end
end

function SpringHeeledAssassinApply(shade,posatturnstartx,posatturnstarty,posatturnstartz)
    for k, v in pairs(Osi.DB_Is_InCombat:Get(nil, Osi.CombatGetGuidFor(Ext.Entity.Get(shade).Uuid.EntityUuid))) do
        targetpostx,targetposty,targetpostz = Osi.GetPosition(v[1])
        local distance = Ext.Math.Length({targetpostx-posatturnstartx,targetposty-posatturnstarty,targetpostz-posatturnstartz})
        if (7 <= distance and distance <= 11) then
            Osi.ApplyStatus(v[1],"SRING_HEELED_ASSASSIN_TECHNICAL_1_200029",5.0,1)
        elseif (11 < distance and distance <= 16) then
            Osi.ApplyStatus(v[1],"SRING_HEELED_ASSASSIN_TECHNICAL_2_200030",5.0,1)
        elseif (16 < distance and distance <= 22) then
            Osi.ApplyStatus(v[1],"SRING_HEELED_ASSASSIN_TECHNICAL_3_200031",5.0,1)
        elseif (22 < distance and distance <= 29) then
            Osi.ApplyStatus(v[1],"SRING_HEELED_ASSASSIN_TECHNICAL_4_200032",5.0,1)
        elseif (29 < distance) then
            Osi.ApplyStatus(v[1],"SRING_HEELED_ASSASSIN_TECHNICAL_5_200033",5.0,1)
        end
    end
end



-- The main listening. This is the one which applies backstabbing.
Ext.Osiris.RegisterListener("StartedPreviewingSpell", 4, "before", function (caster, spell, _, _, _)
    if HasPassive(caster,"Shade_Innate_Backstabbing_100001") == 1 then
        BackstabbingApply(caster,15)
    end
end)

-- The listener for Shadow Thirst.
Ext.Osiris.RegisterListener("KilledBy", 4, "after", function (killed, killer, _, _)
    -- Potential Additionnal Condition : and Osi.HasActiveStatus(killed,"BACKSTABBING_TECHNICAL_200001") == 1
    if (HasPassive(killer,"Shade_Shadow_Thirst_100005") == 1) then
        local maxhp = Ext.Entity.Get(killed).Health.MaxHp
        if (maxhp <= 20) then
            Osi.ApplyStatus(killer,"SHADOW_THIRST_3_200002",-1.0,1,killer)
        elseif (20 < maxhp and maxhp <= 50) then
            Osi.ApplyStatus(killer,"SHADOW_THIRST_6_200003",-1.0,1,killer)
        elseif (50 < maxhp and maxhp <= 150) then
            Osi.ApplyStatus(killer,"SHADOW_THIRST_12_200004",-1.0,1,killer)
        elseif (150 < maxhp and maxhp <= 400) then
            Osi.ApplyStatus(killer,"SHADOW_THIRST_21_200005",-1.0,1,killer)
        elseif (400 < maxhp) then
            Osi.ApplyStatus(killer,"SHADOW_THIRST_33_200006",-1.0,1,killer)
        end
    end
end)

-- The listener for Cruelty
Ext.Osiris.RegisterListener("UsingSpell", 5, "before", function (shade, _, _, _, _)
    if (HasPassive(shade,"Shade_Cruelty_100007") == 1) then
        local random = math.random(20)
        if (random <= 5) then
            Osi.ApplyStatus(shade,"CRUELTY_MIN_200009",1.0,1,shade)
        end
        if (6 <= random and random <= 13) then
            Osi.ApplyStatus(shade,"CRUELTY_LOW_200010",1.0,1,shade)
        end
        if (14 <= random and random <= 17) then
            Osi.ApplyStatus(shade,"CRUELTY_HIGH_200011",1.0,1,shade)
        end
        if (18 <= random and random <= 20) then
            Osi.ApplyStatus(shade,"CRUELTY_MAX_200012",1.0,1,shade)
        end
    end
end)

-- The listener for Exquisite Hunter
Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "before", function (shade, target, _, _, _, _)
    if (HasPassive(shade,"Shade_Exquisite_Hunter_100010") == 1) then
        for k, v in pairs(Osi.DB_Is_InCombat:Get(nil, Osi.CombatGetGuidFor(Ext.Entity.Get(shade).Uuid.EntityUuid))) do
            if (v[1] ~= target) then 
                Osi.RemoveStatus(v[1],"EXQUISITE_HUNTER_STAGE_1_200017")
                Osi.RemoveStatus(v[1],"EXQUISITE_HUNTER_STAGE_2_200018")
                Osi.RemoveStatus(v[1],"EXQUISITE_HUNTER_STAGE_3_200019")
            end
            if (v[1] == target and Osi.HasActiveStatus(shade,"EXQUISITE_HUNTER_TECHNICAL_200020") ~= 1) then
                if (Osi.HasActiveStatus(target,"EXQUISITE_HUNTER_STAGE_2_200018") == 1) then
                    Osi.ApplyStatus(v[1],"EXQUISITE_HUNTER_STAGE_3_200019",-1.0,1,shade)
                end
                if (Osi.HasActiveStatus(target,"EXQUISITE_HUNTER_STAGE_1_200017") == 1) then
                    Osi.ApplyStatus(v[1],"EXQUISITE_HUNTER_STAGE_2_200018",-1.0,1,shade)
                end
                if (Osi.HasActiveStatus(target,"EXQUISITE_HUNTER_STAGE_2_200018") ~= 1 and Osi.HasActiveStatus(target,"EXQUISITE_HUNTER_STAGE_3_200019") ~= 1) then
                    Osi.ApplyStatus(v[1],"EXQUISITE_HUNTER_STAGE_1_200017",-1.0,1,shade)
                end
            end
        end
    end
end)

Ext.Osiris.RegisterListener("TurnStarted", 1, "before", function(shade)
    if (HasPassive(shade,"Shade_Spring_Heeled_Assassin_100021") == 1) then
        posatstartx,posatstarty,posatstartz = Osi.GetPosition(shade)
        _D(posatstartx,posatstarty,posatstartz)
    end
end)

Ext.Osiris.RegisterListener("StartedPreviewingSpell", 4, "before", function (shade, _, _, _, _)
    if HasPassive(shade,"Shade_Spring_Heeled_Assassin_100021") == 1 then
        SpringHeeledAssassinApply(shade,posatstartx,posatstarty,posatstartz)
    end
end)