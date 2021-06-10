
function update_price!(m::Model, B, dict)

    JH = m.ext[:sets][:JH]
    JD = m.ext[:sets][:JD]
    S = m.ext[:sets][:S]
    J = m.ext[:sets][:J]
    pen=m.ext[:ADMM][:pen]
    pcap=m.ext[:ADMM][:pcap]
    pres=m.ext[:ADMM][:pres]
    g=value.(m_risk4.ext[:ADMM][:generation])#values where saved in model m_risk4
    dt = value.(m_risk4.ext[:variables][:dt])


    if B=="EO"

        for jh in JH, jd in JD, s in S
            pen[jh,jd,s]=pen[jh,jd,s]-rho*(sum(g[dict[id],jh,jd,s] for id in ID)- dt[jh,jd,s])
            if pen[jh,jd,s]<0
                pen[jh,jd,s]=0
            end
        end

    elseif B=="cCM"

        capcm = value.(m_risk4.ext[:ADMM][:capacity])
        dcm = value.(m_risk4.ext[:variables][:dcm])

        for jh in JH, jd in JD, s in S
            pen[jh,jd,s]=pen[jh,jd,s]-rho*(sum(g[dict[id],jh,jd,s] for id in ID)- dt[jh,jd,s])
            if pen[jh,jd,s]<0
                pen[jh,jd,s]=0
            end
        end

        for s in S
            pcap[s]=pcap[s]-rho*(sum(capcm[dict[id],s] for id in ID)- dcm[s])
            if pcap[s]<0
                pcap[s]=0
            end
        end

    elseif B=="ORDC"

        r = value.(m_risk4.ext[:ADMM][:reserve])
        dr = value.(m_risk5.ext[:variables][:dr])

        for jh in JH, jd in JD, s in S
            pen[jh,jd,s]=pen[jh,jd,s]-rho*(sum(g[dict[id],jh,jd,s] for id in ID)- dt[jh,jd,s])
            if pen[jh,jd,s]<0
                pen[jh,jd,s]=0
            end
        end

        for jh in JH, jd in JD, s in S
            pres[jh,jd,s]=pres[jh,jd,s]-rho*(sum(r[dict[id],jh,jd,s] for id in ID)- sum(dr[j,jh,jd,s] for j in J))
            if pres[jh,jd,s]<0
                pres[jh,jd,s]=0
            end
        end

    end


end
