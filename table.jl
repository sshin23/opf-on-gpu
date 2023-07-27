tbl = join((
"""
$(mod(i,5) == 1 ? "\\hline" : "")
$name 
& $(varcon(nvar[i]))
& $(varcon(ncon[i]))
& $(iter[:madnlp_simdiff_gpu][i])$(termination[:madnlp_simdiff_gpu][i])
& $(fmt(adtime[:madnlp_simdiff_gpu][i]))
& $(fmt(lintime[:madnlp_simdiff_gpu][i]))
& $(fmt(soltime[:madnlp_simdiff_gpu][i]))
& $(iter[:madnlp_simdiff_cpu][i])$(termination[:madnlp_simdiff_cpu][i])
& $(fmt(adtime[:madnlp_simdiff_cpu][i]))
& $(fmt(lintime[:madnlp_simdiff_cpu][i]))
& $(fmt(soltime[:madnlp_simdiff_cpu][i]))
& $(iter[:ipopt_ampl][i])$(termination[:ipopt_ampl][i])
& $(fmt(adtime[:ipopt_ampl][i]))
& $(fmt(soltime[:ipopt_ampl][i]))
& $(iter[:ipopt_jump][i])$(termination[:ipopt_jump][i])
& $(fmt(adtime[:ipopt_jump][i]))
& $(fmt(soltime[:ipopt_jump][i]))
"""
        for (i, (name, ~)) in enumerate(all_cases)
), "\\\\\n")


write(
    "result-1.tex",
    replace(
        read("table-1.tex", String),
        "%% data %%" => replace(
            tbl,
            "_" => "\\_"
        )
    )
)

run(`pdflatex result-1.tex`)


tbl = join((
"""
$(mod(i,5) == 1 ? "\\hline" : "")
$name 
& $(efmt(obj[:madnlp_simdiff_gpu][i]))
& $(efmt(cvio[:madnlp_simdiff_gpu][i]))
& $(efmt(obj[:madnlp_simdiff_cpu][i]))
& $(efmt(cvio[:madnlp_simdiff_cpu][i]))
& $(efmt(obj[:ipopt_ampl][i]))
& $(efmt(cvio[:ipopt_ampl][i]))
& $(efmt(obj[:ipopt_jump][i]))
& $(efmt(cvio[:ipopt_jump][i]))
"""
        for (i, (name, ~)) in enumerate(all_cases)
), "\\\\\n")


write(
    "result-2.tex",
    replace(
        read("table-2.tex", String),
        "%% data %%" => replace(
            tbl,
            "_" => "\\_"
        )
    )
)

run(`pdflatex result-2.tex`)
