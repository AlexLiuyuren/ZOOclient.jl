module ZOOclient

using Base.Dates.now

export Dimension, dim_print
export Objective, get_history_bestsofar
export zoo_min
export Parameter
export Solution, sol_print, sol_equal

export zoolog
export rng, my_precision, set_seed, set_precision

include("ZOOclient/utils/tool_function.jl")
include("ZOOclient/utils/zoo_global.jl")
include("ZOOclient/dimension.jl")
include("ZOOclient/objective.jl")
include("ZOOclient/parameter.jl")
include("ZOOclient/solution.jl")
include("ZOOclient/algos/racos/racos_classification.jl")
include("ZOOclient/algos/racos/racos_common.jl")
include("ZOOclient/algos/racos/racos.jl")
include("ZOOclient/algos/racos/sracos.jl")
include("ZOOclient/algos/racos/racos_optimization.jl")
include("ZOOclient/algos/asracos/asracos.jl")
include("ZOOclient/algos/asracos/asracos_opt.jl")
include("ZOOclient/algos/pposs/pposs_opt.jl")
include("ZOOclient/optimize.jl")

end
