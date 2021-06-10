## code for analyzing cost of market mechanisms
# author: Victor Debray
# last update: 10 June, 2021


## Step 0: Activate environment - ensure consistency accross computers
ENV["GUROBI_HOME"] = "/Library/gurobi903/mac64"
import Pkg
Pkg.add("Gurobi")
Pkg.add("Distributions")
Pkg.build("Gurobi")
using Pkg
Pkg.activate(@__DIR__) # @__DIR__ = directory this script is in
Pkg.instantiate() # If a Manifest.toml file exist in the current project, download all the packages declared in that manifest. Else, resolve a set of feasible packages from the Project.toml files and install them.

##  Step 1: input data
using CSV # Excel based format to store data --> get the time series in CSV :)
using DataFrames
using YAML #to store the input data!!
using Random, Distributions
using Plots

data = YAML.load_file(joinpath(@__DIR__, "data_gep.yaml"))
ts = CSV.read(joinpath(@__DIR__, "Profiles_12_reprdays.csv"), DataFrame)#store this data in a dataframe = convenient
repr_days = CSV.read(joinpath(@__DIR__, "Weights_12_reprdays.csv"), DataFrame)
LOLp = CSV.read(joinpath(@__DIR__, "LOLP_parameters.csv"), DataFrame)
LOADS = CSV.read(joinpath(@__DIR__, "LOADS_10_scenario.csv"), DataFrame)

## Step 2: create model & pass data to model
using JuMP
using Gurobi
const GRB_ENV=Gurobi.Env()

m = Model(() -> Gurobi.Optimizer(GRB_ENV))
set_optimizer_attribute(m, "OutputFlag", 0)
m_risk1 = Model(() -> Gurobi.Optimizer(GRB_ENV))
set_optimizer_attribute(m_risk1, "OutputFlag", 0)
m_risk2 = Model(() -> Gurobi.Optimizer(GRB_ENV))
set_optimizer_attribute(m_risk2, "OutputFlag", 0)
m_risk3 = Model(() -> Gurobi.Optimizer(GRB_ENV))
set_optimizer_attribute(m_risk3, "OutputFlag", 0)
m_risk4 = Model(() -> Gurobi.Optimizer(GRB_ENV))
set_optimizer_attribute(m_risk4, "OutputFlag", 0)
m_risk5 = Model(() -> Gurobi.Optimizer(GRB_ENV))
set_optimizer_attribute(m_risk5, "OutputFlag", 0)

MM=[m, m_risk1, m_risk2, m_risk3, m_risk4, m_risk5]
M1=[m_risk1, m_risk2, m_risk3, m_risk4]
M2=[m_risk1, m_risk2, m_risk3, m_risk4, m_risk5]

include("prepare_parameters.jl")
#still to do: capacity target ofr cCM with different scenarios
for m in MM
    define_sets!(m,data)
    process_time_series_data!(m, data, ts, LOADS)
    process_parameters!(m, data, repr_days)
    build_ORDC!(m, data, LOLp)
end

## Step 3: build the model

include("build_model.jl")
include("build_model_risk.jl")
include("risk_iteration.jl")
include("update_price.jl")
include("update_residuals.jl")
include("update_past.jl")

# recall that you can, once you've built a model, delete and overwrite constraints using the appropriate reference:
A = "risk-averse" #neutral or risk-averse
B ="ORDC" #EO, cCM or ORDC

dict= Dict("Mid"=>1, "Base"=>2, "Peak"=>3)
dict2=Dict(m_risk1=>"Mid", m_risk2=>"Base", m_risk3=>"Peak", m_risk4=>"Load", m_risk5=>"Operator")
if A == "neutral"
    #build your model
    build_greenfield_IY_GEP_model!(m, B)
    #solve your model
    optimize!(m)
    # check termination status
    print(
        """

        Termination status: $(termination_status(m))

        """
    )
    #check first results
    @show value.(m.ext[:objective])
    @show value.(m.ext[:variables][:cap])
end

threshold=100
#threshold= tau*sqrt((length(ID)+1)*length(S)*length(JH)*length(JD))
max_loop=3

if A == "risk-averse"

    l=0
    while true
        l=l+1
        println("loop number: ", l)
        if B=="ORDC"
            for m in M2
                risk_iteration!(m,B,dict2[m],dict)
            end

            for m in M2
                update_price!(m,B,dict)
            end

            residuals= update_residuals!(B,dict)

            for m in M2
                update_past!(m,B,dict)
            end

        else
            for m in M1
                risk_iteration!(m,B,dict2[m],dict)
            end

            for m in M1
                update_price!(m,B,dict)
            end

            residuals= update_residuals!(B,dict)

            for m in M1
                update_past!(m,B,dict)
            end
        end

        Psi=residuals[1]
        Xsi=residuals[2]
        println("Primal stopping criteria: ", Psi)
        println("Dual stopping criteria: ", Xsi)
        if Psi< threshold
            if Xsi< threshold
                break
            end
        end
        if l==max_loop
            break
        end

    end

    println("number of loops: ", l)
end

@show value.(m_risk3.ext[:variables][:cap])
@show value.(m_risk2.ext[:variables][:cap])
@show value.(m_risk1.ext[:variables][:cap])

# check termination status
print(
    """

    Termination status: $(termination_status(m))

    """
)


@show value.(m.ext[:objective])
@show value.(m.ext[:variables][:cap])

include("get_values.jl")

a = get_values!(m,B)
