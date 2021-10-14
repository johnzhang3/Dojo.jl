################################################################################
# Development
################################################################################
using ConstrainedDynamics
using ConstrainedDynamicsVis

# Utils
function module_dir()
    return joinpath(@__DIR__, "..", "..")
end

# Activate package
using Pkg
Pkg.activate(module_dir())

# Load packages
using Plots
using Random
using StaticArrays
using LinearAlgebra
using Test

# Include dev files
include(joinpath(module_dir(), "examples", "dev", "loader.jl"))

mech = getmechanism(:dice, Δt = 0.01, g = -9.81, cf = 0.2, contact = true, conetype = :soc)

Random.seed!(100)
ω = 0.0 * (rand(3) .- 0.5) * 1
x = [0, 0, 1.0]
v = 0.0 * [1, 0.3, 0.2]
initialize!(mech, :dice, x = x, v = v, ω = ω)
storage = simulate!(mech, 0.01, record = true, solver = :mehrotra!)

################################################################################
# Differentiation
################################################################################

include(joinpath(module_dir(), "examples", "dev", "diff_tools_control_contact.jl"))
# Set data
Nb = length(mech.bodies)
# Random.seed!(10)
# ndata = datadim(mech, quat = true)
# data = rand(ndata)*0.05
data = getdata(mech)
setdata!(mech, data)
mehrotra!(mech, opts = InteriorPointOptions(rtol = 1e-6, btol = 1e-1, undercut=1.2, verbose=true))
sol = getsolution(mech)
attjac = attitudejacobian(data, Nb)

# IFT
setentries!(mech)
datamat = full_data_matrix(mech)
solmat = full_matrix(mech.system)
sensi = - (solmat \ datamat)
@show cond(solmat)
@show rank(solmat)
@show norm(full_vector(mech.system), Inf)

# finite diff
fd_datamat = finitediff_data_matrix(mech, data, sol) * attjac
@test norm(fd_datamat + datamat, Inf) < 1e-7
plot(Gray.(abs.(datamat)))
plot(Gray.(abs.(fd_datamat)))

fd_solmat = finitediff_sol_matrix(mech, data, sol)
@test norm(fd_solmat + solmat, Inf) < 1e-7
plot(Gray.(abs.(solmat)))
plot(Gray.(abs.(fd_solmat)))

fd_sensi = finitediff_sensitivity(mech, data) * attjac
@test norm(fd_sensi - sensi) / norm(fd_sensi) < 5e-3
plot(Gray.(sensi))
plot(Gray.(fd_sensi))
norm(fd_sensi - sensi, Inf)
norm(fd_sensi, Inf)

###############################################################################
# plot
###############################################################################

plot(hcat(Vector.(storage.x[1])...)')
plot(hcat([[q.w, q.x, q.y, q.z] for q in storage.q[1]]...)')
plot(hcat(Vector.(storage.v[1])...)')
plot(hcat(Vector.(storage.ω[1])...)')

sdf = get_sdf(mech, storage)
plot(hcat(sdf[1]...)', ylims = (-0.01,0.01))
plot(hcat(sdf[2]...)', ylims = (-0.01,0.01))
plot(hcat(sdf[3]...)', ylims = (-0.01,0.01))
plot(hcat(sdf[4]...)', ylims = (-0.01,0.01))
plot(hcat(sdf[5]...)')
plot(hcat(sdf[6]...)')
plot(hcat(sdf[7]...)')
plot(hcat(sdf[8]...)')
