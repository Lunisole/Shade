-- The first core function of the class. Determine if a character (caster) is in the back of a target (target)
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

-- The main listening. This is the one which applies backstabbing.
Ext.Osiris.RegisterListener("UsingSpell", 5, "before", function (caster, spell, _, _, _)
    if HasPassive(caster,"Shade_Innate_Backstabbing_100001") == 1 then
        BackstabbingApply(caster,15)
    end
end)

-- The listener for Shadow Thirst.
Ext.Osiris.RegisterListener("KilledBy", 4, "after", function (killed, killer, _, _)
    -- Potential Additionnal Condition : and Osi.HasActiveStatus(killed,"BACKSTABBING_TECHNICAL_200001") == 1
    if (HasPassive(killer,"Shade_Shadow_Thirst_100004") == 1) then
        local maxhp = Ext.Entity.Get(killed).Health.MaxHp
        if (maxhp <= 20) then
            Osi.ApplyStatus(killer,"SHADOW_THIRST_3_200002",-1.0,1,killer)
        end
        if (20 < maxhp and maxhp <= 50) then
            Osi.ApplyStatus(killer,"SHADOW_THIRST_6_200003",-1.0,1,killer)
        end
        if (51 <= maxhp and maxhp <= 150) then
            Osi.ApplyStatus(killer,"SHADOW_THIRST_12_200004",-1.0,1,killer)
        end
        if (151 <= maxhp and maxhp <= 400) then
            Osi.ApplyStatus(killer,"SHADOW_THIRST_21_200005",-1.0,1,killer)
        end
        if (401 <= maxhp) then
            Osi.ApplyStatus(killer,"SHADOW_THIRST_33_200006",-1.0,1,killer)
        end
    end
end)
