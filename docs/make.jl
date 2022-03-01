push!(LOAD_PATH, "../src/")

using Documenter, Dojo

makedocs(
    modules = [Dojo],
    format = Documenter.HTML(prettyurls = false),
    sitename = "Dojo",
    pages = [
        ##############################################
        ## MAKE SURE TO SYNC WITH docs/src/index.md ##
        ##############################################
        "index.md",

        "Creating a Mechanism" => [
            "define_mechanism.md",
            "load_mechanism.md",
           ],

        "Creating a Simulation" => [
            "define_simulation.md",
            "define_controller.md",
           ],

        "Environments" => [
            "load_environment.md",
            "define_environment.md",
        ],

        "Gradients from Simulator" => [
            "gradients.md",
           ],

        "Examples" => [
            "simulation.md",
            "trajectory_optimization.md",
            "reinforcement_learning.md",
            "system_identification.md",
           ],

        "State Representations" => [
            "maximal_representation.md",
            "minimal_representation.md",
        ],

        "Contact Models" => [
            "contact_models.md",
            "impact.md",
            "nonlinear_friction.md",
            "linearized_friction.md",
        ],

        "Interior-Point Solver" => [
            "interior_point.md",
            "solver_options.md",
        ],

        "faq.md",
        "api.md",
        "contributing.md",
        "citing.md"
    ]
)

deploydocs(
    repo = "github.com/dojo-sim/Dojo.jl.git",
)
