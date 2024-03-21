using MadNLP, MadNLPHSL, MadNLPGPU, HSL_jll
using ExaModelsExamples
using JuMP, Ipopt, CUDA, AmplNLWriter, NLPModels
using Printf, Plots
using LinearAlgebra

include("opf.jl")

pgfplotsx()

ExaModelsExamples.silence()
CUDA.allowscalar(false);
CUDA.device!(1)

include("utils.jl")
include("cases.jl")
tol=1e-4


all_cases = filter(((n,c),)->
    # endswith(n, "goc") ||
    # endswith(n, "pegase") ||
    endswith(n, "epigrids"), pglib_cases)
ncases = length(all_cases)

# reseults 
soltime = Dict(
    :ipopt_jump => zeros(ncases),
    :ipopt_ampl => zeros(ncases),
    :madnlp_simdiff_gpu => zeros(ncases),
    :madnlp_simdiff_cpu => zeros(ncases)
)

iter = Dict(
    :ipopt_jump => zeros(Int, ncases),
    :ipopt_ampl => zeros(Int, ncases),
    :madnlp_simdiff_gpu => zeros(Int, ncases),
    :madnlp_simdiff_cpu => zeros(Int, ncases)
)

adtime = Dict(
    :ipopt_jump => zeros(ncases),
    :ipopt_ampl => zeros(ncases),
    :madnlp_simdiff_gpu => zeros(ncases),
    :madnlp_simdiff_cpu => zeros(ncases)
)

lintime = Dict(
    :madnlp_simdiff_gpu => zeros(ncases),
    :madnlp_simdiff_cpu => zeros(ncases)
)

inittime = Dict(
    :madnlp_simdiff_gpu => zeros(ncases),
    :madnlp_simdiff_cpu => zeros(ncases)
)

termination = Dict(
    :ipopt_jump => Vector{String}(undef, ncases),
    :ipopt_ampl => Vector{String}(undef, ncases),
    :madnlp_simdiff_gpu => Vector{String}(undef, ncases),
    :madnlp_simdiff_cpu => Vector{String}(undef, ncases)
)

obj = Dict(
    :ipopt_jump => zeros(ncases),
    :ipopt_ampl => zeros(ncases),
    :madnlp_simdiff_gpu => zeros(ncases),
    :madnlp_simdiff_cpu => zeros(ncases)
)

cvio = Dict(
    :ipopt_jump => zeros(ncases),
    :ipopt_ampl => zeros(ncases),
    :madnlp_simdiff_gpu => zeros(ncases),
    :madnlp_simdiff_cpu => zeros(ncases)
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
    m = ExaModelsExamples.ac_power_model(case; backend=CUDABackend())

    result = madnlp(
        m;
        linear_solver=CuCholeskySolver,
        disable_garbage_collector=true,
        tol=tol,
    )
    GC.gc()
    
    tot = result.counters.total_time
    o, c = evaluate(m, result)
    
    iter[:madnlp_simdiff_gpu][i] = result.counters.k
    soltime[:madnlp_simdiff_gpu][i] = tot 
    inittime[:madnlp_simdiff_gpu][i] = result.counters.init_time 
    adtime[:madnlp_simdiff_gpu][i] = result.counters.eval_function_time  
    lintime[:madnlp_simdiff_gpu][i] = result.counters.linear_solver_time  
    termination[:madnlp_simdiff_gpu][i] = termination_code(result.status)
    obj[:madnlp_simdiff_gpu][i] = o
    cvio[:madnlp_simdiff_gpu][i] = c

    # MadNLP (cpu)
    m = ExaModelsExamples.ac_power_model(case)
    result = madnlp(
        m;
        disable_garbage_collector=true,
        linear_solver=Ma27Solver,
    )
    GC.gc()

    nvar[i] = m.meta.nvar
    ncon[i] = m.meta.ncon

    tot = result.counters.total_time
    o, c = evaluate(m, result)
    
    iter[:madnlp_simdiff_cpu][i] = result.counters.k
    soltime[:madnlp_simdiff_cpu][i] = tot 
    inittime[:madnlp_simdiff_cpu][i] = result.counters.init_time 
    adtime[:madnlp_simdiff_cpu][i] = result.counters.eval_function_time  
    lintime[:madnlp_simdiff_cpu][i] = result.counters.linear_solver_time  
    termination[:madnlp_simdiff_cpu][i] = termination_code(result.status)
    obj[:madnlp_simdiff_cpu][i] = o
    cvio[:madnlp_simdiff_cpu][i] = c

    # JuMP
    m = jump_ac_power_model(case)
    set_optimizer(m, Ipopt.Optimizer)
    set_optimizer_attribute(m, "linear_solver", "ma27")
    set_optimizer_attribute(m, "tol", tol)
    set_optimizer_attribute(m, "bound_relax_factor", tol)
    set_optimizer_attribute(m, "output_file", "jump_output")
    set_optimizer_attribute(m, "dual_inf_tol", 10000.0)
    set_optimizer_attribute(m, "constr_viol_tol", 10000.0)
    set_optimizer_attribute(m, "compl_inf_tol", 10000.0)
    set_optimizer_attribute(m, "honor_original_bounds", "no")
    set_optimizer_attribute(m, "print_timing_statistics", "yes")
    optimize!(m)

    it, tot, ad = ipopt_stats("jump_output")
    o, c = evaluate(m)
    
    iter[:ipopt_jump][i] = it
    soltime[:ipopt_jump][i] = tot
    adtime[:ipopt_jump][i] = ad
    termination[:ipopt_jump][i] = termination_code(termination_status(m))
    obj[:ipopt_jump][i] = o
    cvio[:ipopt_jump][i] = c

    # AMPL
    m_ampl = jump_ac_power_model(case)
    set_optimizer(
        m_ampl,
        () -> AmplNLWriter.Optimizer(
            Ipopt.Ipopt_jll.amplexe,
            [
                "linear_solver=ma27",
                "tol=$tol",
                "bound_relax_factor=$tol",
                "output_file=ampl_output",
                "dual_inf_tol=10000.0",
                "constr_viol_tol=10000.0",
                "compl_inf_tol=10000.0",
                "honor_original_bounds=no",
                "print_timing_statistics=yes",
            ]
        )
    )
    optimize!(m_ampl)
    
    it, tot, ad = ipopt_stats("ampl_output")
    o,c = evaluate(m,m_ampl)
    
    iter[:ipopt_ampl][i] = it
    soltime[:ipopt_ampl][i] = tot
    adtime[:ipopt_ampl][i] = ad
    termination[:ipopt_ampl][i] = termination_code(termination_status(m_ampl))
    obj[:ipopt_ampl][i] = o
    cvio[:ipopt_ampl][i] = c
end

# sort results by nvar
p = sortperm(nvar)
permute!(nvar, p)
permute!(ncon, p)
permute!(all_cases, p)
for dict in (iter, lintime, adtime, inittime, soltime, obj, cvio)
    for a in values(dict)
        permute!(a, p)
    end
end


include("table.jl")
include("plot.jl")







