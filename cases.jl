using Pkg.Artifacts
const PGLIB_PATH = joinpath(artifact"PGLib_opf", "pglib-opf-23.07")

pglib_path  = PGLIB_PATH
pglib_cases = map(
    v -> (
        split(split(v, "case")[2], ".")[1],
        joinpath(pglib_path, v)
    ),
    filter(startswith("pglib_opf"), readdir(pglib_path))
)

pglib_api_path = joinpath(pglib_path, "api")
pglib_api_cases = map(
    v -> (
        split(split(v, "case")[2], ".")[1],
        joinpath(pglib_api_path, v)
    ),
    filter(startswith("pglib_opf"), readdir(pglib_api_path))
)

pglib_sad_path = joinpath(pglib_path, "sad")
pglib_sad_cases = map(
    v -> (
        split(split(v, "case")[2], ".")[1],
        joinpath(pglib_sad_path, v)
    ),
    filter(startswith("pglib_opf"), readdir(pglib_sad_path))
)

#ps_test_data_path = ENV["PS_TEST_DATA_PATH"]
#ps_test_data_names = [
#    "ACTIVSg10k"
#    "ACTIVSg2000"
#    "ACTIVSg70k"
#]
#ps_test_data_cases = map(
#    name -> (
#        name,
#        joinpath(ps_test_data_path, name, name * ".m")
#    ),
#    ps_test_data_names
#)
