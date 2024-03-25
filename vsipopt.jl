using Printf, LinearAlgebra
using ExaModelsExamples
using MadNLP, MadNLPHSL, MadNLPGPU, CUDA
using NLPModelsIpopt
using CairoMakie
using NLPModels
using JuMP

include("opf.jl")


ExaModelsExamples.silence()
CUDA.allowscalar(false);
CUDA.device!(1)

include("utils.jl")
include("cases.jl")
tol=1e-6


all_cases = filter(((n,c),)->
    endswith(n, "goc") ||
    endswith(n, "pegase") ||
    endswith(n, "epigrids"), pglib_cases)
ncases = length(all_cases)

# reseults 
soltime = Dict(
    :madnlp_examodels_gpu => zeros(ncases),
    :ipopt_examodels_cpu => zeros(ncases)
)

iter = Dict(
    :madnlp_examodels_gpu => zeros(Int, ncases),
    :ipopt_examodels_cpu => zeros(Int, ncases)
)

adtime = Dict(
    :madnlp_examodels_gpu => zeros(ncases),
    :ipopt_examodels_cpu => zeros(ncases)
)

lintime = Dict(
    :madnlp_examodels_gpu => zeros(ncases),
    :ipopt_examodels_cpu => zeros(ncases)
)

inittime = Dict(
    :madnlp_examodels_gpu => zeros(ncases),
    :ipopt_examodels_cpu => zeros(ncases)
)

fulltime = Dict(
    :madnlp_examodels_gpu => zeros(ncases),
    :ipopt_examodels_cpu => zeros(ncases)
)

onlinetime = Dict(
    :madnlp_examodels_gpu => zeros(ncases),
    :ipopt_examodels_cpu => zeros(ncases)
)

termination = Dict(
    :madnlp_examodels_gpu => Vector{String}(undef, ncases),
    :ipopt_examodels_cpu => Vector{String}(undef, ncases)
)

obj = Dict(
    :madnlp_examodels_gpu => zeros(ncases),
    :ipopt_examodels_cpu => zeros(ncases)
)

cvio = Dict(
    :madnlp_examodels_gpu => zeros(ncases),
    :ipopt_examodels_cpu => zeros(ncases)
)

nvar = zeros(Int, ncases)
ncon = zeros(Int, ncases)


# run case studies
for (i, (name,case)) in enumerate(all_cases)
    println("""
******************************
* #$i: Solving $name instance 
******************************
""")
    # MadNLP (gpu)
    GC.gc()
    GC.enable(false)
    full = @elapsed begin
        init_time = @elapsed begin
            m = ExaModelsExamples.ac_power_model(case; backend=CUDABackend())
            solver = MadNLPSolver(
                m;
                tol=tol,
                max_iter=500
            )
        end
        online = @elapsed begin
            result = solve!(
				        m, solver
            )
        end
    end
    GC.enable(true)
    GC.gc()
    
    tot = result.counters.total_time
    o, c = evaluate(m, result)
    
    iter[:madnlp_examodels_gpu][i] = result.counters.k
    soltime[:madnlp_examodels_gpu][i] = tot 
    inittime[:madnlp_examodels_gpu][i] = init_time
    adtime[:madnlp_examodels_gpu][i] = result.counters.eval_function_time  
    lintime[:madnlp_examodels_gpu][i] = result.counters.linear_solver_time  
    termination[:madnlp_examodels_gpu][i] = termination_code(result.status)
    obj[:madnlp_examodels_gpu][i] = o
    cvio[:madnlp_examodels_gpu][i] = c
    fulltime[:madnlp_examodels_gpu][i] = full
    onlinetime[:madnlp_examodels_gpu][i] = online

    # Ipopt (cpu)
    GC.gc()
    GC.enable(false)
    full = @elapsed begin
        init_time = @elapsed begin
            m = ExaModelsExamples.ac_power_model(case)
            solver = IpoptSolver(m)
        end

        online = @elapsed begin
            result = solve!(
                solver, m;
                linear_solver="ma27",
                tol = tol,
                output_file = "ipopt_output",
                print_timing_statistics = "yes",
                max_iter=500
            )
        end
    end
    GC.enable(true)
    GC.gc()


    it, tot, ad = ipopt_stats("ipopt_output")
    o, c = evaluate(m, result)
    
    iter[:ipopt_examodels_cpu][i] = it
    soltime[:ipopt_examodels_cpu][i] = tot 
    inittime[:ipopt_examodels_cpu][i] = init_time 
    adtime[:ipopt_examodels_cpu][i] = ad
    lintime[:ipopt_examodels_cpu][i] = tot - ad
    termination[:ipopt_examodels_cpu][i] = termination_code(result.status)
    obj[:ipopt_examodels_cpu][i] = o
    cvio[:ipopt_examodels_cpu][i] = c
    fulltime[:ipopt_examodels_cpu][i] = full
    onlinetime[:ipopt_examodels_cpu][i] = online
    
    nvar[i] = m.meta.nvar
    ncon[i] = m.meta.ncon
end

# sort results by nvar
p = sortperm(nvar)
permute!(nvar, p)
permute!(ncon, p)
permute!(all_cases, p)
for dict in (iter, lintime, adtime, inittime, soltime, obj, cvio, termination)
    for a in values(dict)
        permute!(a, p)
    end
end

include("table.jl")
include("plot.jl")







