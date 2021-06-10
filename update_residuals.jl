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
            dual_residual_ei[dict[id],jh,jd,s]=rho*((g[dict[id],jh,jd,s]-1/(1+length(ID)*SD[jh,jd,s]))-(xien[dict[id],jh,jd,s]-1/(1+length(ID)*SD[jh,jd,s])))
        end

        for jh in JH, jd in JD, s in S
            dual_residual_ec[jh,jd,s]=rho*((dt[jh,jd,s]-1/(1+length(ID)*SD[jh,jd,s]))-(xcen[jh,jd,s]-1/(1+length(ID)*SD[jh,jd,s])))
        end

        Psi=(
            sqrt(sum((primal_residual_e[jh,jd,s])^2 for jh in JH, jd in JD, s in S)
        ))

        Xsi=(
            sqrt(sum((dual_residual_ei[dict[id],jh,jd,s])^2 for id in ID, jh in JH, jd in JD, s in S)) + sqrt(sum((dual_residual_ec[jh,jd,s])^2 for jh in JH, jd in JD, s in S))
        )

        return(Psi,Xsi)
    elseif B=="cCM"
        for jh in JH, jd in JD, s in S
            primal_residual_e[jh,jd,s]= sum(g[id,jh,jd,s] for id in ID)-dt[jh,jd,s]
        end

        for id in ID, jh in JH, jd in JD, s in S
            dual_residual_ei[dict[id],jh,jd,s]=rho*((g[id,jh,jd,s]-1/(1+length(ID)*SD[jh,jd,s]))-(xien1[dict[id],jh,jd,s]-1/(1+length(ID)*SD[jh,jd,s])))
        end

        for jh in JH, jd in JD, s in S
            dual_residual_ec[jh,jd,s]=rho*((dt[jh,jd,s]-1/(1+length(ID)*SD[jh,jd,s]))-(xcen1[jh,jd,s]-1/(1+length(ID)*SD[jh,jd,s])))
        end

        Psi=(
            sqrt(sum((primal_residual_e[jh,jd,s])^2 for jh in JH, jd in JD, s in S)
        ))

        Xsi=(
            sqrt(sum((dual_residual_ei[dict[id],jh,jd,s])^2 for id in ID, jh in JH, jd in JD, s in S)) + sqrt(sum((dual_residual_ec[jh,jd,s])^2 for jh in JH, jd in JD, s in S))
        )

        return(Psi,Xsi)

    elseif B=="ORDC"
        for jh in JH, jd in JD, s in S
            primal_residual_e[jh,jd,s]= sum(g[id,jh,jd,s] for id in ID)-dt[jh,jd,s]
        end

        for id in ID, jh in JH, jd in JD, s in S
            dual_residual_ei[dict[id],jh,jd,s]=rho*((g[id,jh,jd,s]-1/(1+length(ID)*SD[jh,jd,s]))-(xien1[dict[id],jh,jd,s]-1/(1+length(ID)*SD[jh,jd,s])))
        end

        for jh in JH, jd in JD, s in S
            dual_residual_ec[jh,jd,s]=rho*((dt[jh,jd,s]-1/(1+length(ID)*SD[jh,jd,s]))-(xcen1[jh,jd,s]-1/(1+length(ID)*SD[jh,jd,s])))
        end

        Psi=(
            sqrt(sum((primal_residual_e[jh,jd,s])^2 for jh in JH, jd in JD, s in S)
        ))

        Xsi=(
            sqrt(sum((dual_residual_ei[dict[id],jh,jd,s])^2 for id in ID, jh in JH, jd in JD, s in S)) + sqrt(sum((dual_residual_ec[jh,jd,s])^2 for jh in JH, jd in JD, s in S))
        )

        return(Psi,Xsi)

    end

end
