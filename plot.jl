speedup_sol = soltime[:ipopt_examodels_cpu] ./ soltime[:madnlp_examodels_gpu]
speedup_ad  = adtime[:ipopt_examodels_cpu]  ./ adtime[:madnlp_examodels_gpu]
speedup_lin = lintime[:ipopt_examodels_cpu] ./ lintime[:madnlp_examodels_gpu]
speedup_internal = (
    soltime[:ipopt_examodels_cpu] - adtime[:ipopt_examodels_cpu] - lintime[:ipopt_examodels_cpu]
) ./ (
    soltime[:madnlp_examodels_gpu] - adtime[:madnlp_examodels_gpu] - lintime[:madnlp_examodels_gpu]
)

f = Figure(size=(500,300))
ax = Axis(
    f[1, 1],
    xscale = log10,
    yscale = log10,
    xlabel = "number of variables",
    ylabel = "speedup",
);
Makie.scatter!(
    ax,
    nvar,
    speedup_sol;
    label = "total solution",
    marker = :circle,
    markeralpha = 0.0,
    markerstrokealpha = 1,
);
Makie.scatter!(
    ax,
    nvar,
    speedup_ad;
    label = "derivative evaluation",
    marker = :rect,
    markeralpha = 0.0,
    markerstrokealpha = 1,
);
Makie.scatter!(
    ax,
    nvar,
    speedup_lin;
    label = "linear solver",
    marker = :diamond,
    markeralpha = 0.0,
    markerstrokealpha = 1,
);
Makie.scatter!(
    ax,
    nvar,
    speedup_internal;
    label = "solver internal",
    marker = :star5,
    markeralpha = 0.0,
    markerstrokealpha = 1,
);
Makie.hlines!(
    ax,
    [1];
    color = :gray,
    label = nothing
);

axislegend(position = :lt)
save("speedup-sol.pdf", f)
