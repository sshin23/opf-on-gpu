speedup_sol = soltime[:madnlp_simdiff_cpu] ./ soltime[:madnlp_simdiff_gpu]
speedup_ad  = adtime[:madnlp_simdiff_cpu]  ./ adtime[:madnlp_simdiff_gpu]
speedup_lin = lintime[:madnlp_simdiff_cpu] ./ lintime[:madnlp_simdiff_gpu]
speedup_internal = (
    soltime[:madnlp_simdiff_cpu] - adtime[:madnlp_simdiff_cpu] - lintime[:madnlp_simdiff_cpu]
) ./ (
    soltime[:madnlp_simdiff_gpu] - adtime[:madnlp_simdiff_gpu] - lintime[:madnlp_simdiff_gpu]
)

p1 = plot(
    ;
    xlim = (minimum(nvar), maximum(nvar)),
    ylim = (
        .5 * min(
            minimum(speedup_sol),
            minimum(speedup_ad),
            minimum(speedup_lin),
            minimum(speedup_internal)
        ),
        2 * max(
            maximum(speedup_sol),
            maximum(speedup_ad),
            maximum(speedup_lin),
            maximum(speedup_internal)
        )
    ),
    framestyle = :box,
    xscale = :log10,
    yscale = :log10,
    xlabel = "number of variables",
    ylabel = "speedup",
    fontfamily = "Times",
    legend= :topleft,
    size=(500,300)
);
scatter!(
    p1,
    nvar,
    speedup_sol;
    label = "total solution",
    marker = :circle,
    markeralpha = 0.0,
    markerstrokealpha = 1,
);
scatter!(
    p1,
    nvar,
    speedup_ad;
    label = "derivative evaluation",
    marker = :rect,
    markeralpha = 0.0,
    markerstrokealpha = 1,
);
scatter!(
    p1,
    nvar,
    speedup_lin;
    label = "linear solver",
    marker = :diamond,
    markeralpha = 0.0,
    markerstrokealpha = 1,
);
scatter!(
    p1,
    nvar,
    speedup_internal;
    label = "solver internal",
    marker = :star5,
    markeralpha = 0.0,
    markerstrokealpha = 1,
);
hline!(
    p1,
    [1];
    color = :gray,
    label = nothing
);

savefig(p1, "speedup-sol.pdf")
