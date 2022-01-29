using LinearAlgebra
using StaticArrays
using ForwardDiff
using FiniteDiff
using StaticArrays: SUnitRange
using Rotations
using Rotations: RotationError, params, lmult, rmult, tmat, vmat, hmat, skew, pure_quaternion
using Colors: RGBA, RGB
using LightXML
using Parameters
using SparseArrays
using Distributions

using Plots
using Random
using MeshCat
using GeometryBasics
using LightGraphs
using DocStringExtensions
using JLD2


export Origin,
    Body,
    JointConstraint,
    ContactConstraint,
    Mechanism,
    Storage,
    UnitQuaternion,
    Rotational,
    Translational,

    Box,
    Cylinder,
    Sphere,
    Pyramid,
    Mesh,

    Fixed,
    Prismatic,
    Planar,
    FixedOrientation,
    Revolute,
    Cylindrical,
    PlanarAxis,
    FreeRevolute,
    Orbital,
    PrismaticOrbital,
    PlanarOrbital,
    FreeOrbital,
    Spherical,
    CylindricalFree,
    PlanarFree,

    NonlinearContact,
    UnitQuaternion,

    set_position,
    set_velocity!,
    set_input!,
    add_force!,
    getid,
    getcomponent,
    get_body,
    get_joint_constraint,
    get_contact_constraint,
    simulate!,
    initializeConstraints!,
    disassemble,
    minimal_coordinates,
    minimal_velocities,

    RotX,
    RotY,
    RotZ,
    RGBA,

    szeros,
    sones,
    srand,

    get_mechanism,
    initialize!,
    getdim,
    control_dimension,

    get_mechanism,
    initialize!,
    get_data,
    set_data!,
    get_solution,
    attitude_jacobian,
    finitediff_sol_matrix,
    full_matrix,
    full_data_matrix,
    finitediff_data_matrix,
    finitediff_sensitivity

# Utilities
include(joinpath(module_dir(), "src", "util", "util.jl"))
include(joinpath(module_dir(), "src", "util", "custom_static.jl"))
include(joinpath(module_dir(), "src", "util", "customdict.jl"))
include(joinpath(module_dir(), "src", "util", "quaternion.jl"))

# Graph system
include(joinpath(module_dir(), "src", "graph", "entry.jl"))
include(joinpath(module_dir(), "src", "graph", "system.jl"))
include(joinpath(module_dir(), "src", "graph", "setup_functions.jl"))
include(joinpath(module_dir(), "src", "graph", "ldu.jl"))

# Mechanism
include(joinpath(module_dir(), "src", "mechanism", "shapes.jl"))
include(joinpath(module_dir(), "src", "mechanism", "component.jl"))
include(joinpath(module_dir(), "src", "mechanism", "state.jl"))
include(joinpath(module_dir(), "src", "mechanism", "body.jl"))
include(joinpath(module_dir(), "src", "mechanism", "equality_constraint.jl"))
include(joinpath(module_dir(), "src", "mechanism", "inequality_constraint.jl"))
include(joinpath(module_dir(), "src", "mechanism", "origin.jl"))
include(joinpath(module_dir(), "src", "mechanism", "mechanism.jl"))
include(joinpath(module_dir(), "src", "mechanism", "system.jl"))
include(joinpath(module_dir(), "src", "mechanism", "methods.jl"))
include(joinpath(module_dir(), "src", "mechanism", "momentum.jl"))

# Simulation
include(joinpath(module_dir(), "src", "simulation", "step.jl"))
include(joinpath(module_dir(), "src", "simulation", "storage.jl"))
include(joinpath(module_dir(), "src", "simulation", "simulate.jl"))

# Energy
include(joinpath(module_dir(), "src", "mechanism", "energy.jl"))

# Joints
include(joinpath(module_dir(), "src", "joints", "joint.jl"))
include(joinpath(module_dir(), "src", "joints", "translational", "constraint.jl"))
include(joinpath(module_dir(), "src", "joints", "translational", "input.jl"))
include(joinpath(module_dir(), "src", "joints", "translational", "force.jl"))
include(joinpath(module_dir(), "src", "joints", "translational", "minimal.jl"))
include(joinpath(module_dir(), "src", "joints", "rotational", "constraint.jl"))
include(joinpath(module_dir(), "src", "joints", "rotational", "input.jl"))
include(joinpath(module_dir(), "src", "joints", "rotational", "torque.jl"))
include(joinpath(module_dir(), "src", "joints", "rotational", "minimal.jl"))
include(joinpath(module_dir(), "src", "joints", "prototypes.jl"))

# Inequality constraints
include(joinpath(module_dir(), "src", "bounds", "bound.jl"))
include(joinpath(module_dir(), "src", "bounds", "cone.jl"))
include(joinpath(module_dir(), "src", "bounds", "contact.jl"))
include(joinpath(module_dir(), "src", "bounds", "impact.jl"))
include(joinpath(module_dir(), "src", "bounds", "linear_contact.jl"))

# Solver
include(joinpath(module_dir(), "src", "solver", "methods.jl"))
include(joinpath(module_dir(), "src", "solver", "mehrotra.jl"))
include(joinpath(module_dir(), "src", "solver", "linesearch.jl"))

# Variational integrator
include(joinpath(module_dir(), "src", "discretization", "integrator.jl"))
include(joinpath(module_dir(), "src", "discretization", "body.jl"))

# User interface
include(joinpath(module_dir(), "src", "ui", "mechanism_ui.jl"))
include(joinpath(module_dir(), "src", "ui", "initialize.jl"))
include(joinpath(module_dir(), "src", "ui", "urdf.jl"))
include(joinpath(module_dir(), "src", "ui", "convert_shape.jl"))
include(joinpath(module_dir(), "src", "ui", "visualize.jl"))

# Differentiation
include(joinpath(module_dir(), "src", "gradients", "analytical.jl"))
include(joinpath(module_dir(), "src", "gradients", "finite_difference.jl"))

# Environments
include(joinpath(module_dir(), "env", "mechanisms.jl"))
include(joinpath(module_dir(), "env", "environment.jl"))

# Utilities
include(joinpath(module_dir(), "examples", "trajectory_optimization", "utils.jl"))
include(joinpath(module_dir(), "examples", "reinforcement_learning", "ars.jl"))
