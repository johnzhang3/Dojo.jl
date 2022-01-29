function gethopper(; timestep::T=0.01, gravity=[0.0; 0.0; -9.81], cf::T=2.0,
    contact::Bool=true,
    contact_body::Bool=true,
    limits::Bool = false,
    spring=0.0,
    damper=1.0,
    joint_limits=[[  0,   0, -45] * π/180,
                  [150, 150,  45] * π/180]) where T

    path = joinpath(@__DIR__, "../deps/hopper_good.urdf")
    mech = Mechanism(path, false, T, gravity=gravity, timestep=timestep, spring=spring, damper=damper)

    # joint limits
    joints = deepcopy(mech.joints)

    if limits
        thigh = get_joint_constraint(mech, :thigh)
        joints[thigh.id] = add_limits(mech, thigh, rot_limits=[SVector{1}(joint_limits[1][1]), SVector{1}(joint_limits[2][1])])

        @warn "uncomment limits"
        # leg = get_joint_constraint(mech, "leg")
        # joints[leg.id] = add_limits(mech, leg, rot_limits=[SVector{1}(joint_limits[1][2]), SVector{1}(joint_limits[2][2])])
        #
        # foot = get_joint_constraint(mech, "foot")
        # joints[foot.id] = add_limits(mech, foot, rot_limits=[SVector{1}(joint_limits[1][3]), SVector{1}(joint_limits[2][3])])

        mech = Mechanism(Origin{T}(), [mech.bodies...], [joints...], gravity=gravity, timestep=timestep, spring=spring, damper=damper)
    end

    if contact
        origin = Origin{T}()
        bodies = mech.bodies
        joints = mech.joints

        normal = [0.0; 0.0; 1.0]
        names = contact_body ? getfield.(mech.bodies, :name) : [:ffoot, :foot]
        bounds = []
        for name in names
            body = get_body(mech, name)
            if name == :foot # need special case for foot
                # torso
                pf = [0,0, +0.5 * body.shape.rh[2]]
                pb = [0,0, -0.5 * body.shape.rh[2]]
                o = [0;0; body.shape.rh[1]]
                push!(bounds, contact_constraint(body, normal, cf=cf, p=pf, offset=o))
                push!(bounds, contact_constraint(body, normal, cf=cf, p=pb, offset=o))
            else
                p = [0;0; 0.5 * body.shape.rh[2]]
                o = [0;0; body.shape.rh[1]]
                push!(bounds, contact_constraint(body, normal, cf=cf, p=p, offset=o))
            end
        end
        set_position(mech, get_joint_constraint(mech, :floating_joint), [1.25, 0.0, 0.0])
        mech = Mechanism(origin, bodies, joints, [bounds...], gravity=gravity, timestep=timestep, spring=spring, damper=damper)
    end
    return mech
end

function initializehopper!(mechanism::Mechanism; x::T=0.0, z::T=0.0, θ::T=0.0) where T
    set_position(mechanism,
                 get_joint_constraint(mechanism, :floating_joint),
                 [z + 1.25 , -x, -θ])
    for joint in mechanism.joints
        (joint.name != :floating_joint) && set_position(mechanism, joint, zeros(control_dimension(joint)))
    end
    zeroVelocity!(mechanism)
end
