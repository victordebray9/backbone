# Step 2a: create sets
function define_sets!(m::Model, data::Dict) #define data as a dictionnary?
    # create dictionary to store sets
    m.ext[:sets] = Dict() #store sets in a dictionary in ext field of model (sets is name of dictionary) :)

    # define the sets
    m.ext[:sets][:JH] = 1:data["nTimesteps"] # Timesteps per day is set JH
    m.ext[:sets][:JD] = 1:data["nReprDays"] # Representative days
    m.ext[:sets][:ID] = [id for id in keys(data["dispatchableGenerators"])] # dispatchable generators --> Peak, Mid, Base
    #m.ext[:sets][:IV] = [iv for iv in keys(data["variableGenerators"])] # variable generators
    #m.ext[:sets][:I] = m.ext[:sets][:ID]# m.ext[:sets][:IV]) # all generators

    # return model
    return m
end

# Step 2b: add time series
function process_time_series_data!(m::Model, data::Dict, ts::DataFrame) #takes the model, the dictionnary data & the Dataframe ts
    # extract the relevant sets
    #IV=m.ext[:sets][:IV]
    JH = m.ext[:sets][:JH] # Time steps per day is set JH
    JD = m.ext[:sets][:JD] # Days

    # create dictionary to store time series
    m.ext[:timeseries] = Dict()
    m.ext[:timeseries][:AF]=Dict()
        #ts.Load in REPL to get them. 12*24=288 :)
    # example: add time series to dictionary
    m.ext[:timeseries][:D] = [ts.Load_res[jh+data["nTimesteps"]*(jd-1)] for jh in JH, jd in JD] #in MW
    #ts is a DataFrame, data is a Dictionnary , jh is a time step in a day, jd is a day
    #it converts a column into an array (ts.Load is a column, m.ext... is an array)-> ona day is one column
    #AF = availability factor
    #m.ext[:timeseries][:AF][IV[1]]=[ts.LFW[jh+data["nTimesteps"]*(jd-1)] for jh in JH, jd in JD]
    #m.ext[:timeseries][:AF][IV[2]]=[ts.LFS[jh+data["nTimesteps"]*(jd-1)] for jh in JH, jd in JD]
    # return model
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

    #input parameters
    #pCO2=m.ext[:parameters][:pCO2]=data["CO2Price"]
    VOLL=m.ext[:parameters][:VOLL]=data["VOLL"]
    r=m.ext[:parameters][:discountrate]=data["discountrate"]#because it is a dictionnary
    W = m.ext[:parameters][:W]=repr_days.Weights #because it is a Dataframe
    m.ext[:parameters][:Dcm]=maximum(ts.Load_res) #because we put the maximal load as demand target, there will be zero load shedding :)


    d = data["dispatchableGenerators"]#data["variableGenerators"])(merge funstion)

    # example: legacy capacity
    LC = m.ext[:parameters][:LC] = Dict(id => d[id]["legcap"] for id in ID) # MW , We are still creating dictionnaries!!
    #here, i is the key? and indicates to the value "legcap" for that key... (it is the legacy of the capacity...)
    m.ext[:parameters][:Der] = Dict(id => d[id]["derating"] for id in ID)

    #variable costs
    FC = m.ext[:parameters][:FC] = Dict(id => d[id]["fuelCosts"] for id in ID) # MW
    #EC = m.ext[:parameters][:EC] = Dict(id => d[id]["emissions"] for id in ID)
    #VC = m.ext[:parameters][:VC] = Dict(id => FC[id] for iD in ID) #+pCO2*EC[i] if we want to account dor the price of CO2
    #investment cost
    OC = m.ext[:parameters][:OC] = Dict(id => d[id]["OC"] for id in ID) #EUR/MW
    LT = m.ext[:parameters][:LT] = Dict(id => d[id]["lifetime"] for id in ID)
    IC = m.ext[:parameters][:IC] = Dict(id => r*OC[id]/(1-(1+r).#(-LT[id])) for id in ID) #EUR/MW/year
    println(IC)
    println(LT)
    CONE=IC["Peak"] # annualized investment cost of peak power plant.

    # return model
    return m
end
