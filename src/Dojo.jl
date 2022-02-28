module Dojo

# constants
global REG = 1.0e-10

using LinearAlgebra
using Random
using StaticArrays
using SparseArrays
using FiniteDiff
using StaticArrays: SUnitRange
using Rotations
using Rotations: RotationError, params, lmult, rmult, tmat, vmat, hmat, skew, pure_quaternion
using Parameters
using Statistics

using Colors: RGBA, RGB
using FFMPEG
using LightXML
using MeshCat
using Meshing
using GeometryBasics
using LightGraphs

using JLD2
using DocStringExtensions

# Utilities
include(joinpath("utilities", "methods.jl"))
include(joinpath("utilities", "custom_static.jl"))

# Orientation
include(joinpath("orientation", "quaternion.jl"))
include(joinpath("orientation", "mrp.jl"))
include(joinpath("orientation", "axis_angle.jl"))
include(joinpath("orientation", "mapping.jl"))
include(joinpath("orientation", "rotate.jl"))

# Graph system
include(joinpath("graph", "entry.jl"))
include(joinpath("graph", "system.jl"))
include(joinpath("graph", "linear_system.jl"))
include(joinpath("graph", "adjacency.jl"))
include(joinpath("graph", "dfs.jl"))
include(joinpath("graph", "cycles.jl"))
include(joinpath("graph", "ldu.jl"))

# Graph objects
include(joinpath("mechanism", "node.jl"))
include(joinpath("mechanism", "edge.jl"))
include(joinpath("mechanism", "id.jl"))

# Bodies
include(joinpath("bodies", "shapes.jl"))
include(joinpath("bodies", "state.jl"))
include(joinpath("bodies", "constructor.jl"))
include(joinpath("bodies", "origin.jl"))
include(joinpath("bodies", "set.jl"))

# Mechanism
include(joinpath("joints", "constraint.jl"))
include(joinpath("contacts", "constructor.jl"))
include(joinpath("contacts", "contact.jl"))

include(joinpath("mechanism", "constructor.jl"))
include(joinpath("mechanism", "gravity.jl"))
include(joinpath("mechanism", "state.jl"))
include(joinpath("mechanism", "system.jl"))
include(joinpath("mechanism", "methods.jl"))
include(joinpath("mechanism", "set.jl"))
include(joinpath("mechanism", "get.jl"))
include(joinpath("mechanism", "urdf.jl"))
include(joinpath("mechanism", "traversal.jl"))

# Simulation
include(joinpath("simulation", "step.jl"))
include(joinpath("simulation", "storage.jl"))
include(joinpath("simulation", "simulate.jl"))

# Mechanics
include(joinpath("mechanics", "momentum.jl"))
include(joinpath("mechanics", "energy.jl"))

# Joints
include(joinpath("joints", "orthogonal.jl"))
include(joinpath("joints", "joint.jl"))
include(joinpath("joints", "translational", "constructor.jl"))
include(joinpath("joints", "translational", "impulses.jl"))
include(joinpath("joints", "translational", "input.jl"))
include(joinpath("joints", "translational", "springs.jl"))
include(joinpath("joints", "translational", "dampers.jl"))
include(joinpath("joints", "translational", "minimal.jl"))
include(joinpath("joints", "rotational", "constructor.jl"))
include(joinpath("joints", "rotational", "impulses.jl"))
include(joinpath("joints", "rotational", "input.jl"))
include(joinpath("joints", "rotational", "springs.jl"))
include(joinpath("joints", "rotational", "dampers.jl"))
include(joinpath("joints", "rotational", "minimal.jl"))
include(joinpath("joints", "limits.jl"))
include(joinpath("joints", "prototypes.jl"))
include(joinpath("joints", "minimal.jl"))
include(joinpath("joints", "impulses.jl"))

# Contacts
include(joinpath("contacts", "constraints.jl"))
include(joinpath("contacts", "cone.jl"))
include(joinpath("contacts", "impact.jl"))
include(joinpath("contacts", "linear.jl"))
include(joinpath("contacts", "nonlinear.jl"))
include(joinpath("contacts", "utils.jl"))

# Solver
include(joinpath("solver", "linear_system.jl"))
include(joinpath("solver", "centering.jl"))
include(joinpath("solver", "complementarity.jl"))
include(joinpath("solver", "violations.jl"))
include(joinpath("solver", "options.jl"))
include(joinpath("solver", "initialization.jl"))
include(joinpath("solver", "correction.jl"))
include(joinpath("solver", "mehrotra.jl"))
include(joinpath("solver", "line_search.jl"))

# Integrator
include(joinpath("integrators", "integrator.jl"))
include(joinpath("integrators", "constraint.jl"))

# Visualizer
include(joinpath("visuals", "visualizer.jl"))
include(joinpath("visuals", "set.jl"))
include(joinpath("visuals", "convert.jl"))
include(joinpath("visuals", "colors.jl"))

# Data
include(joinpath("mechanism", "data.jl"))

# Gradients
include(joinpath("gradients", "finite_difference.jl"))
include(joinpath("gradients", "state.jl"))
include(joinpath("gradients", "data.jl"))
include(joinpath("gradients", "utilities.jl"))

# Environments
include(joinpath("..", "environments", "mechanisms.jl"))
include(joinpath("..", "environments", "environment.jl"))
include(joinpath("..", "environments", "dynamics.jl"))
include(joinpath("..", "environments", "utilities.jl"))

include(joinpath("..", "environments", "include.jl"))

# Bodies
export
    Body,
    Origin,
    Box,
    Cylinder,
    Sphere,
    Pyramid,
    Mesh,
    Shapes,
    get_body,
    get_node

# Joints
export
    Rotational,
    Translational,
    JointConstraint,
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
    get_joint

# Contacts
export
    ContactConstraint,
    ImpactContact,
    LinearContact,
    NonlinearContact,
    get_contact

# Inputs
export
    set_input!,
    add_input!,
    input_dimension

# Mechanism
export
    Mechanism,
    get_mechanism,
    initialize!

# Maximal
export
    set_maximal_configurations!,
    set_maximal_velocities!,
    maximal_dimension

# Minimal
export
    set_minimal_coordinates!,
    set_minimal_velocities!,
    get_minimal_state,
    minimal_coordinates,
    minimal_velocities,
    minimal_dimension

# Maximal <-> Minimal
export
    maximal_to_minimal,
    minimal_to_maximal

# Simulation
export
    simulate!,
    step!

# Environments
export
    Environment

# Orientation
export
    UnitQuaternion,
    RotX,
    RotY,
    RotZ,
    attitude_jacobian

# Data
export
    get_data,
    set_data!,
    get_solution

# Gradients
export
    maximal_to_minimal_jacobian,
    minimal_to_maximal_jacobian

# Mechanics
export
    kinetic_energy,
    potential_energy,
    mechanical_energy,
    momentum

# Solver
export
    mehrotra!,
    SolverOptions

# Linear System "Ax = b"
export
    full_matrix,
    full_data_matrix

# Visuals
export
    Visualizer,
    set_background!,
    set_floor!,
    set_surface!,
    set_light!,
    set_camera!
    RGBA

# Static
export
    szeros,
    sones,
    srand

end
