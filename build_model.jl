## Step 3: construct your model
# Greenfield GEP - single year (Lecture 3 - slide 25, but based on representative days instead of full year)
function build_greenfield_IY_GEP_model!(m::Model, B)
    # Clear m.ext entries "variables", "expressions" and "constraints" as dictionnaries --> place where we store our variables
    m.ext[:variables] = Dict()
    m.ext[:expressions] = Dict()
    m.ext[:constraints] = Dict()

    # Extract sets
    JH = m.ext[:sets][:JH]
    JD = m.ext[:sets][:JD]
    ID = m.ext[:sets][:ID]
    J = m.ext[:sets][:J]
    S = m.ext[:sets][:S]


    # Extract time series data
    AF = m.ext[:timeseries][:AF]
    D = m.ext[:timeseries][:D] # there must be 10 different demands!!!! -> first take random, then take one that you can justify! :)
    SD = m.ext[:timeseries][:SD]

    # Extract parameters
    FC = m.ext[:parameters][:FC]
    #Der = m.ext[:parameters][:Der]
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

        if B =="EO"
            cap = m.ext[:variables][:cap] = @variable(m, [id=ID], lower_bound=0, base_name="capacity")
            g = m.ext[:variables][:g] = @variable(m, [id=ID,jh=JH,jd=JD] , lower_bound=0, base_name="generation")
            dt = m.ext[:variables][:dt] = @variable(m, [jh=JH,jd=JD], lower_bound=0, base_name="load_real")


            # Formulate objective 1a
            m.ext[:objective] = @objective(m, Max,
                + sum(W[jd]*VOLL*dt[jh,jd] for jh in JH, jd in JD) #wilingness to pay
                - sum(IC[id]*cap[id] for id in ID) #annuity of overnight investment cost
                - sum(W[jd]*FC[id]*g[id,jh,jd] for id in ID, jh in JH, jd in JD) #variable cost
                )#+ sum(W[jd]*(D[jh,jd]-dt[jh,jd])*VOLL for jh in JH, jd in JD) #other way to do this :)
                # is this really okay to have just 1 year with IC? Yes, if you have 1 year lifetime, IC= 525000, if 2 years, 269000 -> more than 2 times half ->
                # the total investment reduced over 1 year as we counted the revenue from selling electricity in the second year with a discount factor.
                # (equivalent to look if total recovered costs over the whole lifetime recovers investment costs)the timespan is 1 year.

                # constraints
                #generation = load + energy not served
            m.ext[:constraints][:con2a] = @constraint(m, [jh=JH, jd=JD],#it applies for each timelapse on each day but over sum of each power plant :)
                dt[jh,jd] - sum(g[id,jh,jd] for id in ID) == 0 #d is here the shedded residual demand
                )#if constraint released by one unit, it means dt is increased with 1. :o -> g with one as well but dt increase not counted in the objective function...


                #constraint that real load is smaller than demanded load -> load shedding
            m.ext[:constraints][:con1a] = @constraint(m, [jh=JH, jd=JD],
                dt[jh,jd] <= D[jh,jd]
                )

                # renewables
                #m.ext[:constraints][:con3a1res] = @constraint(m, [i=IV,jh=JH, jd =JD],
                #g[i,jh,jd] <= AF[i][jh,jd]*cap[i]
                #)

                # 3a1 - conventional
            m.ext[:constraints][:con3a] = @constraint(m, [id=ID,jh=JH,jd=JD],
                g[id,jh,jd] <= cap[id]#we assume there is no capacity already present
                #dual variable is the marginal cost of the binding contraint. If the capacity of the base unit was no more limiting,
                #you would produce 1 quant of energy less with the mid (at time [1,1] and one more with the base:
                #Your objextive to maximize will thus be 40 bigger (50-10 less fuel costs) )
                #BUT: because of the weigths, the marginal cost difference and thus alpha will be much bigger than 40!
                )

        elseif B=="cCM"
            cap = m.ext[:variables][:cap] = @variable(m, [id=ID], lower_bound=0, base_name="capacity")
            capcm = m.ext[:variables][:capcm] = @variable(m, [id=ID], lower_bound=0, base_name="cmcapacity")
            g = m.ext[:variables][:g] = @variable(m, [id=ID,jh=JH,jd=JD] , lower_bound=0, base_name="generation")
            dt = m.ext[:variables][:dt] = @variable(m, [jh=JH,jd=JD], lower_bound=0, base_name="load_real")
            dcm = m.ext[:variables][:dcm] = @variable(m, lower_bound=0, base_name="capacity_demand")

            m.ext[:objective] = @objective(m, Max,
                + sum(W[jd]*VOLL*dt[jh,jd] for jh in JH, jd in JD) #wilingness to pay
                - sum(IC[id]*cap[id] for id in ID) #annuity of overnight investment cost
                - sum(W[jd]*FC[id]*g[id,jh,jd] for id in ID, jh in JH, jd in JD) #variable cost
                + CONE*dcm
                )#because timespan is 1 year, the money received from building capacity is not the total, but the annualized one...

                # constraints
                #generation = load + energy not served
            m.ext[:constraints][:con2a] = @constraint(m, [jh=JH, jd=JD],#it applies for each timelapse on each day but over sum of each power plant :)
                dt[jh,jd] - sum(g[id,jh,jd] for id in ID) == 0# - ens[jh,jd] (maybe later)
                )

                #capacity market clearing
            m.ext[:constraints][:con2b] = @constraint(m,
                sum(capcm[id] for id in ID) ==  dcm
                )

                #constraint that real load is smaller than demanded load -> load shedding
                m.ext[:constraints][:con1a] = @constraint(m, [jh=JH, jd=JD],
                dt[jh,jd] <= D[jh,jd]
                )

                m.ext[:constraints][:con1b] = @constraint(m,
                dcm <= Dcm
                )

                # renewables
                #m.ext[:constraints][:con3a1res] = @constraint(m, [i=IV,jh=JH, jd =JD],
                #g[i,jh,jd] <= AF[i][jh,jd]*cap[i]
                #)

                # 3a1 - conventional
                m.ext[:constraints][:con3a]= @constraint(m, [id=ID,jh=JH,jd=JD],
                g[id,jh,jd] <= cap[id]#we assume capacity is already present
                )
                m.ext[:constraints][:con3b] = @constraint(m, [id=ID],
                capcm[id] <= cap[id]
                )

        elseif B=="ORDC"
            cap = m.ext[:variables][:cap] = @variable(m, [id=ID], lower_bound=0, base_name="capacity")
            g = m.ext[:variables][:g] = @variable(m, [id=ID,jh=JH,jd=JD] , lower_bound=0, base_name="generation")
            r = m.ext[:variables][:r] = @variable(m, [id=ID, jh=JH, jd =JD], lower_bound=0, base_name="reserve_capacity_supply")
            dt = m.ext[:variables][:dt] = @variable(m, [jh=JH,jd=JD], lower_bound=0, base_name="load_real")
            dr = m.ext[:variables][:dr] = @variable(m, [j=J, jh=JH, jd=JD], lower_bound=0, base_name="reserve_capacity_demand")

            m.ext[:objective] = @objective(m, Max,
                + sum(W[jd]*VOLL*dt[jh,jd] for jh in JH, jd in JD) #wilingness to pay
                - sum(IC[id]*cap[id] for id in ID) #annuity of overnight investment cost
                - sum(W[jd]*FC[id]*g[id,jh,jd] for id in ID, jh in JH, jd in JD) #variable cost
                + sum(W[jd]*Vr[1,j]*dr[j,jh,jd] for jh in JH, jd in JD, j in J)
                )#because timespan is 1 year, the money received from building capacity is not the total, but the annualized one...

                    # constraints
                    #generation = load + energy not served
            m.ext[:constraints][:con2a] = @constraint(m, [jh=JH, jd=JD],#it applies for each timelapse on each day but over sum of each power plant :)
                dt[jh,jd] - sum(g[id,jh,jd] for id in ID) == 0 # - ens[jh,jd] (maybe later)
                )
                    #reserve market clearing
            m.ext[:constraints][:con2c] = @constraint(m, [jh=JH, jd=JD],#it applies for each timelapse on each day but over sum of each power plant :)
                sum(dr[j,jh,jd] for j in J) - sum(r[id,jh,jd] for id in ID) == 0# - ens[jh,jd] (maybe later)
                )


                    #constraint that real load is smaller than demanded load -> load shedding
            m.ext[:constraints][:con1a] = @constraint(m, [jh=JH, jd=JD],
                dt[jh,jd] <= D[jh,jd]
                )

            m.ext[:constraints][:con1c] = @constraint(m, [jh=JH, jd=JD, j=J],
                dr[j,jh,jd] <= Dres[1,j]
                )

                    # renewables
                    #m.ext[:constraints][:con3a1res] = @constraint(m, [i=IV,jh=JH, jd =JD],
                    #g[i,jh,jd] <= AF[i][jh,jd]*cap[i]
                    #)

                    # 3a1 - conventional
            m.ext[:constraints][:con3c] = @constraint(m, [id=ID,jh=JH,jd=JD],
                g[id,jh,jd] + r[id,jh,jd] <= cap[id]#we assume capacity is already present
                )
        end
#=
    elseif A == "risk-averse"
        threshold=tau*sqrt((size(ID)+1)*size(S)*size(JH)*size(JD))

        if B =="EO"
            cap = m.ext[:variables][:cap] = @variable(m, [id=ID], lower_bound=0, base_name="capacity")
            g = m.ext[:variables][:g] = @variable(m, [id=ID,jh=JH,jd=JD, s=S] , lower_bound=0, base_name="generation")
            dt = m.ext[:variables][:dt] = @variable(m, [jh=JH,jd=JD, s=S], lower_bound=0, base_name="load_real")
            a = m.ext[:variables][:a] = @variable(m, [id=ID], lower_bound=0, base_name="value at risk")
            u = m.ext[:variables][:u] = @variable(m, [id=ID, s=S], lower_bound=0, base_name="adjusted probability")
            # Formulate objective 1a
            while Psi>threshold, Xsi> threshold

                for id in ID
                    m.ext[:objective1] = @objective(m, Min,
                        Gamma[id]*(
                        IC[id]*cap[id]
                        +sum(P[s]*FC[id]*g[id,jh,jd,s] for jh in JH, jd in JD, s in S)
                        )
                        -(1-Gamma[id])*(
                        a[id]
                        -1/Beta[id]*sum(u[id,s] for s in S)
                        )
                        - Gamma[id]*sum(P[s]*pen[jh,jd,s]*g[id,jh,jd,s]for jh in JH, jd in JD, s in S)
                        +rho/2*(
                        sum(g[id,jh,jd,s]-(xien[id,jh,jd,s]-1/(size(ID)+1)*(sum(xien[id,jh,jd,s]for id in ID)-xcen[jh,jd,s]))for jh in JH, jd in JD, s in S)
                        )^2
                    )
                    # constraints
                    #generator does not generate more than its capacity
                    m.ext[:constraints][:con3a] = @constraint(m, [id=ID,jh=JH,jd=JD,s=S],
                        g[id,jh,jd,s] <= cap[id]
                    )

                    m.ext[:constraints][:con4a] = @constraint(m, [id=ID, s=S],
                        a[id]-sum((pen[jh,jd,js]-FC[id])*g[id,jh,jd,s] for jh in JH, jd in JD) + IC[id]*cap[id]-u[id,s]
                    )
                end

                m.ext[:objective2] = @objective(m,Min,
                    -sum(P[s]*VOLL*dt[jh,jd,s] for jh in JH, jd in JD, s in S)
                    +sum(P[s]*pen[jh,jd,s]*dt[jh,jd,s] for jh in JH, jd in JD, s in S)
                    + rho/2*(
                    sum(dt[jh,jd,s]-(xcen[jh,jd,s]-1/(size(ID)+1)*(sum(xien[id,jh,jd,s]for id in ID)-xcen[jh,jd,s]))for jh in JH, jd in JD, s in S)
                    )^2
                )

                #constraints
                m.ext[:constraints][:con1a] = @constraint(m, [jh=JH, jd=JD, s =S],
                    dt[jh,jd,s] <= SD[jh,jd,s]
                )

                #price update
                for jh in JH, jd in JD, s in S
                    pen[jh,jd,js]=pen[jh,jd,s]-rho*(sum(g[id,jh,jd,s]for id in ID)- dt[jh,jd,s])
                end

                primal_residual=

                Psi=()

                dual_residual=
                Xsi=
            end



        elseif B=="cCM"
            cap = m.ext[:variables][:cap] = @variable(m, [id=ID], lower_bound=0, base_name="capacity")
            capcm = m.ext[:variables][:capcm] = @variable(m, [id=ID], lower_bound=0, base_name="cmcapacity")
            g = m.ext[:variables][:g] = @variable(m, [id=ID,jh=JH,jd=JD] , lower_bound=0, base_name="generation")
            dt = m.ext[:variables][:dt] = @variable(m, [jh=JH,jd=JD], lower_bound=0, base_name="load_real")
            dcm = m.ext[:variables][:dcm] = @variable(m, lower_bound=0, base_name="capacity_demand")

            m.ext[:objective] = @objective(m, Max,
                + sum(W[jd]*VOLL*dt[jh,jd] for jh in JH, jd in JD)
                - sum(IC_risk[id]*cap[id] for id in ID)
                - sum(W[jd]*FC[id]*g[id,jh,jd] for id in ID, jh in JH, jd in JD)
                + CONE*dcm
                )

            #constraints

                #capacity market clearing
            m.ext[:constraints][:con2b] = @constraint(m,
                sum(capcm[id] for id in ID) ==  dcm
                )

                #constraint that real load is smaller than demanded load -> load shedding
                m.ext[:constraints][:con1a] = @constraint(m, [jh=JH, jd=JD],
                dt[jh,jd] <= D[jh,jd]
                )
                #constraint that demand for capacity is smaller than the maximal amount of capacity demand
                m.ext[:constraints][:con1b] = @constraint(m,
                dcm <= Dcm
                )


                # generators do not generate more than their capacity
                m.ext[:constraints][:con3a]= @constraint(m, [id=ID,jh=JH,jd=JD],
                g[id,jh,jd] <= cap[id]
                )
                m.ext[:constraints][:con3b] = @constraint(m, [id=ID],
                capcm[id] <= cap[id]
                )

        elseif B=="ORDC"
            cap = m.ext[:variables][:cap] = @variable(m, [id=ID], lower_bound=0, base_name="capacity")
            g = m.ext[:variables][:g] = @variable(m, [id=ID,jh=JH,jd=JD] , lower_bound=0, base_name="generation")
            r = m.ext[:variables][:r] = @variable(m, [id=ID, jh=JH, jd =JD], lower_bound=0, base_name="reserve_capacity_supply")
            dt = m.ext[:variables][:dt] = @variable(m, [jh=JH,jd=JD], lower_bound=0, base_name="load_real")
            dr = m.ext[:variables][:dr] = @variable(m, [jh=JH, jd=JD, j=J], lower_bound=0, base_name="reserve_capacity_demand")

            m.ext[:objective] = @objective(m, Max,
                + sum(W[jd]*VOLL*dt[jh,jd] for jh in JH, jd in JD)
                - sum(IC_risk[id]*cap[id] for id in ID)
                - sum(W[jd]*FC[id]*g[id,jh,jd] for id in ID, jh in JH, jd in JD)
                + sum(W[jd]*Vr[1,j]*dr[jh,jd,j] for jh in JH, jd in JD, j in J)
                )

            # constraints
            #generation = load + energy not served
            m.ext[:constraints][:con2a] = @constraint(m, [jh=JH, jd=JD],#it applies for each timelapse on each day but over sum of each power plant :)
                dt[jh,jd] - sum(g[id,jh,jd] for id in ID) == 0 # - ens[jh,jd] (maybe later)
                )
            #reserve market clearing
            m.ext[:constraints][:con2c] = @constraint(m, [jh=JH, jd=JD],
                sum(dr[jh,jd,j] for j in J) - sum(r[id,jh,jd] for id in ID) == 0
                )


            #constraint that real load is smaller than demanded load -> load shedding
            m.ext[:constraints][:con1a] = @constraint(m, [jh=JH, jd=JD],
                dt[jh,jd] <= D[jh,jd]
                )
            #constraint that demand for reserve cannot be bigger than residual demand vor reserve...
            m.ext[:constraints][:con1c] = @constraint(m, [jh=JH, jd=JD, j=J],
                dr[jh,jd,j] <= Dres[1,j]
                )


            # the amount of reserves available + the generated electricty is smaller than the capacity for each generator
            m.ext[:constraints][:con3c] = @constraint(m, [id=ID,jh=JH,jd=JD],
                g[id,jh,jd] + r[id,jh,jd] <= cap[id]#we assume capacity is already present
                )
        end
        =#


    return m
end
