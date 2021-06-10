

function risk_iteration!(m::Model, B, id, dict)


    JH = m.ext[:sets][:JH]
    JD = m.ext[:sets][:JD]
    ID = m.ext[:sets][:ID]
    J = m.ext[:sets][:J]
    S = m.ext[:sets][:S]
    g=m_risk4.ext[:ADMM][:generation]#values will be stored in model m_risk4, this is totaly random
    r=m_risk4.ext[:ADMM][:reserve]

    if B == "EO"

        build_greenfield_IY_GEP_model_risk!(m, B, id, dict)
        optimize!(m)

        #compose a vector with generation of each technology
        if id != "Load"
            g_local = value.(m.ext[:variables][:g])

            for jh in JH, jd in JD, s in S
                g[dict[id],jh,jd,s]=g_local[id,jh,jd,s]
            end
        end
    elseif B == "cCM"


        build_greenfield_IY_GEP_model_risk!(m, B, id, dict)
        optimize!(m)

        capcm=m_risk4.ext[:ADMM][:capacity]

        #compose a vector with generation of each technology
        if id != "Load"
            g_local = value.(m.ext[:variables][:g])

            for jh in JH, jd in JD, s in S
                g[dict[id],jh,jd,s]=g_local[id,jh,jd,s]
            end

            capcm_local = value.(m.ext[:variables][:capcm])

            for jh in JH, jd in JD, s in S
                capcm[dict[id],s]=capcm_local[id,s]
            end

        end

    elseif B == "ORDC"

        build_greenfield_IY_GEP_model_risk!(m, B, id, dict)
        optimize!(m)

        r=m_risk4.ext[:ADMM][:reserve]

        #compose a vector with generation of each technology
        if id != "Load" && id != "Operator"
            g_local = value.(m.ext[:variables][:g])

            for jh in JH, jd in JD, s in S
                g[dict[id],jh,jd,s]=g_local[id,jh,jd,s]
            end
        end
    end

end
