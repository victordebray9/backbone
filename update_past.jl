function update_past!(m::Model, B, dict)

    JH = m.ext[:sets][:JH]
    JD = m.ext[:sets][:JD]
    ID = m.ext[:sets][:ID]
    S = m.ext[:sets][:S]
    J = m.ext[:sets][:J]
    g = value.(m_risk4.ext[:ADMM][:generation])
    dt = value.(m_risk4.ext[:variables][:dt])
    xien = m.ext[:ADMM][:xien]
    xcen = m.ext[:ADMM][:xcen]


    if B=="EO"
        for id in ID, jh in JH, jd in JD, s in S
            xien[dict[id],jh,jd,s]=g[dict[id],jh,jd,s]
        end
        for jh in JH, jd in JD, s in S
            xcen[jh,jd,s]=dt[jh,jd,s]
        end

    elseif B=="cCM"

        capcm = value.(m_risk4.ext[:ADMM][:capacity])
        dcm = value.(m_risk4.ext[:variables][:dcm])
        xicap = m.ext[:ADMM][:xicap]
        xccap = m.ext[:ADMM][:xccap]

        for id in ID, jh in JH, jd in JD, s in S
            xien[dict[id],jh,jd,s]=g[dict[id],jh,jd,s]
        end
        for jh in JH, jd in JD, s in S
            xcen[jh,jd,s]=dt[jh,jd,s]
        end

        for id in ID, s in S
            xicap[dict[id],s]=capcm[dict[id],s]
        end
        for s in S
            xccap[s]=dcm[s]
        end

    elseif B=="ORDC"

        r = value.(m_risk4.ext[:ADMM][:reserve])
        dr = value.(m_risk5.ext[:variables][:dr])
        xires = m.ext[:ADMM][:xires]
        xcres = m.ext[:ADMM][:xcres]

        for id in ID, jh in JH, jd in JD, s in S
            xien[dict[id],jh,jd,s]=g[dict[id],jh,jd,s]
        end
        for jh in JH, jd in JD, s in S
            xcen[jh,jd,s]=dt[jh,jd,s]
        end

        for id in ID, jh in JH, jd in JD, s in S
            xires[dict[id],jh,jd,s]=r[dict[id],jh,jd,s]
        end
        for j in J, jh in JH, jd in JD, s in S
            xcres[j,jh,jd,s]=dr[j,jh,jd,s]
        end
    end

end
