# opf-on-gpu
This repository stores the scripts for generating the results in "Accelerating Optimal Power Flow: Condensed-Space Interior-Point Methods and Automatic Differentiation on GPUs" by Sungho Shin, Francois Pacaud, and Mihai Anitescu.

## How to run the script?
First, julia v1.9 or higher needs to be installed. We recommend using [juliaup](https://github.com/JuliaLang/juliaup). 

To benchmark with ma27 linear solver, you can additionally install [JuliaHSL](https://www.hsl.rl.ac.uk/hsl2023/index.html). Also, to ensure that AMPL can find the HSL library, make sure that `libhsl.so` can be found from `PATH` environment variable.

The script assumes that your computer has an NVIDIA GPU. 

Once julia is installed, you can instantiate the project to automatically download the dependencies.
```
$ cd path/to/opf-on-gpu
$ julia --project -e 'import Pkg; Pkg.develop("path/to/HSL_jll"); Pkg.instantiate()`
```
Then, the script can run:
```
$ julia -e 'include("example.jl"); include("example.jl")' 
```
Here, we run it twice just to make sure that compilation time is not affecting the timing results.

## Bug reports and support
Please email [@sshin23](https://github.com/sshin23)
