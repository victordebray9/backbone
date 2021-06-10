function update_past!(m::Model, B, dict)

    JH = m.ext[:sets][:JH]
    JD = m.ext[:sets][:JD]
    S = m.ext[:sets][:S]
    J = m.ext[:sets][:J]
    g=value.(m_risk4.ext[:ADMM][:generation])
    dt = value.(m_risk4.ext[:variables][:dt])
    xien=m.ext[:ADMM][:xien]
    xcen=m.ext[:ADMM][:xcen]




    if B=="EO"
        for id in ID, jh in JH, jd in JD, s in S
            xien[dict[id],jh,jd,s]=g[dict[id],jh,jd,s]
        end
        for jh in JH, jd in JD, s in S
            xcen[jh,jd,s]=dt[jh,jd,s]
        end

    elseif B=="cCM"
        for id in ID, jh in JH, jd in JD, s in S
            xien[dict[id],jh,jd,s]=g[dict[id],jh,jd,s]
        end
        for jh in JH, jd in JD, s in S
            xcen[jh,jd,s]=dt[jh,jd,s]
        end
    elseif B=="ORDC"
        for id in ID, jh in JH, jd in JD, s in S
            xien[dict[id],jh,jd,s]=g[dict[id],jh,jd,s]
        end
        for jh in JH, jd in JD, s in S
            xcen[jh,jd,s]=dt[jh,jd,s]
        end
    end

end
