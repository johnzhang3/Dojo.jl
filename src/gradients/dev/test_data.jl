using Dojo
using Test

include("data.jl")
include("utils.jl")

function test_get_set_data(mechanism::Mechanism)
    Nd = data_dim(mechanism, attjac=false)
    data0 = rand(Nd)
    set_data!(mechanism, data0)
    data1 = get_data(mechanism)
    @test norm(data0 - data1) < 1e-10
end

@testset "get and set data" begin
    mech = getsnake(Nb=3, damper=1.0, spring=1.0, contact_type=:contact);
    test_get_set_data(mech)
    mech = getsnake(Nb=3, damper=1.0, spring=1.0, contact_type=:linear_contact);
    test_get_set_data(mech)
    mech = getsnake(Nb=3, damper=1.0, spring=1.0, contact_type=:impact);
    test_get_set_data(mech)

    mech = getpendulum(damper=1.0, spring=10.0);
    test_get_set_data(mech)
    mech = gethumanoid(damper=1.0, spring=10.0, contact=true);
    test_get_set_data(mech)
    mech = gethumanoid(damper=1.0, spring=10.0, contact=false);
    test_get_set_data(mech)
    mech = getatlas(damper=1.0, spring=10.0);
    test_get_set_data(mech)
    mech = getquadruped(damper=1.0, spring=10.0);
    test_get_set_data(mech)
end
