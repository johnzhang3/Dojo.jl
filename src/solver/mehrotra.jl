# interior-point solver options
@with_kw mutable struct InteriorPointOptions{T}
    rtol::T = 1.0e-5
    btol::T = 1.0e-5
    ls_scale::T = 0.5
    max_iter::Int = 100
    max_ls::Int = 3
    max_time::T = 1e5
    diff_sol::Bool = false
    reg::Bool = false
    ϵ_min = 0.05 # ∈ [0.005, 0.25]
        # smaller -> faster
        # larger  -> slower, more robust
    breg = 1e-3 # bilinear constraint violation level at which regularization is triggered [1e-3, 1e-4]
    γreg = 1e-1 # regularization scaling parameters ∈ [0, 0.1]:
        # 0   -> faster & ill-conditioned
        # 0.1 -> slower & better-conditioned
        # simulation choose γreg = 0.1
        # MPC choose γreg = 0.0
    undercut::T = 5.0 # the solver will aim at reaching κ_vio = btol / undercut
        # simulation choose undercut = Inf
        # MPC choose undercut = 5.0
    verbose::Bool = false
    warn::Bool = false
end

function mehrotra!(mechanism::Mechanism;
        opts = InteriorPointOptions(
            btol = 1e-6, 
            rtol = 1e-6, 
            undercut = Inf,
			breg = 0.0, max_iter = 40, verbose=true),
        ε = nothing, newtonIter = nothing, lineIter = nothing, warning::Bool = false)


    system = mechanism.system
    eqcs = mechanism.eqconstraints
    bodies = mechanism.bodies
    frics = mechanism.frictions
    ineqcs = mechanism.ineqconstraints

	# @warn "zeroing v2 ω2"
	# for body in bodies
	# 	body.state.vsol[1] *= 0.0
	# 	body.state.ωsol[1] *= 0.0
	# 	body.state.vsol[2] *= 0.0
	# 	body.state.ωsol[2] *= 0.0
	# end

    foreach(resetVars!, ineqcs)
    mechanism.μ = 0.0
	μtarget = 0.0

    # setentries!(mechanism) # compute the residual, maybe not useful
	# @warn "removed init"
	initial_state!.(ineqcs.values)
    setentries!(mechanism) # compute the residual

    bvio = bilinear_violation(mechanism)
    rvio = residual_violation(mechanism)

	println("-----------------------------------------------------------------")
    for n = Base.OneTo(opts.max_iter)

        if opts.verbose
            setentries!(mechanism)
            ##################
            Δvar = norm(full_vector(mechanism.system), Inf)
            fv = full_vector(mechanism.system)
            fM = full_matrix(mechanism.system)
            fΔ = fM \ fv
            Δalt = norm(fΔ, Inf)
            ##################
            res = norm(full_vector(mechanism.system), Inf)
            println("n ", n, "   bvio", scn(bvio), "   rvio", scn(rvio), "   α", scn(mechanism.α),
                    "   μ", scn(μtarget), "   |res|∞", scn(res), "   |Δ|∞", scn(Δvar))
        end

        if (rvio < opts.rtol) && (bvio < opts.btol)
            break
        end
		(n == opts.max_iter) && (@warn "failed mehrotra")
        # Compute regularization level
        # bvio = bilinear_violation(mechanism)
        # reg_val = bvio < opts.breg ? bvio * γreg : 0.0 #useless for now

		mechanism.μ = 0.0

		pullresidual!(mechanism) # store the residual inside mechanism.residual_entries

        GraphBasedSystems.ldu_factorization!(mechanism.system) # factorize system
        pullmatrix!(mechanism)
        GraphBasedSystems.ldu_backsubstitution!(mechanism.system) # solve system

        feasibilityStepLength!(mechanism; τort = 0.95, τsoc = 0.95)
		αaff = copy(mechanism.α)
		centering!(mechanism, mechanism.α)
		σcentering = clamp(mechanism.νaff / (mechanism.ν + 1e-20), 0.0, 1.0)^3

		# Compute corrector residual
		μtarget = max(σcentering * mechanism.ν, opts.btol/opts.undercut)
		mechanism.μ = μtarget

		correction!(mechanism) # update the residual in mechanism.residual_entries
		###############
		mechanism.μ = 0.0
		setentries!(mechanism) # to make sure that the Jacobian is the same as the first one
		pushresidual!(mechanism)

        pushmatrix!(mechanism) # restore matrix
        GraphBasedSystems.ldu_backsubstitution!(mechanism.system) # solve system

		# τ = max(0.95, 1 - max(rvio, bvio)^2)
		τ = 0.95
		# @show "corrector"
		feasibilityStepLength!(mechanism; τort = τ, τsoc = min(τ, 0.95))
		rvio, bvio = lineSearch!(mechanism, rvio, bvio, opts; warning = false)

        foreach(updatesolution!, bodies)
        foreach(updatesolution!, eqcs)
        foreach(updatesolution!, ineqcs)
        foreach(updatesolution!, frics)

        setentries!(mechanism)
    end

    warning && (@info string("newton! did not converge. n = ", newtonIter, ", tol = ", normf(mechanism), "."))
    return
end

function initial_state!(ineqc::InequalityConstraint{T,N,Nc,Cs}) where {T,N,Nc,Cs}
    initial_state_ort!(ineqc.γsol[1], ineqc.ssol[1])
    initial_state_ort!(ineqc.γsol[2], ineqc.ssol[2])
    return nothing
end

function initial_state!(ineqc::InequalityConstraint{T,N,Nc,Cs}) where {T,N,Nc,Cs<:Tuple{ConeBound{T,N}}}
    initial_state_soc!(ineqc.γsol[1], ineqc.ssol[1])
    initial_state_soc!(ineqc.γsol[2], ineqc.ssol[2])
    return nothing
end

function initial_state!(ineqc::InequalityConstraint{T,N,Nc,Cs}) where {T,N,Nc,Cs<:Tuple{ContactBound{T,N}}}
	γort, sort = initial_state_ort(ineqc.γsol[1][1:1], ineqc.ssol[1][1:1])
	γsoc, ssoc = initial_state_soc(ineqc.γsol[1][2:4], ineqc.ssol[1][2:4])
	ineqc.γsol[1] = [γort; γsoc]
	ineqc.ssol[1] = [sort; ssoc]
	γort, sort = initial_state_ort(ineqc.γsol[2][1:1], ineqc.ssol[2][1:1])
	γsoc, ssoc = initial_state_soc(ineqc.γsol[2][2:4], ineqc.ssol[2][2:4])
	ineqc.γsol[2] = [γort; γsoc]
	ineqc.ssol[2] = [sort; ssoc]
    return nothing
end

function initial_state_ort!(γ::AbstractVector{T}, s::AbstractVector{T}; ϵ::T = 1e-20) where {T}
    δs = max(-1.5 * minimum(s), 0)
    δγ = max(-1.5 * minimum(γ), 0)

    sh = s .+ δs
    γh = γ .+ δγ
    δhs = 0.5 * transpose(sh) * γh / (sum(γh) + ϵ)
    δhγ = 0.5 * transpose(sh) * γh / (sum(sh) + ϵ)

    s0 = sh .+ δhs
    γ0 = γh .+ δhγ
    s = s0
    γ = γ0
    return nothing
end

function initial_state_soc!(γ::AbstractVector{T}, s::AbstractVector{T}; ϵ::T = 1e-20) where {T}
    e = [1.0; zeros(length(γ) - 1)] # identity element
    δs = max(-1.5 * (s[1] - norm(s[2:end])), 0)
    δγ = max(-1.5 * (γ[1] - norm(γ[2:end])), 0)

    sh = s + δs * e
    γh = γ + δγ * e
    δhs = 0.5 * transpose(sh) * γh / ((γh[1] + norm(γh[2,end])) + ϵ)
    δhγ = 0.5 * transpose(sh) * γh / ((sh[1] + norm(sh[2,end])) + ϵ)

    s0 = sh + δhs * e
    γ0 = γh + δhγ * e
    s = s0
    γ = γ0
    return nothing
end

function initial_state_ort(γ::AbstractVector{T}, s::AbstractVector{T}; ϵ::T = 1e-20) where {T}
    δs = max(-1.5 * minimum(s), 0)
    δγ = max(-1.5 * minimum(γ), 0)

    sh = s .+ δs
    γh = γ .+ δγ
    δhs = 0.5 * transpose(sh) * γh / (sum(γh) + ϵ)
    δhγ = 0.5 * transpose(sh) * γh / (sum(sh) + ϵ)

    s0 = sh .+ δhs
    γ0 = γh .+ δhγ
	return γ0, s0
end

function initial_state_soc(γ::AbstractVector{T}, s::AbstractVector{T}; ϵ::T = 1e-20) where {T}
    e = [1.0; zeros(length(γ) - 1)] # identity element
    δs = max(-1.5 * (s[1] - norm(s[2:end])), 0)
    δγ = max(-1.5 * (γ[1] - norm(γ[2:end])), 0)

    sh = s + δs * e
    γh = γ + δγ * e
    δhs = 0.5 * transpose(sh) * γh / ((γh[1] + norm(γh[2,end])) + ϵ)
    δhγ = 0.5 * transpose(sh) * γh / ((sh[1] + norm(sh[2,end])) + ϵ)

    s0 = sh + δhs * e
    γ0 = γh + δhγ * e
	return γ0, s0
end

function correction!(mechanism)
	system = mechanism.system
	residual_entries = mechanism.residual_entries

    for id in reverse(system.dfs_list)
        component = getcomponent(mechanism, id)
        correction!(mechanism, residual_entries[id], getentry(system, id), component)
    end
	return
end

@inline function correction!(mechanism::Mechanism, residual_entry::Entry,
		step_entry::Entry, component::Component)
    return
end

@inline function correction!(mechanism::Mechanism, residual_entry::Entry, step_entry::Entry,
		ineqc::InequalityConstraint{T,N,Nc,Cs,N½}) where {T,N,Nc,Cs,N½}
	Δs = step_entry.value[1:N½]
    Δγ = step_entry.value[N½ .+ (1:N½)]
	μ = mechanism.μ
	residual_entry.value += [- Δs .* Δγ .+ μ; szeros(N½)]
    return
end

@inline function correction!(mechanism::Mechanism, residual_entry::Entry, step_entry::Entry,
		ineqc::InequalityConstraint{T,N,Nc,Cs,N½}) where {T,N,Nc,Cs<:Tuple{ConeBound{T,N}},N½}
	cone = ineqc.constraints[1]
	μ = mechanism.μ
	Δs = step_entry.value[1:N½]
    Δγ = step_entry.value[N½ .+ (1:N½)]
	residual_entry.value += [- cone_product(Δs, Δγ) + μ * neutral_vector(cone); szeros(N½)]
    return
end

@inline function correction!(mechanism::Mechanism, residual_entry::Entry, step_entry::Entry,
		ineqc::InequalityConstraint{T,N,Nc,Cs,N½}) where {T,N,Nc,Cs<:Tuple{ContactBound{T,N}},N½}
	cont = ineqc.constraints[1]
	μ = mechanism.μ
	Δs = step_entry.value[1:N½]
    Δγ = step_entry.value[N½ .+ (1:N½)]
	residual_entry.value += [[-Δs[1] * Δγ[1]; -cone_product(Δs[2:4], Δγ[2:4])] + μ * neutral_vector(cont); szeros(N½)]
    return
end

function pullresidual!(mechanism::Mechanism)
	for i in eachindex(mechanism.residual_entries)
		mechanism.residual_entries[i] = deepcopy(mechanism.system.vector_entries[i])
	end
	return
end

function pushresidual!(mechanism::Mechanism)
	for i in eachindex(mechanism.residual_entries)
		mechanism.system.vector_entries[i] = deepcopy(mechanism.residual_entries[i])
	end
	return
end

function pullmatrix!(mechanism::Mechanism)
	mechanism.matrix_entries.nzval .= deepcopy(mechanism.system.matrix_entries.nzval) #TODO: make allocation free
	return
end

function pushmatrix!(mechanism::Mechanism)
	mechanism.system.matrix_entries.nzval .= deepcopy(mechanism.matrix_entries.nzval) #TODO: make allocation free
	return
end

function savediagonalinverses!(mechanism::Mechanism)
	for i in eachindex(mechanism.diagonal_inverses)
		mechanism.diagonal_inverses[i] = deepcopy(mechanism.system.diagonal_inverses[i])
	end
	return
end

function pushdiagonalinverses!(mechanism::Mechanism)
	for i in eachindex(mechanism.diagonal_inverses)
		mechanism.system.diagonal_inverses[i] = deepcopy(mechanism.diagonal_inverses[i])
	end
	return
end
