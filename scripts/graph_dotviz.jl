using CartesianGeneticProgramming
using ArgParse
using ArcadeLearningEnvironment
include("../graphing/graph_utils.jl")

s = ArgParseSettings()
@add_arg_table s begin
    "--cfg"
    help = "configuration script"
    default = "cfg/atari_ram.yaml"
    "--game"
    help = "game rom name"
    default = "pong"
    "--seed"
    help = "random seed for evolution"
    arg_type = Int
    default = 0
    "--ind"
    help = "individual for evaluation"
    arg_type = String
    default = ""
end
args = parse_args(ARGS, s)

ale = ALE_new()
loadROM(ale, args["game"])
n_in = length(getRAM(ale))
n_out = length(getMinimalActionSet(ale))
ALE_del(ale)

cfg = get_config(args["cfg"]; game=args["game"], n_in=n_in, n_out=n_out)

ind = CGPInd(cfg, read(args["ind"], String))
dot_array = walk_nodes(ind)
dot_file  = "graph.dot"
open(dot_file, "w") do f
   for i in dot_array
      println(f, i)
   end
end
# to view from commandline:
# $ dot -Tpng graph.dot -o graph.png
# $ display graph.png