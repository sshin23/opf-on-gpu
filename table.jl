compile_latex = false

tbl = join((
"""
$(mod(i,5) == 1 ? "\\hline" : "")
$name 
& $(varcon(nvar[i]))
& $(varcon(ncon[i]))
& $(iter[:madnlp_examodels_gpu][i])$(termination[:madnlp_examodels_gpu][i])
& $(fmt(adtime[:madnlp_examodels_gpu][i]))
& $(fmt(lintime[:madnlp_examodels_gpu][i]))
& $(fmt(soltime[:madnlp_examodels_gpu][i]))
& $(iter[:ipopt_examodels_cpu][i])$(termination[:ipopt_examodels_cpu][i])
& $(fmt(adtime[:ipopt_examodels_cpu][i]))
& $(fmt(lintime[:ipopt_examodels_cpu][i]))
& $(fmt(soltime[:ipopt_examodels_cpu][i]))
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

compile_latex && run(`pdflatex result-1.tex`)


tbl = join((
"""
$(mod(i,5) == 1 ? "\\hline" : "")
$name 
& $(efmt(obj[:madnlp_examodels_gpu][i]))
& $(efmt(cvio[:madnlp_examodels_gpu][i]))
& $(efmt(obj[:ipopt_examodels_cpu][i]))
& $(efmt(cvio[:ipopt_examodels_cpu][i]))
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

compile_latex && run(`pdflatex result-2.tex`)
