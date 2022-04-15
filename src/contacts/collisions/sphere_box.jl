"""
    SphereBoxCollision 

    collision between sphere and box 

    origin_sphere:    position of sphere contact relative to body center of mass
    origin_box_a:     position of box corner contact a relative to body center of mass
    origin_box_b:     position of box corner contact b relative to body center of mass
    radius_sphere:    radius of sphere contact
"""
mutable struct SphereBoxCollision{T,O,I,OI} <: Collision{T,O,I,OI}
    origin_sphere::SVector{I,T}
    corner_x::SVector{I,T}
    corner_y::SVector{I,T}
    corner_z::SVector{I,T}
    radius_sphere::T
end 

# distance
function distance(collision::SphereBoxCollision, xp, qp, xc, qc)
    # contact origin points
    cop = contact_point_origin(xp, qp, collision.origin_sphere) 
    coc = contact_point_box(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z)
    
    # distance between contact origins
    d = norm(cop - coc, 2)

    # minimum distance between spheres
    return d - collision.radius_sphere
end

function ∂distance∂x(gradient::Symbol, collision::SphereBoxCollision, xp, qp, xc, qc)
    # contact origin points
    cop = contact_point_origin(xp, qp, collision.origin_sphere) 
    coc = contact_point_box(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z)

    # distance between contact origins
    d = norm(cop - coc, 2)
    ∂norm∂d = ∂norm∂x(cop - coc)

    if gradient == :parent
        D = ∂norm∂d * (1.0 * ∂contact_point_origin∂x(xp, qp, collision.origin_sphere) - ∂contact_point_box∂p(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z) * ∂contact_point_origin∂x(xp, qp, collision.origin_sphere))
    elseif gradient == :child 
        D = ∂norm∂d * -1.0 * ∂contact_point_box∂x(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z)
    end

    if gradient == :parent 
        FD = FiniteDiff.finite_difference_jacobian(x -> distance(collision, x, qp, xc, qc), xp)
    elseif gradient == :child 
        FD = FiniteDiff.finite_difference_jacobian(x -> distance(collision, xp, qp, x, qc), xc)
    end

    return FD

    # @assert norm(D - FD, Inf) < 1.0e-5

    # return D
end

function ∂distance∂q(gradient::Symbol, collision::SphereBoxCollision, xp, qp, xc, qc)
    # contact origin points
    cop = contact_point_origin(xp, qp, collision.origin_sphere) 
    coc = contact_point_box(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z)

     # distance between contact origins
     d = norm(cop - coc, 2)
     ∂norm∂d = ∂norm∂x(cop - coc)
 
     if gradient == :parent
         D = ∂norm∂d * (1.0 * ∂contact_point_origin∂q(xp, qp, collision.origin_sphere) - ∂contact_point_box∂p(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z) * ∂contact_point_origin∂q(xp, qp, collision.origin_sphere))
     elseif gradient == :child 
         D = ∂norm∂d * -1.0 * ∂contact_point_box∂q(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z)
     end

    if gradient == :parent 
        FD = FiniteDiff.finite_difference_jacobian(q -> distance(collision, xp, Quaternion(q..., false), xc, qc), vector(qp))
    elseif gradient == :child 
        FD = FiniteDiff.finite_difference_jacobian(q -> distance(collision, xp, qp, xc, Quaternion(q..., false)), vector(qc))
    end

    return FD

    # @assert norm(D - FD, Inf) < 1.0e-5

    return D
end

# contact point in world frame
function contact_point(relative::Symbol, collision::SphereBoxCollision, xp, qp, xc, qc) 
    # contact origin points
    cop = contact_point_origin(xp, qp, collision.origin_sphere) 
    coc = contact_point_box(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z)

    # direction of minimum distance (child to parent)
    d = cop - coc 
    dir = normalize(d)

    # contact point
    if relative == :parent
        return cop - collision.radius_sphere * dir
    elseif relative == :child 
        return coc 
    end
end

function ∂contact_point∂x(relative::Symbol, jacobian::Symbol, collision::SphereBoxCollision, xp, qp, xc, qc)
    # contact origin points
    cop = contact_point_origin(xp, qp, collision.origin_sphere) 
    coc = contact_point_box(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z)

    # direction of minimum distance (child to parent)
    d = cop - coc 
    dir = normalize(d)

    if relative == :parent 
        # cop - collision.radius_sphere * dir
        if jacobian == :parent 
            ∂c∂x = ∂contact_point_origin∂x(xp, qp, collision.origin_sphere)
            X = ∂c∂x 
            X -= collision.radius_sphere * ∂normalize∂x(d) * (∂c∂x - ∂contact_point_box∂p(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z) * ∂c∂x)
        elseif jacobian == :child 
            X = -1.0 * collision.radius_sphere * ∂normalize∂x(d) * -1.0 * ∂contact_point_box∂x(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z)
        end
    elseif relative == :child 
        # coc 
        if jacobian == :parent 
            X = ∂contact_point_box∂p(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z) * ∂contact_point_origin∂x(xp, qp, collision.origin_sphere)
        elseif jacobian == :child 
            X = ∂contact_point_box∂x(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z)
        end
    end

    if jacobian == :parent
        FD =  FiniteDiff.finite_difference_jacobian(x -> contact_point(relative, collision, x, qp, xc, qc), xp)
    elseif jacobian == :child 
        FD = FiniteDiff.finite_difference_jacobian(x -> contact_point(relative, collision, xp, qp, x, qc), xc)
    end

    return FD

    # @assert norm(X - FD, Inf) < 1.0e-5

    return X
end

function ∂contact_point∂q(relative::Symbol, jacobian::Symbol, collision::SphereBoxCollision, xp, qp, xc, qc)
    # contact origin points
    cop = contact_point_origin(xp, qp, collision.origin_sphere) 
    coc = contact_point_box(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z)

    # direction of minimum distance (child to parent)
    d = cop - coc 
    dir = normalize(d)

    if relative == :parent 
        # cop - collision.radius_sphere * dir
        if jacobian == :parent 
            ∂c∂q = ∂contact_point_origin∂q(xp, qp, collision.origin_sphere)
            Q = ∂c∂q 
            Q -= collision.radius_sphere * ∂normalize∂x(d) * (∂c∂q - ∂contact_point_box∂p(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z) * ∂c∂q)
        elseif jacobian == :child 
            Q = -1.0 * collision.radius_sphere * ∂normalize∂x(d) * -1.0 * ∂contact_point_box∂q(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z)
        end
    elseif relative == :child 
        # coc
        if jacobian == :parent 
            Q = ∂contact_point_box∂p(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z) * ∂contact_point_origin∂q(xp, qp, collision.origin_sphere)
        elseif jacobian == :child 
            Q = ∂contact_point_box∂q(cop, xc, qc, collision.corner_x, collision.corner_y, collision.corner_z)
        end
    end

    if jacobian == :parent
        FD = FiniteDiff.finite_difference_jacobian(q -> contact_point(relative, collision, xp, Quaternion(q..., false), xc, qc), vector(qp))
    elseif jacobian == :child 
        FD = FiniteDiff.finite_difference_jacobian(q -> contact_point(relative, collision, xp, qp, xc, Quaternion(q..., false)), vector(qc))
    end

    return FD

    # @assert norm(Q - FD, Inf) < 1.0e-5

    return Q
end

