
## Step 5: interpretation
function get_values!(m::Model, B)
    # sets
    JH = m.ext[:sets][:JH]
    JD = m.ext[:sets][:JD]
    ID = m.ext[:sets][:ID]
    J = m.ext[:sets][:J]


    # parameters
    D = m.ext[:timeseries][:D]
    W = m.ext[:parameters][:W]
    LC = m.ext[:parameters][:LC] #legacy capacityg
    VOLL = m.ext[:parameters][:VOLL]
    IC = m.ext[:parameters][:IC]
    FC = m.ext[:parameters][:FC]


    # variables/expressions
    if B=="EO"
        g = value.(m.ext[:variables][:g]) #is a 5x24x12 array because 12 representative days, 24 time steps in a day and 5 generator technologies
        cap = value.(m.ext[:variables][:cap]) #is a 5x1 vector because only 5 generation technologies
        totcap = sum(cap[id] for id in ID)
        l = dual.(m.ext[:constraints][:con2a]) #price of energy
        lvec = [l[jh,jd]/W[jd] for jh in JH, jd in JD]#the real prices must be divided by the weights
        #-> way to much remuneration if we dont do this! (not anymore, I added W in constraint :) )
        aa = dual.(m.ext[:constraints][:con3a])
        aavec = [aa[id,jh,jd]/W[jd] for id in ID, jh in JH, jd in JD]
        dt = value.(m.ext[:variables][:dt])
        CE=sum(l[jh,jd]*dt[jh,jd] for jh in JH, jd in JD) #Energy cost for the society that buys it
        CENS=sum(W[jd]*VOLL*(D[jh,jd]-dt[jh,jd]) for jh in JH, jd in JD) #Energy not served cost for society by estimating the VOLL
        #totload=sum(W[jd]*dt[jh,jd] for jh in JH, jd in JD)
        #totnotserved = sum(W[jd]*(D[jh,jd]-dt[jh,jd]) for jh in JH, jd in JD)
        CCM=0
        CORDC=0
        Rtot=-CE #equals the revenues from different markets for the generators
        SOCcost=Rtot+CENS #cost to the society as a whole


    elseif B=="cCM"
        g = value.(m.ext[:variables][:g])
        cap = value.(m.ext[:variables][:cap])
        totcap = sum(cap[id] for id in ID)
        capcm = m.ext[:variables][:capcm]
        l = dual.(m.ext[:constraints][:con2a])
        lvec = [l[jh,jd]/W[jd] for jh in JH, jd in JD]
        lcap=dual.(m.ext[:constraints][:con2b])
        aa = dual.(m.ext[:constraints][:con3a])
        ab = dual.(m.ext[:constraints][:con3b])
        aavec = [aa[id,jh,jd]/W[jd] for id in ID, jh in JH, jd in JD]
        dt = value.(m.ext[:variables][:dt])
        dcm =value.(m.ext[:variables][:dcm])
        CE=sum(l[jh,jd]*dt[jh,jd] for jh in JH, jd in JD)
        CENS=sum(W[jd]*VOLL*(D[jh,jd]-dt[jh,jd]) for jh in JH, jd in JD)
        CCM=lcap*sum(cap[id] for id in ID) # Capacity cost for the system operator buying capacity from generators
        CORDC=0
        Rtot=-CE+CCM #equals the revenues from different markets for the generators
        SOCcost=Rtot+CENS

    elseif B=="ORDC"
        g = value.(m.ext[:variables][:g])
        r = value.(m.ext[:variables][:r])
        cap = value.(m.ext[:variables][:cap])
        totcap = sum(cap[id] for id in ID)
        l = dual.(m.ext[:constraints][:con2a])
        lvec = [l[jh,jd]/W[jd] for jh in JH, jd in JD]
        lr = dual.(m.ext[:constraints][:con2c])
        lrvec = [lr[jh,jd]/W[jd] for jh in JH, jd in JD]
        aa = dual.(m.ext[:constraints][:con3c])
        aavec = [aa[id,jh,jd]/W[jd] for id in ID, jh in JH, jd in JD]
        dt = value.(m.ext[:variables][:dt])
        dr = value.(m.ext[:variables][:dr])
        CE=sum(l[jh,jd]*dt[jh,jd] for jh in JH, jd in JD)
        CENS=sum(W[jd]*VOLL*(D[jh,jd]-dt[jh,jd]) for jh in JH, jd in JD)
        CCM=0
        CORDC=sum(lr[jh,jd]*dr[jh,jd,j] for jh in JH, jd in JD, j in J)
        Rtot=-CE-CORDC #equals the revenues from different markets for the generators
        SOCcost=Rtot+CENS
    end

     Invcost=sum(IC[id]*cap[id] for id in ID) #Investment costs for all the genrators
     Opcost=sum(W[jd]*FC[id]*g[id,jh,jd] for id in ID, jh in JH, jd in JD) #operational costs for all the generators

     TOTcost=Invcost+Opcost #equals the different costs for the generators
     #because we are in an equilibrium model, this term must be equal to the revenued of the genrators.



     return (CE,CCM,CORDC,CENS,Invcost,Opcost,totcap)




    # # create arrays for plotting
    # dlvec=convert(DataFrame,lvec)
    # gvec = [g[i,jh,jd] for i in I, jh in JH, jd in JD]
    # dgvec=convert(DataFrame,gvec)
    #
    #
    # if B = "EO"
    # #CSV.write("/Users/victordebray/Google_Drive/Master_Thesis/Advancement/backbone\\clearing_prices.csv",dlvec)
    # #CSV.write("/Users/victordebray/Google_Drive/Master_Thesis/Advancement/backbone\\capacity_equilibrium.csv",dcapvec)
    # #CSV.write("/Users/victordebray/Google_Drive/Master_Thesis/Advancement/backbone\\instant_generation.csv",dgvec)
    # elseif B = "cCM"


end
