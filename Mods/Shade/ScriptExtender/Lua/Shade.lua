function BackstabbingCheck(target, caster, distance) 
    local quatx = Ext.Entity.Get(target).Bound.Bound.RotationQuat[2]
    local quatz = Ext.Entity.Get(target).Bound.Bound.RotationQuat[4]
    local quatmatrix = {1-2*0*0-2*quatz*quatz,2*quatx*0-2*0*quatz,2*quatx*quatz+2*0*0,2*quatx*0+2*0*quatz,1-2*quatx*quatx-2*quatz*quatz,2*0*quatz-2*0*quatx,2*quatx*quatz-2*0*0,2*0*quatz+2*0*quatx,1-2*quatx*quatx-2*0*0}
    local orient = Ext.Math.Mul({0,0,1},quatmatrix)
    local normalized = Ext.Math.Normalize(distance)
    local DP = Ext.Math.Dot(orient,normalized)
    local result = Ext.Math.Acos(DP)
    if (((3*math.pi)/4)<result and result<((5*math.pi)/4)) then
        print("Backstabbing")
        isbackstabbing = 1
    else
        print("Not Backstabbing")
        isbackstabbing = 0
    end
end

function BackstabbingApply(character, backstabbingmaxdistance)
    for k, v in pairs(Osi.DB_Is_InCombat:Get(nil, Osi.CombatGetGuidFor(Ext.Entity.Get(character).Uuid.EntityUuid))) do
        local selfx = Ext.Entity.Get(character).Bound.Bound.Translate[1]
        local selfz = Ext.Entity.Get(character).Bound.Bound.Translate[3]
        local targetx = Ext.Entity.Get(v[1]).Bound.Bound.Translate[1]
        local targetz = Ext.Entity.Get(v[1]).Bound.Bound.Translate[3]
        local distance = {targetx-selfx,0,targetz-selfz}
        if Ext.Math.Length(distance) <= backstabbingmaxdistance then
            Osi.RemoveStatus(v[1],"BACKSTABBING_TECHNICAL")
            BackstabbingCheck(v[1],character, distance)
            if isbackstabbing == 1 then
                Osi.ApplyStatus(v[1],"BACKSTABBING_TECHNICAL",5.0,1)
            end
        end
    end
end

Ext.Osiris.RegisterListener("UsingSpell", 5, "before", function (caster, spell, _, _, _)
    if HasPassive(caster,"Shade_Main_Passive") == 1 then
	    BackstabbingApply(caster,15)
    end
end)

