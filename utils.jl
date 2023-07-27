function ipopt_stats(fname)
    output = read(fname, String)
    iter = parse(Int, split(split(output, "Number of Iterations....:")[2], "\n")[1])
    i = parse(Float64,split(split(output, "Total CPU secs in IPOPT (w/o function evaluations)   =")[2], "\n")[1])
    ad = parse(Float64,split(split(output, "Total CPU secs in NLP function evaluations           =")[2], "\n")[1])
    tot = i + ad
    return iter, tot, ad
end
function varcon(n)
    if n <= 1000
        "$n"
    elseif n <= 1000000'
        @sprintf("%5.1fk", n/1000)
    else
        @sprintf("%5.1fm", n/1000000)
    end
end
fmt(t) = @sprintf("%5.2f", t)
efmt(t) = @sprintf("%1.8e", t)
percent(t) = @sprintf("%5.1f", t * 100) * "\\%"
function termination_code(status::TerminationStatusCode)
    if status == LOCALLY_SOLVED
        return " "
    elseif status == ALMOST_LOCALLY_SOLVED
        return "a"
    elseif status == INFEASIBLE_OR_UNBOUNDED
        return "i"
    else
        return "f"
    end
end

function termination_code(status::MadNLP.Status)
    if status == MadNLP.SOLVE_SUCCEEDED
        return " "
    elseif status == MadNLP.SOLVED_TO_ACCEPTABLE_LEVEL
        return "a"
    elseif status == MadNLP.DIVERGING_ITERATES || status == MadNLP.DIVERGING_ITERATES
        return "i"
    else
        return "f"
    end
end

function evaluate(m::AbstractNLPModel, result)
    constraints = similar(result.solution, m.meta.ncon)
    NLPModels.cons!(m, result.solution, constraints)
    return result.objective, max(
        norm(min.(result.solution .- m.meta.lvar, 0), Inf),
        norm(min.(m.meta.uvar .- result.solution, 0), Inf),
        norm(min.(constraints .- m.meta.lcon, 0), Inf),
        norm(min.(m.meta.ucon .- constraints, 0), Inf)
    )
end

function evaluate(m::JuMP.Model, m2 = nothing)
    if m2!= nothing
        @assert value.(all_variables(m)) == m.moi_backend.optimizer.model.inner.x
        m.moi_backend.optimizer.model.inner.x .= value.(all_variables(m2))
    end
    model = m.moi_backend.optimizer.model
    lvar = model.variables.lower
    uvar = model.variables.upper
    x = model.inner.x
    g = model.inner.g

    model.inner.eval_g(x,g)
    lcon, ucon = copy(model.qp_data.g_L), copy(model.qp_data.g_U)
    for bound in model.nlp_data.constraint_bounds
        push!(lcon, bound.lower)
        push!(ucon, bound.upper)
    end

    return model.inner.eval_f(x), max(
        norm(min.(x .- lvar, 0), Inf),
        norm(min.(uvar .- x, 0), Inf),
        norm(min.(g .- lcon, 0), Inf),
        norm(min.(ucon .- g, 0), Inf)
    )
end

function evaluate(fname::String)
    output = read(fname, String)
    o = parse(Float64, split(split(split(output, "Objective...............:   ")[2], "    ")[2],"\n")[1])
    c = parse(Float64, split(split(split(output, "Constraint violation....:   ")[2], "    ")[2],"\n")[1])
    return o, c
end
