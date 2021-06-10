
function update_parameters!(m::Model, B, dict)

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
        for id in ID, jh in JH, jd in JD, s in S
            xien[dict[id],jh,jd,s]=g[dict[id],jh,jd,s]
        end
        for jh in JH, jd in JD, s in S
            xcen[jh,jd,s]=dt[jh,jd,s]
        end
    elseif B=="cCM"

        for jh in JH, jd in JD, s in S
            pen[jh,jd,s]=pen[jh,jd,s]-rho*(sum(g[id,jh,jd,s] for id in ID)- dt[jh,jd,s])
            if pen[jh,jd,s]<0
                pen[jh,jd,s]=0
            end
        end
        for id in ID, jh in JH, jd in JD, s in S
            xien[dict[id],jh,jd,s]=g[id,jh,jd,s]
        end
        for jh in JH, jd in JD, s in S
            xcen[jh,jd,s]=dt[jh,jd,s]
        end
    elseif B=="ORDC"

        for jh in JH, jd in JD, s in S
            pen[jh,jd,s]=pen[jh,jd,s]-rho*(sum(g[id,jh,jd,s] for id in ID)- dt[jh,jd,s])
            if pen[jh,jd,s]<0
                pen[jh,jd,s]=0
            end
        end
        for id in ID, jh in JH, jd in JD, s in S
            xien[dict[id],jh,jd,s]=g[id,jh,jd,s]
        end
        for jh in JH, jd in JD, s in S
            xcen[jh,jd,s]=dt[jh,jd,s]
        end
    end


end
