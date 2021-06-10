function update_residuals!(B,dict)

    JH = m.ext[:sets][:JH]
    JD = m.ext[:sets][:JD]
    ID = m.ext[:sets][:ID]
    J = m.ext[:sets][:J]
    S = m.ext[:sets][:S]
    SD = m.ext[:timeseries][:SD]
    rho=m.ext[:parameters][:rho]
    tau=m.ext[:parameters][:tau]

    primal_residual_e=m.ext[:ADMM][:primal_residual_e]
    dual_residual_ei=m.ext[:ADMM][:dual_residual_ei]
    dual_residual_ec=m.ext[:ADMM][:dual_residual_ec]

    g=value.(m_risk4.ext[:ADMM][:generation])
    dt = value.(m_risk4.ext[:variables][:dt])
    xien=value.(m_risk4.ext[:ADMM][:xien])
    xcen=value.(m_risk4.ext[:ADMM][:xcen])#values are taken from model 4, this is juste random


    if B=="EO"

        for jh in JH, jd in JD, s in S
            primal_residual_e[jh,jd,s]= sum(g[dict[id],jh,jd,s] for id in ID)-dt[jh,jd,s]
        end

        for id in ID, jh in JH, jd in JD, s in S
            dual_residual_ei[dict[id],jh,jd,s]=rho*((g[dict[id],jh,jd,s]-1/(1+length(ID))*SD[jh,jd,s])-(xien[dict[id],jh,jd,s]-1/(1+length(ID))*SD[jh,jd,s]))
        end

        for jh in JH, jd in JD, s in S
            dual_residual_ec[jh,jd,s]=rho*((dt[jh,jd,s]-1/(1+length(ID))*SD[jh,jd,s])-(xcen[jh,jd,s]-1/(1+length(ID))*SD[jh,jd,s]))
        end

        Psi=(
            sqrt(sum((primal_residual_e[jh,jd,s])^2 for jh in JH, jd in JD, s in S)
        ))

        Xsi=(
            sqrt(sum((dual_residual_ei[dict[id],jh,jd,s])^2 for id in ID, jh in JH, jd in JD, s in S)) + sqrt(sum((dual_residual_ec[jh,jd,s])^2 for jh in JH, jd in JD, s in S))
        )

        return(Psi,Xsi)
    elseif B=="cCM"

        primal_residual_c=m.ext[:ADMM][:primal_residual_c]
        dual_residual_ci=m.ext[:ADMM][:dual_residual_ci]
        dual_residual_cc=m.ext[:ADMM][:dual_residual_cc]
        capcm = value.(m_risk4.ext[:ADMM][:capacity])
        dcm = value.(m_risk4.ext[:variables][:dcm])
        xicap = m.ext[:ADMM][:xicap]
        xccap = m.ext[:ADMM][:xccap]

        for jh in JH, jd in JD, s in S
            primal_residual_e[jh,jd,s]= sum(g[dict[id],jh,jd,s] for id in ID)-dt[jh,jd,s]
        end

        for s in S
            primal_residual_c[s]= sum(capcm[dict[id],s] for id in ID)-dcm[s]
        end

        for id in ID, jh in JH, jd in JD, s in S
            dual_residual_ei[dict[id],jh,jd,s]=rho*((g[dict[id],jh,jd,s]-1/(1+length(ID))*SD[jh,jd,s])-(xien[dict[id],jh,jd,s]-1/(1+length(ID))*SD[jh,jd,s]))
        end

        for jh in JH, jd in JD, s in S
            dual_residual_ec[jh,jd,s]=rho*((dt[jh,jd,s]-1/(1+length(ID))*SD[jh,jd,s])-(xcen[jh,jd,s]-1/(1+length(ID))*SD[jh,jd,s]))
        end

        for id in ID, s in S
            dual_residual_ci[dict[id],s]=rho*((capcm[dict[id],s]-1/(1+length(ID))* sum(capcm[dict[id],s] for id in ID)-dcm[s])-(xicap[dict[id],s]-1/(1+length(ID))*sum(capcm[dict[id],s] for id in ID)-dcm[s]))
        end

        for s in S
            dual_residual_cc[s]=rho*((dcm[s]-1/(1+length(ID))*sum(capcm[dict[id],s] for id in ID)-dcm[s])-(xccap[s]-1/(1+length(ID))*sum(capcm[dict[id],s] for id in ID)-dcm[s]))
        end

        Psi=(
            sqrt(sum((primal_residual_e[jh,jd,s])^2 for jh in JH, jd in JD, s in S)) + sqrt(sum((primal_residual_c[s])^2 for s in S))
            )

        Xsi=(
            sqrt(sum((dual_residual_ei[dict[id],jh,jd,s])^2 for id in ID, jh in JH, jd in JD, s in S)) + sqrt(sum((dual_residual_ec[jh,jd,s])^2 for jh in JH, jd in JD, s in S))
            + sqrt(sum((dual_residual_ci[dict[id],s])^2 for id in ID, s in S)) + sqrt(sum((dual_residual_ec[s])^2 for s in S))
        )

        return(Psi,Xsi)

    elseif B=="ORDC"

        primal_residual_o=m.ext[:ADMM][:primal_residual_o]
        dual_residual_oi=m.ext[:ADMM][:dual_residual_oi]
        dual_residual_oc=m.ext[:ADMM][:dual_residual_oc]
        r = value.(m_risk4.ext[:ADMM][:reserve])
        dr = value.(m_risk5.ext[:variables][:dr])
        xires = m.ext[:ADMM][:xires]
        xcres = m.ext[:ADMM][:xcres]

        for jh in JH, jd in JD, s in S
            primal_residual_e[jh,jd,s]= sum(g[dict[id],jh,jd,s] for id in ID)-dt[jh,jd,s]
        end

        for jh in JH, jd in JD, s in S
            primal_residual_o[jh,jd,s]= sum(r[dict[id],jh,jd,s] for id in ID)-sum(dr[j,jh,jd,s] for j in J)
        end

        for id in ID, jh in JH, jd in JD, s in S
            dual_residual_ei[dict[id],jh,jd,s]=rho*((g[dict[id],jh,jd,s]-1/(1+length(ID))*SD[jh,jd,s])-(xien[dict[id],jh,jd,s]-1/(1+length(ID))*SD[jh,jd,s]))
        end

        for jh in JH, jd in JD, s in S
            dual_residual_ec[jh,jd,s]=rho*((dt[jh,jd,s]-1/(1+length(ID))*SD[jh,jd,s])-(xcen[jh,jd,s]-1/(1+length(ID))*SD[jh,jd,s]))
        end

        for id in ID, jh in JH, jd in JD, s in S
            dual_residual_oi[dict[id],jh,jd,s]=rho*((r[dict[id],jh,jd,s]-1/(1+length(ID))*sum(r[dict[id],jh,jd,s] for id in ID)-sum(dr[j,jh,jd,s] for j in J))-(xires[dict[id],jh,jd,s] - 1/(1+length(ID))*sum(r[dict[id],jh,jd,s] for id in ID)-sum(dr[j,jh,jd,s] for j in J)))
        end

        for j in J, jh in JH, jd in JD, s in S
            dual_residual_oc[j,jh,jd,s]=rho*((dr[j,jh,jd,s]-1/(1+length(ID))*sum(r[dict[id],jh,jd,s] for id in ID)-sum(dr[j,jh,jd,s] for j in J))-(xcres[j,jh,jd,s]-1/(1+length(ID))*sum(r[dict[id],jh,jd,s] for id in ID)-sum(dr[j,jh,jd,s] for j in J)))
        end
        Psi=(
            sqrt(sum((primal_residual_e[jh,jd,s])^2 for jh in JH, jd in JD, s in S)) + sqrt(sum((primal_residual_o[jh,jd,s])^2 for jh in JH, jd in JD, s in S))
        )

        Xsi=(
            sqrt(sum((dual_residual_ei[dict[id],jh,jd,s])^2 for id in ID, jh in JH, jd in JD, s in S)) + sqrt(sum((dual_residual_ec[jh,jd,s])^2 for jh in JH, jd in JD, s in S))
            + sqrt(sum((dual_residual_oi[dict[id],jh,jd,s])^2 for id in ID, jh in JH, jd in JD, s in S)) + sqrt(sum((dual_residual_oc[j,jh,jd,s])^2 for j in J, jh in JH, jd in JD, s in S))

        )

        return(Psi,Xsi)

    end

end
