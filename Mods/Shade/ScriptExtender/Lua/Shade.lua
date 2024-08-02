--[[
--The sad shade of my former function :( :( :( :( :(
function Lu_Shde_BackstabbingCheck(target, caster, distance)
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

Ext.Vars.RegisterUserVariable("Lu_Shde_SpringHeeledAssStartPos", {
    Server = true
})

Ext.Vars.RegisterUserVariable("Lu_Shde_DeathMark", {
    Server = true
})

Ext.Vars.RegisterUserVariable("Lu_UmBld_ShdwPosition", {
    Server = true
})

-- Determines the min/max angle required to backstab, depending on the spell.
function Lu_Shde_BackstabbingAngle(shade,spell)
    -- if the spell is Feint Stabbing
    if (spell == "Shade_Feint_Stabbing_E00001" or spell == "Shade_Melee_MH_Feint_Stabbing_700002" or spell == "Shade_Melee_OH_Feint_Stabbing_700003" or spell == "Shade_Ranged_MH_Feint_Stabbing_800001" or spell == "Shade_Ranged_OH_Feint_Stabbing_800002") then 
        anglemin = 0
        anglemax = 2*math.pi
    -- if the shade has the Supreme Backstab passive
    elseif HasPassive(shade,"UmbralBlade_Supreme_Backstab_110003") == 1  then
        anglemin = (2*math.pi)/3
        anglemax = (4*math.pi)/3
    -- normal scenario
    else
        anglemin = (3*math.pi)/4
        anglemax = (5*math.pi)/4
    end
    return anglemin, anglemax
end 

-- Determines the orientation vector (normalized) of a character
function Lu_Shde_CharSteeringVec(target)
    print("Target is",target)
    local targetzsteering = math.cos(Ext.Entity.Get(target).Steering.field_C)
    local targetxsteering = math.sin(Ext.Entity.Get(target).Steering.field_C)
    orient = {targetxsteering,0,targetzsteering}
    print("OrientVec")
    _D(orient)
    return orient
end 

-- Determines if a character is in the back of another one or not.
function Lu_Shde_BackstabbingCheck(target, caster, distance)
    Lu_Shde_CharSteeringVec(target)
    local normalized = Ext.Math.Normalize(distance)
    local DP = Ext.Math.Dot(orient,normalized)
    local result = Ext.Math.Acos(DP)
    if (anglemin<=result and result<=anglemax) then
        isbackstabbing = 1
        --print("Backstabbing")
    else
        isbackstabbing = 0
        --print("Not Backstabbing")
    end
end

-- Determines the character (shade) to target vector and nomalize it. Then calls 2 others function and apply the Backstabbing status if requirements are met.
function Lu_Shde_BackstabbingInit(shade, target, spell, backstabbingmaxdistance)
    backstabbingmaxdistance = backstabbingmaxdistance or 100
    local selfx = Ext.Entity.Get(shade).Bound.Bound.Translate[1]
    local selfz = Ext.Entity.Get(shade).Bound.Bound.Translate[3]
    local targetx = Ext.Entity.Get(target).Bound.Bound.Translate[1]
    local targetz = Ext.Entity.Get(target).Bound.Bound.Translate[3]
    local distance = {targetx-selfx,0,targetz-selfz}
    if Ext.Math.Length(distance) <= backstabbingmaxdistance then
        Osi.RemoveStatus(target,"BACKSTABBING_TECHNICAL_200001")
        Lu_Shde_BackstabbingAngle(shade,spell)
        Lu_Shde_BackstabbingCheck(target,shade, distance)
        if isbackstabbing == 1 then
            Osi.ApplyStatus(target,"BACKSTABBING_TECHNICAL_200001",5.0,1)
        end
    end
end

-- Iterates every entity in a combat with a character (shade) and calls Lu_Shde_BackstabbingInit to check if the character (shade) can backstab the entity.
function Lu_Shde_BackstabbingApply(shade, spell, backstabbingmaxdistance)
    for k, v in pairs(Osi.DB_Is_InCombat:Get(nil, Osi.CombatGetGuidFor(Ext.Entity.Get(shade).Uuid.EntityUuid))) do
        Lu_Shde_BackstabbingInit(shade, v[1], spell, backstabbingmaxdistance)  
    end
end

function Lu_Shde_Cruelty(shade)
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
end

function Lu_Shde_SpringHeeledAssApply(shade)
    local posatturnstartx = Ext.Entity.Get(shade).Vars.Lu_Shde_SpringHeeledAssStartPos[1]
    local posatturnstarty = Ext.Entity.Get(shade).Vars.Lu_Shde_SpringHeeledAssStartPos[2]
    local posatturnstartz = Ext.Entity.Get(shade).Vars.Lu_Shde_SpringHeeledAssStartPos[3]
    for k, v in pairs(Osi.DB_Is_InCombat:Get(nil, Osi.CombatGetGuidFor(Ext.Entity.Get(shade).Uuid.EntityUuid))) do
        local targetpostx,targetposty,targetpostz = Osi.GetPosition(v[1])
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
        else
            Osi.RemoveStatus(v[1],"SRING_HEELED_ASSASSIN_TECHNICAL_1_200029")
            Osi.RemoveStatus(v[1],"SRING_HEELED_ASSASSIN_TECHNICAL_2_200030")
            Osi.RemoveStatus(v[1],"SRING_HEELED_ASSASSIN_TECHNICAL_3_200031")
            Osi.RemoveStatus(v[1],"SRING_HEELED_ASSASSIN_TECHNICAL_4_200032")
            Osi.RemoveStatus(v[1],"SRING_HEELED_ASSASSIN_TECHNICAL_5_200033")
        end
    end
end

function Lu_Shde_TeleportTo()
    Osi.TeleportToPosition(shdtotp, positionrectified[1], positionrectified[2], positionrectified[3], "", 0, 0, 0)
end

function Lu_Shde_DeathMarkInit(marked4death, shade)
    Ext.Entity.Get(marked4death).Vars.Lu_Shde_DeathMark = {0,Ext.Entity.Get(shade).Uuid.EntityUuid}
end

function Lu_Shde_DeathMarkInrmnt(marked4death, shade, DamageAmount)
    if Ext.Entity.Get(shade).Uuid.EntityUuid == Ext.Entity.Get(marked4death).Vars.Lu_Shde_DeathMark[2] then
        local temp = Ext.Entity.Get(marked4death).Vars.Lu_Shde_DeathMark
        if Osi.HasActiveStatus(marked4death,"BACKSTABBING_TECHNICAL_200001") == 1 then
            temp[1] = (Ext.Entity.Get(marked4death).Vars.Lu_Shde_DeathMark[1]+math.floor(3/2*DamageAmount))
        else 
            temp[1] = (Ext.Entity.Get(marked4death).Vars.Lu_Shde_DeathMark[1]+DamageAmount)
        end
        Ext.Entity.Get(marked4death).Vars.Lu_Shde_DeathMark = temp
    end
end

function Lu_Shde_DeathMarkExpi(marked4death)
    local Damage = math.floor(4/3*Ext.Entity.Get(marked4death).Vars.Lu_Shde_DeathMark[1])
    ApplyDamage(marked4death,Damage,"Piercing",Ext.Entity.Get(marked4death).Vars.Lu_Shde_DeathMark[2])
end

function Lu_UmBld_ShdwInit(shadow, shade)
    Osi.Transform(shadow,shade,"585ee1db-2c04-4e6f-874a-2b45fd554052")
    local x,y,z = Osi.GetPosition(shadow)
    Ext.Entity.Get(shade).Vars.Lu_UmBld_ShdwPosition = {x,y,z,shadow}
end

function Lu_UmBld_ShdwSwap(shade)
    shdtotp = shade
    positionrectified = {Ext.Entity.Get(shade).Vars.Lu_UmBld_ShdwPosition[1],Ext.Entity.Get(shade).Vars.Lu_UmBld_ShdwPosition[2],Ext.Entity.Get(shade).Vars.Lu_UmBld_ShdwPosition[3]}
    Osi.Die(Ext.Entity.Get(shade).Vars.Lu_UmBld_ShdwPosition[4])
    Ext.Timer.WaitFor(1150, Lu_Shde_TeleportTo)
    Ext.Timer.WaitFor(1300, function()
        Osi.ApplyStatus(shade,"SHADOW_RECALL_210009",1.0,1)
        Osi.RemoveStatus(shade,"LINGERING_UMBRA_OWNER_210003")
    end)
end

function Lu_UmBld_LethalDarkness(shade,status,hitnumber)
    --_P("Correctly send to function:",status)
    local hitnumber = hitnumber or 7
    for hitindex = 1, hitnumber do
        for k, v in pairs(Osi.DB_Is_InCombat:Get(nil, Osi.CombatGetGuidFor(Ext.Entity.Get(shade).Uuid.EntityUuid))) do
            local obscurity = Osi.GetObscuredState(v[1])
            local IsAlly = Osi.IsAlly(shade,v[1])
            if (obscurity ~= "Clear" and IsAlly ~= 1 and hitnumber >0) then
                Lu_Shde_BackstabbingInit(shade,v[1],"")
                Lu_Shde_Cruelty(shade)
                if status == "LETHAL_DARKNESS_DAMAGE_MELEE_210005" then
                    Osi.CreateExplosion(v[1],"UmbralBlade_Lethal_Darkness_Damage_Melee_810001",-1,shade)
                    --_P("Succesfully created explosion : Melee Lethal Darkness")
                else
                    Osi.CreateExplosion(v[1],"UmbralBlade_Lethal_Darkness_Damage_Ranged_810002",-1,shade)
                    --_P("Succesfully created explosion : Ranged Lethal Darkness")
                end
                hitnumber = hitnumber - 1
            end
        end
    end
end

-- The main listening. This is the one which applies backstabbing.
Ext.Osiris.RegisterListener("StartedPreviewingSpell", 4, "before", function (caster, spell, _, _, _)
    if HasPassive(caster,"Shade_Innate_Backstabbing_100001") == 1 then
        Lu_Shde_BackstabbingApply(caster,spell,15)
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
    Lu_Shde_Cruelty(shade)
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

--The listener to get the position on turn start of Spring-Heeled Assassin
Ext.Osiris.RegisterListener("TurnStarted", 1, "before", function(shade)
    if (HasPassive(shade,"Shade_Spring_Heeled_Assassin_100021") == 1) then
        local posatstartx,posatstarty,posatstartz = Osi.GetPosition(shade)
        Ext.Entity.Get(shade).Vars.Lu_Shde_SpringHeeledAssStartPos = {posatstartx,posatstarty,posatstartz}
    end
end)

--The listener to apply the status of Spring-Heeled Assassin
Ext.Osiris.RegisterListener("StartedPreviewingSpell", 4, "before", function(shade, _, _, _, _)
    if HasPassive(shade,"Shade_Spring_Heeled_Assassin_100021") == 1 then
        Lu_Shde_SpringHeeledAssApply(shade)
    end
end)

--Maybe useless, I'm not sure
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(shade, status, _, _)
	if status == "SMOKE_COVER_EFFECT_A00001" then
        Ext.Timer.WaitFor(1500, function(shade)
            Osi.ApplyStatus(shade,"SMOKE_COVER_FOGCLOUD_200040",-1.0,1,shade)
        end)
    end
end)

Ext.Osiris.RegisterListener("AttackedBy",7,"after", function(shade,attacker,_,_,_,_,_)
    if (HasPassive(shade,"Shade_Gap_Close_F00009") == 1 and IsCharacter(attacker) == 1) then
        Lu_Shde_CharSteeringVec(attacker)
        local posx,posy,posz = Osi.GetPosition(attacker)
        positionrectified = {posx+orient[1],posy+orient[2],posz+orient[3]}
    end
end)

Ext.Osiris.RegisterListener("UsingSpell", 5, "after", function (shade,spell,_,_,_)
    if spell == "Shade_Gap_Close_C00004" then
        shdtotp = shade
        Ext.Timer.WaitFor(1300, Lu_Shde_TeleportTo)
    end
end)

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(marked4death,status,shade, _)
    if status == "MARK_OF_DEATH_200042" then
        Lu_Shde_DeathMarkInit(marked4death, shade)
    end
end)

Ext.Osiris.RegisterListener("AttackedBy",7,"after", function(marked4death,shade,_,_,DamageAmount,_,_)
    if Osi.HasActiveStatus(marked4death,"MARK_OF_DEATH_200042") == 1 then
        Lu_Shde_DeathMarkInrmnt(marked4death,shade,DamageAmount)
    end
end)

Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(marked4death,status,_,_)
    if status == "MARK_OF_DEATH_200042" then
        Lu_Shde_DeathMarkExpi(marked4death)
    end
end)

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(shadow,status,shade,_)
    if status == "LINGERING_UMBRA_EFFECT_210001" then
        Lu_UmBld_ShdwInit(shadow,shade)
    end
end)

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(shade,status,_,_)
    if status == "LINGERING_UMBRA_TECHNICAL_210008" then
        Ext.Timer.WaitFor(500, function()
            Osi.RemoveStatus(shade,"LINGERING_UMBRA_TECHNICAL_210008")
        end)
    end
end)

Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(shadow,status,_,_)
    if status == "LINGERING_UMBRA_TIMER_210002" then
        Osi.Die(shadow)
    end
end)

Ext.Osiris.RegisterListener("UsingSpell", 5, "after", function (shade,spell,_,_,_)
    if spell == "UmbralBlade_Shadow_Recall_610001" then
        Lu_UmBld_ShdwSwap(shade)
    end
end)

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(shade,status,_,_)
    if (status == "LETHAL_DARKNESS_DAMAGE_MELEE_210005" or status == "LETHAL_DARKNESS_DAMAGE_RANGED_210007") then
        --_P(status)
        Lu_UmBld_LethalDarkness(shade,status,7)
    end
end)