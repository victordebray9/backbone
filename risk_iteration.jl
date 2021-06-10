

function risk_iteration!(m::Model, B, id, dict)


    JH = m.ext[:sets][:JH]
    JD = m.ext[:sets][:JD]
    ID = m.ext[:sets][:ID]
    J = m.ext[:sets][:J]
    S = m.ext[:sets][:S]
    g=m_risk4.ext[:ADMM][:generation]

    if B == "EO"

        build_greenfield_IY_GEP_model_risk!(m, B, id, dict) 
        optimize!(m)

        if id != "Load"
            g_local = value.(m.ext[:variables][:g])
            #println("generation2: ")
            #println(g_local[id,:,:,1])

            for jh in JH, jd in JD, s in S
                g[dict[id],jh,jd,s]=g_local[id,jh,jd,s]
            end
            print()
        end
    elseif B == "cCM"
        build_greenfield_IY_GEP_model_risk!(m, B, id, dict)
        optimize!(m)
        g_local = value.(m.ext[:variables][:g])

        g=value.(m_risk4.ext[:variables][:g])

        g = value.(m_risk4.ext[:variables][:g])
        for jh in JH, jd in JD, s in S
            g[id,jh,jd,s]=g_local[id,jh,jd,s]
        end
    elseif B == "ORDC"
        build_greenfield_IY_GEP_model_risk!(m, B, id, dict)
        optimize!(m)
        g_local = value.(m.ext[:variables][:g])

        g=value.(m_risk4.ext[:variables][:g])

        g = value.(m_risk4.ext[:variables][:g])
        for jh in JH, jd in JD, s in S
            g[id,jh,jd,s]=g_local[id,jh,jd,s]
        end
    end

end
