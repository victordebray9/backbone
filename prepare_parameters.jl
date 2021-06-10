# Step 2a: create sets
function define_sets!(m::Model, data::Dict) #define data as a dictionnary?
    # create dictionary to store sets
    m.ext[:sets] = Dict() #store sets in a dictionary in ext field of model (sets is name of dictionary) :)

    # define the sets
    m.ext[:sets][:JH] = 1:data["nTimesteps"] # Timesteps per day is set JH
    m.ext[:sets][:JD] = 1:data["nReprDays"] # Representative days
    m.ext[:sets][:ID] = [id for id in keys(data["dispatchableGenerators"])] # dispatchable generators --> Peak, Mid, Base
    #m.ext[:sets][:IV] = [iv for iv include keys(data["variableGenerators"])] # variable generators
    #m.ext[:sets][:I] = m.ext[:sets][:ID]# m.ext[:sets][:IV]) # all generators
    m.ext[:sets][:S] = 1:10 #we will account for 10 possible scenrarios!
    m.ext[:sets][:I] = 1:3
    # return model
    return m
end

# Step 2b: add time series
function process_time_series_data!(m::Model, data::Dict, ts::DataFrame, LOADS::DataFrame) #takes the model, the dictionnary data & the Dataframe ts
    # extract the relevant sets
    #IV=m.ext[:sets][:IV]
    JH = m.ext[:sets][:JH] # Time steps per day is set JH
    JD = m.ext[:sets][:JD] # Days
    S = m.ext[:sets][:S]

    # create dictionary to store time series
    m.ext[:timeseries] = Dict()
    m.ext[:timeseries][:AF]=Dict()

    #prepare the load
    m.ext[:timeseries][:D] = [ts.Load_res[jh+data["nTimesteps"]*(jd-1)] for jh in JH, jd in JD]

    #prepare the loads with different scenarios
    m.ext[:timeseries][:SD] = [LOADS.LOAD_10_YEARS_3[jh + data["nTimesteps"]*(jd-1) + data["nReprDays"]*data["nTimesteps"]*(s-1)] for jh in JH, jd in JD, s in S]

    return m
    #--->at this stage we have a model with an external field with the timeseries and the indices: no parameters, constraints or variables!
end

# step 2c: process input parameters
function process_parameters!(m::Model, data::Dict, repr_days::DataFrame)
    # extract the sets you need from the dictionnary
    #I = m.ext[:sets][:I]
    ID = m.ext[:sets][:ID]#dispatchableGenerators
    #IV = m.ext[:sets][:IV]

    # generate a dictonary "parameters"
    m.ext[:parameters] = Dict()
    m.ext[:ADMM]=Dict()

    #input parameters
    VOLL=m.ext[:parameters][:VOLL]=data["VOLL"]#value of lost load
    r=m.ext[:parameters][:discountrate]=data["discountrate"]#because it is a dictionnary
    W = m.ext[:parameters][:W]=repr_days.Weights #because it is a Dataframe
    Dcm = m.ext[:parameters][:Dcm]=maximum(ts.Load_res) #because we put the maximal load as demand target, there will be zero load shedding :)
    p = m.ext[:parameters][:p]=data["probability"]
    prob = m.ext[:parameters][:prob]= fill(p,10)
    rho = m.ext[:parameters][:rho]=data["penalty_factor"]
    tau = m.ext[:parameters][:tau]=data["threshold_factor"]


    d = data["dispatchableGenerators"]


    #LC = m.ext[:parameters][:LC] = Dict(id => d[id]["legcap"] for id in ID)
    #m.ext[:parameters][:Der] = Dict(id => d[id]["derating"] for id in ID)
    m.ext[:parameters][:Gamma] = Dict(id => d[id]["w_factor"] for id in ID)#parameters for risk-aversion
    m.ext[:parameters][:Beta] = Dict(id => d[id]["risk-aversion"] for id in ID)#parameters for risk aversion

    #variable costs
    FC = m.ext[:parameters][:FC] = Dict(id => d[id]["fuelCosts1"] for id in ID) # MW

    #investment cost
    OC = m.ext[:parameters][:OC] = Dict(id => d[id]["OC1"] for id in ID) #EUR/MW
    LT = m.ext[:parameters][:LT] = Dict(id => d[id]["lifetime"] for id in ID)
    IC = m.ext[:parameters][:IC] = Dict(id => r*OC[id]/(1-(1+r).^(-LT[id])) for id in ID) #EUR/MW/year

    CONE=m.ext[:parameters][:CONE]=IC["Peak"] # net cost of new entry = annualized investment cost of peak power plant.

    #prepare variables used in ADMM
    m.ext[:ADMM][:pen]=zeros(24,12,10) #energy price
    m.ext[:ADMM][:xien]=zeros(3,24,12,10) #generated quantity of past iteration
    m.ext[:ADMM][:xcen]=zeros(24,12,10) #load of past iteration
    m.ext[:ADMM][:pcap]=zeros(10) #capacity price
    m.ext[:ADMM][:xicap]=zeros(3,10) # installed capacity of past iteration
    m.ext[:ADMM][:xccap]=zeros(10) #capacity demand of past iteration
    m.ext[:ADMM][:pres]=zeros(24,12,10) # reserve price
    m.ext[:ADMM][:xires]=zeros(3,24,12,10) # reserve of past iteration
    m.ext[:ADMM][:xcres]=zeros(7,24,12,10) #reserve demand of past iteration
    m.ext[:ADMM][:primal_residual_e]=zeros(24,12,10) #primal residual
    m.ext[:ADMM][:dual_residual_ei]=zeros(3,24,12,10) #dual reisdual of generators
    m.ext[:ADMM][:dual_residual_ec]=zeros(24,12,10) #dual resiudal of the load
    m.ext[:ADMM][:primal_residual_c]=zeros(10)
    m.ext[:ADMM][:dual_residual_ci]=zeros(3,10)
    m.ext[:ADMM][:dual_residual_cc]=zeros(10)
    m.ext[:ADMM][:primal_residual_o]=zeros(24,12,10)
    m.ext[:ADMM][:dual_residual_oi]=zeros(3,24,12,10)
    m.ext[:ADMM][:dual_residual_oc]=zeros(7,24,12,10)
    m.ext[:ADMM][:generation]=zeros(3,24,12,10)
    m.ext[:ADMM][:capacity]=zeros(3,10)
    m.ext[:ADMM][:reserve]=zeros(3,24,12,10)

    # return model
    return m
end

function build_ORDC!(m::Model, data::Dict, LOLp::DataFrame)
    VOLL=m.ext[:parameters][:VOLL]
    M=m.ext[:timeseries][:Mean]=-LOLp.mean
    Dev=m.ext[:timeseries][:Deviation]=LOLp.standard_deviation
    I=1:length(M)
    N=Array{Normal}(undef, 24)
    x1=Array{Array{Float16}}(undef,24)
    x2=Array{Array{Float16}}(undef,24)
    x3=Array{Array{Float16}}(undef,24)
    xtot=Array{Array{Float64}}(undef,24) #vector that will contain the extreme point of the segments
    mid=Array{Array{Float16}}(undef,24) #array that will contain the middle of the segments
    Ext=3*Dev+M
    Dr=Array{Array{Float16}}(undef,24)
    norm=Normal(0,1)


    for i in I
        x1[i]=collect(range(0, stop=Ext[i],length=7))
        mid[i]=[splice!(x1[i],6)]
        x2[i]=collect(range(x1[i][3],stop=x1[i][5],length=5))
        pushfirst!(mid[i],splice!(x2[i],2),splice!(x2[i],3))
        x3[i]=collect(range(x1[i][1],stop=x1[i][3], length=9))
        pushfirst!(mid[i],splice!(x3[i],2),splice!(x3[i],3),splice!(x3[i],4),splice!(x3[i],5))
        splice!(x3[i],5)
        xtot[i]=push!(append!(x3[i],x2[i]),x1[i][6])
    end
    J=m.ext[:sets][:J]=1:length(mid[1])
    MC=25
    Dr = m.ext[:parameters][:Dr]=[(mid[i][j]-M[i])/Dev[i] for i in I,j in J] #quantity of reserves in the 7 different segments at the 24 different timeblocks! (normalized) :)
    ii = ones(24,7)
    Vr= m.ext[:parameters][:Vr]= (VOLL-MC)*(ii-cdf(norm,Dr)) #valuation of reserve in the 7 different segments at the 24 different timeblocks. If Dr does far -> cdf goes toward 1 and Vr=0
    Dres=m.ext[:parameters][:Dres]=[xtot[i][j+1]-xtot[i][j] for i in I, j in J] #intervals of the different segments
    return m
end
