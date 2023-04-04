function get_slider(; 
    timestep=0.01, 
    input_scaling=timestep, 
    gravity=-9.81, 
    springs=0.0, 
    dampers=0.0,
    limits=false,
    joint_limits=Dict(),
    T=Float64)

    # mechanism
    origin = Origin{T}()

    pbody = Box(0.1, 0.1, 1.0, 1.0)
    bodies = [pbody]

    joint_between_origin_and_pbody = JointConstraint(Prismatic(origin, pbody, Z_AXIS; 
        child_vertex=Z_AXIS/2))
    joints = [joint_between_origin_and_pbody]

    mech = Mechanism(origin, bodies, joints;
        gravity, timestep, input_scaling)

    # springs and dampers
    set_springs!(mech.joints, springs)
    set_dampers!(mech.joints, dampers)

    # joint limits    
    if limits
        joints = set_limits(mech, joint_limits)

        mech = Mechanism(Origin{T}(), mech.bodies, joints;
            gravity, timestep, input_scaling)
    end

    # construction finished
    return mech
end

function initialize_slider!(mechanism::Mechanism{T}; 
    position=0.0) where T

    body = mechanism.bodies[1]
    joint = mechanism.joints[1]
    child_vertex = joint.translational.vertices[2]
    set_maximal_configurations!(mechanism.origin, body, 
        child_vertex=child_vertex - [0, 0, position])
end

function get_nslider(; 
    timestep=0.01, 
    gravity=-9.81, 
    springs=0.0, 
    dampers=0.0, 
    num_bodies=5,
    T=Float64)

    # Parameters
    ex = Z_AXIS
    h = 1.0
    r = 0.05
    vert11 = [0.0; r; 0.0]
    vert12 = -vert11

    # Links
    origin = Origin{T}()
    bodies = [Cylinder(r, h, h, color=RGBA(1.0, 0.0, 0.0)) for i = 1:num_bodies]

    # Constraints
    jointb1 = JointConstraint(Prismatic(origin, bodies[1], ex; 
        child_vertex = 0 * vert11))

    if num_bodies > 1
        joints = [
            jointb1;
            [JointConstraint(Prismatic(bodies[i - 1], bodies[i], ex; 
                parent_vertex=vert12, 
                child_vertex=vert11, 
                spring, 
                damper=damper)) for i = 2:num_bodies]
            ]
    else
        joints = [jointb1]
    end

    mech = Mechanism(origin, bodies, joints;
        gravity, 
        timestep)

    return mech
end

function initialize_nslider!(mechanism::Mechanism{T}; 
    position=0.2, 
    relative_position=0.0) where T

    pbody = mechanism.bodies[1]

    # set position and velocities
    set_maximal_configurations!(mechanism.origin, pbody, 
        parent_vertex=[0.0, 0.0, position])

    # set relative positions
    previd = pbody.id
    for body in mechanism.bodies[2:end]
        set_maximal_configurations!(get_body(mechanism, previd), body, 
            parent_vertex=[0.0, -0.1, relative_position])
        previd = body.id
    end

    zero_velocity!(mechanism)
end
