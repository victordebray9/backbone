## Step 3: construct your model
# Greenfield GEP - single year (Lecture 3 - slide 25, but based on representative days instead of full year)
function build_greenfield_IY_GEP_model_risk!(m::Model, B, id, dict)
    # Clear m.ext entries "variables", "expressions" and "constraints" as dictionnaries --> place where we store our variables
    m.ext[:variables] = Dict()
    m.ext[:expressions] = Dict()
    m.ext[:constraints] = Dict()

    # Extract sets
    JH = m.ext[:sets][:JH]
    JD = m.ext[:sets][:JD]
    ID = m.ext[:sets][:ID]
    I = m.ext[:sets][:I]
    J = m.ext[:sets][:J]
    S = m.ext[:sets][:S]


    # Extract time series data
    AF = m.ext[:timeseries][:AF]
    D = m.ext[:timeseries][:D] # there must be 10 different demands!!!! -> first take random, then take one that you can justify! :)
    SD = m.ext[:timeseries][:SD]

    # Extract parameters
    FC = m.ext[:parameters][:FC]
    VOLL=m.ext[:parameters][:VOLL]
    Dcm = m.ext[:parameters][:Dcm]#capacity demand
    W = m.ext[:parameters][:W] #weights
    IC = m.ext[:parameters][:IC]
    OC = m.ext[:parameters][:OC]
    LT = m.ext[:parameters][:LT]
    CONE= m.ext[:parameters][:CONE]
    Gamma = m.ext[:parameters][:Gamma]
    Beta = m.ext[:parameters][:Beta]
    P = m.ext[:parameters][:prob]

    Vr = m.ext[:parameters][:Vr]
    Dres = m.ext[:parameters][:Dres]
    Dr = m.ext[:parameters][:Dr]
    rho=m.ext[:parameters][:rho]
    tau=m.ext[:parameters][:tau]

    pen=m.ext[:ADMM][:pen]
    xien=m.ext[:ADMM][:xien]
    xcen=m.ext[:ADMM][:xcen]
    pcap=m.ext[:ADMM][:pcap]
    xicap=m.ext[:ADMM][:xicap]
    xccap=m.ext[:ADMM][:xccap]
    pres=m.ext[:ADMM][:pres]
    xires=m.ext[:ADMM][:xires]
    xcres=m.ext[:ADMM][:xcres]



    if B =="EO"
        cap = m.ext[:variables][:cap] = @variable(m, [id=ID], lower_bound=0, base_name="capacity")
        g = m.ext[:variables][:g] = @variable(m, [id=ID,jh=JH,jd=JD, s=S] , lower_bound=0, base_name="generation")
        dt = m.ext[:variables][:dt] = @variable(m, [jh=JH,jd=JD, s=S], lower_bound=0, base_name="load_real")
        a = m.ext[:variables][:a] = @variable(m, [id=ID], lower_bound=0, base_name="value at risk")
        u = m.ext[:variables][:u] = @variable(m, [id=ID, s=S], lower_bound=0, base_name="adjusted probability")
        # Formulate objective 1a

        if id == "Load"
            m.ext[:objective] = @objective(m,Min,
                -sum(P[s]*W[jd]*VOLL*dt[jh,jd,s] for jh in JH, jd in JD, s in S)
                +sum(P[s]*W[jd]*pen[jh,jd,s]*dt[jh,jd,s] for jh in JH, jd in JD, s in S)
                + rho/2*(
                sum(((dt[jh,jd,s]-(xcen[jh,jd,s]-1/(length(ID)+1)*(sum(xien[dict[id],jh,jd,s] for id in ID)-xcen[jh,jd,s]))))^2 for jh in JH, jd in JD, s in S)
                )
            )

            #constraints
            m.ext[:constraints][:con1a] = @constraint(m, [jh=JH, jd=JD, s =S],
                dt[jh,jd,s] <= SD[jh,jd,s]
            )


        else
            m.ext[:objective] = @objective(m, Min,
                Gamma[id]*(
                IC[id]*cap[id]
                +sum(P[s]*W[jd]*FC[id]*g[id,jh,jd,s] for jh in JH, jd in JD, s in S)
                )
                -(1-Gamma[id])*(
                a[id]
                -1/Beta[id]*sum(u[id,s] for s in S)
                )
                - Gamma[id]*sum(P[s]*W[jd]*pen[jh,jd,s]*g[id,jh,jd,s] for jh in JH, jd in JD, s in S)
                +rho/2*(
                sum(((g[id,jh,jd,s]-(xien[dict[id],jh,jd,s]-1/(length(ID)+1)*(sum(xien[dict[id],jh,jd,s] for id in ID)-xcen[jh,jd,s]))))^2 for jh in JH, jd in JD, s in S)
                )
            )
            # constraints
            #generator does not generate more than its capacity
            m.ext[:constraints][:con3a] = @constraint(m, [id=ID,jh=JH,jd=JD,s=S],
                g[id,jh,jd,s] <= cap[id]
            )

            m.ext[:constraints][:con4a] = @constraint(m, [id=ID, s=S],
                a[id]-sum(pen[jh,jd,s]*W[jd]*g[id,jh,jd,s]-FC[id]*W[jd]*g[id,jh,jd,s] for jh in JH, jd in JD) + IC[id]*cap[id]-u[id,s] <= 0
            )

        end

    elseif B=="cCM"
        cap = m.ext[:variables][:cap] = @variable(m, [id=ID], lower_bound=0, base_name="capacity")
        capcm = m.ext[:variables][:capcm] = @variable(m, [id=ID,s=S], lower_bound=0, base_name="cmcapacity")
        g = m.ext[:variables][:g] = @variable(m, [id=ID,jh=JH,jd=JD, s=S] , lower_bound=0, base_name="generation")
        dt = m.ext[:variables][:dt] = @variable(m, [jh=JH,jd=JD, s=S], lower_bound=0, base_name="load_real")
        dcm = m.ext[:variables][:dcm] = @variable(m, [s=S], lower_bound=0, base_name="capacity_demand")
        a = m.ext[:variables][:a] = @variable(m, [id=ID], lower_bound=0, base_name="value at risk")
        u = m.ext[:variables][:u] = @variable(m, [id=ID, s=S], lower_bound=0, base_name="adjusted probability")


        if id == "Load"
            m.ext[:objective] = @objective(m,Min,
                -sum(P[s]*W[jd]*VOLL*dt[jh,jd,s] for jh in JH, jd in JD, s in S)
                -sum(P[s]*CONE*dcm[s] for s in S)
                +sum(P[s]*W[jd]*pen[jh,jd,s]*dt[jh,jd,s] for jh in JH, jd in JD, s in S)
                +sum(P[s]*pcap[s]*dcm[s] for s in S)
                + rho/2*(
                sum(((dt[jh,jd,s]-(xcen[jh,jd,s]-1/(length(ID)+1)*(sum(xien[dict[id],jh,jd,s] for id in ID)-xcen[jh,jd,s]))))^2 for jh in JH, jd in JD, s in S)
                + sum(((dcm[s]-(xccap[s]-1/(length(ID)+1)*(sum(xicap[dict[id],s] for id in ID)-xccap[s]))))^2 for s in S)

                )
            )

            #constraints
            m.ext[:constraints][:con1a] = @constraint(m, [jh=JH, jd=JD, s =S],
                dt[jh,jd,s] <= SD[jh,jd,s]
            )

            m.ext[:constraints][:con1b] = @constraint(m, [s =S],
                dcm[s] <= Dcm
            )

        else
            m.ext[:objective] = @objective(m, Min,
                Gamma[id]*(
                IC[id]*cap[id]
                +sum(P[s]*W[jd]*FC[id]*g[id,jh,jd,s] for jh in JH, jd in JD, s in S)
                )
                -(1-Gamma[id])*(
                a[id]
                -1/Beta[id]*sum(u[id,s] for s in S)
                )
                - Gamma[id]*sum(P[s]*W[jd]*pen[jh,jd,s]*g[id,jh,jd,s] for jh in JH, jd in JD, s in S)
                - Gamma[id]*sum(P[s]*pcap[s]*capcm[id,s] for s in S)
                +rho/2*(
                sum(((g[id,jh,jd,s]-(xien[dict[id],jh,jd,s]-1/(length(ID)+1)*(sum(xien[dict[id],jh,jd,s] for id in ID)-xcen[jh,jd,s]))))^2 for jh in JH, jd in JD, s in S)
                + sum(((capcm[id,s]-(xicap[dict[id],s]-1/(length(ID)+1)*(sum(xicap[dict[id],s] for id in ID)-xccap[s]))))^2 for s in S)
                )
            )
            # constraints
            #generator does not generate more than its capacity
            m.ext[:constraints][:con3a] = @constraint(m, [id=ID,jh=JH,jd=JD,s=S],
                g[id,jh,jd,s] <= cap[id]
            )

            m.ext[:constraints][:con3b] = @constraint(m, [id=ID,s=S],
                capcm[id,s]<=cap[id]
            )

            m.ext[:constraints][:con4a] = @constraint(m, [id=ID, s=S],
                a[id]-sum(pen[jh,jd,s]*W[jd]*g[id,jh,jd,s]-FC[id]*W[jd]*g[id,jh,jd,s] for jh in JH, jd in JD) - pcap[s]*capcm[id,s] + IC[id]*cap[id]-u[id,s] <= 0
            )

        end



    elseif B=="ORDC"
        cap = m.ext[:variables][:cap] = @variable(m, [id=ID], lower_bound=0, base_name="capacity")
        g = m.ext[:variables][:g] = @variable(m, [id=ID,jh=JH,jd=JD,s=S] , lower_bound=0, base_name="generation")
        r = m.ext[:variables][:r] = @variable(m, [id=ID, jh=JH, jd =JD, s=S], lower_bound=0, base_name="reserve_capacity_supply")
        dt = m.ext[:variables][:dt] = @variable(m, [jh=JH,jd=JD, s=S], lower_bound=0, base_name="load_real")
        dr = m.ext[:variables][:dr] = @variable(m, [j=J, jh=JH, jd=JD, s=S], lower_bound=0, base_name="reserve_capacity_demand")
        a = m.ext[:variables][:a] = @variable(m, [id=ID], lower_bound=0, base_name="value at risk")
        u = m.ext[:variables][:u] = @variable(m, [id=ID, s=S], lower_bound=0, base_name="adjusted probability")



        if id == "Load"
            m.ext[:objective] = @objective(m,Min,
                -sum(P[s]*W[jd]*VOLL*dt[jh,jd,s] for jh in JH, jd in JD, s in S)
                +sum(P[s]*W[jd]*pen[jh,jd,s]*dt[jh,jd,s] for jh in JH, jd in JD, s in S)
                + rho/2*(
                sum(((dt[jh,jd,s]-(xcen[jh,jd,s]-1/(length(ID)+1)*(sum(xien[dict[id],jh,jd,s] for id in ID)-xcen[jh,jd,s]))))^2 for jh in JH, jd in JD, s in S)
                )
            )

            #constraints
            m.ext[:constraints][:con1a] = @constraint(m, [jh=JH, jd=JD, s =S],
                dt[jh,jd,s] <= SD[jh,jd,s]
            )

        elseif id == "Operator"
            m.ext[:objective] = @objective(m,Min,
                -sum(P[s]*W[jd]*Vr[1,j]*dr[j,jh,jd,s] for j in J, jh in JH, jd in JD, s in S)
                +sum(P[s]*W[jd]*pres[jh,jd,s]*dr[j,jh,jd,s] for j in J, jh in JH, jd in JD, s in S)
                + rho/2*(
                sum((dr[j,jh,jd,s]-(xcres[j,jh,jd,s]-1/(length(ID)+1)*(sum(xires[dict[id],jh,jd,s] for id in ID)-sum(xcres[j,jh,jd,s] for j in J))))^2 for j in J, jh in JH, jd in JD, s in S)
                )
            )

            #constraints
            m.ext[:constraints][:con1c] = @constraint(m, [jh=JH, jd=JD, j=J,s=S],
                dr[j,jh,jd,s] <= Dres[1,j]
            )

        else
            m.ext[:objective] = @objective(m, Min,
                Gamma[id]*(
                IC[id]*cap[id]
                +sum(P[s]*W[jd]*FC[id]*g[id,jh,jd,s] for jh in JH, jd in JD, s in S)
                )
                -(1-Gamma[id])*(
                a[id]
                -1/Beta[id]*sum(u[id,s] for s in S)
                )
                - Gamma[id]*sum(P[s]*W[jd]*pen[jh,jd,s]*g[id,jh,jd,s] for jh in JH, jd in JD, s in S)
                - Gamma[id]*sum(P[s]*W[jd]*pres[jh,jd,s]*r[id,jh,jd,s] for jh in JH, jd in JD, s in S)
                +rho/2*(
                sum(((g[id,jh,jd,s]-(xien[dict[id],jh,jd,s]-1/(length(ID)+1)*(sum(xien[dict[id],jh,jd,s] for id in ID)-xcen[jh,jd,s]))))^2 for jh in JH, jd in JD, s in S)
                + sum(((r[id,jh,jd,s]-(xires[dict[id],jh,jd,s]-1/(length(ID)+1)*(sum(xires[dict[id],jh,jd,s] for id in ID)-sum(xcres[j,jh,jd,s] for j in J)))))^2 for jh in JH, jd in JD, s in S)
                )
            )
            # constraints
            m.ext[:constraints][:con3c] = @constraint(m, [id=ID,jh=JH,jd=JD,s=S],
                g[id,jh,jd,s] + r[id,jh,jd,s] <= cap[id]#we assume capacity is already present
                )

            m.ext[:constraints][:con4a] = @constraint(m, [id=ID, s=S],
                a[id]-sum(pen[jh,jd,s]*W[jd]*g[id,jh,jd,s]-FC[id]*W[jd]*g[id,jh,jd,s] for jh in JH, jd in JD) - sum(pres[jh,jd,s]*r[id,jh,jd,s] for jh in JH, jd in JD) + IC[id]*cap[id]-u[id,s] <= 0
            )
        end

    end
    return m
end
