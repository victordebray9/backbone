
function update_price!(m::Model, B, dict)

    JH = m.ext[:sets][:JH]
    JD = m.ext[:sets][:JD]
    S = m.ext[:sets][:S]
    J = m.ext[:sets][:J]
    pen=m.ext[:ADMM][:pen]
    xien=m.ext[:ADMM][:xien]
    xcen=m.ext[:ADMM][:xcen]
    pcap=m.ext[:ADMM][:pcap]
    pres=m.ext[:ADMM][:pres]
    g=value.(m_risk4.ext[:ADMM][:generation])
    dt = value.(m_risk4.ext[:variables][:dt])

    if B=="EO"

        for jh in JH, jd in JD, s in S
            pen[jh,jd,s]=pen[jh,jd,s]-rho*(sum(g[dict[id],jh,jd,s] for id in ID)- dt[jh,jd,s])
            if pen[jh,jd,s]<0
                pen[jh,jd,s]=0
            end
        end
    elseif B=="cCM"

        for jh in JH, jd in JD, s in S
            pen[jh,jd,s]=pen[jh,jd,s]-rho*(sum(g[id,jh,jd,s] for id in ID)- dt[jh,jd,s])
            if pen[jh,jd,s]<0
                pen[jh,jd,s]=0
            end
        end

    elseif B=="ORDC"

        for jh in JH, jd in JD, s in S
            pen[jh,jd,s]=pen[jh,jd,s]-rho*(sum(g[id,jh,jd,s] for id in ID)- dt[jh,jd,s])
            if pen[jh,jd,s]<0
                pen[jh,jd,s]=0
            end
        end
        
    end


end
