using CartesianGeneticProgramming
using Cambrian
using ArcadeLearningEnvironment
using ArgParse
using GR
import Cambrian.mutate
import Random

```
Playing Atari games using classic CGP on RAM values

If an individual is provided using --ind, an evaluation loop with rendering will
be performed. Otherwise, an evolution is launched. By default this uses seed=0
for each evaluation for a deterministic environment, but this can be removed for
a stochastic and more realistic result.
```

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

function imshowcolor(x::AbstractArray{UInt8,1}, dims)
    clearws()
    setviewport(0, dims[1] / dims[2], 0, 1)
    setwindow(0, 1, 0, 1)
    y = (zeros(UInt32, dims...) .+ 0xff) .<< 24
    img = UInt32.(x)
    @simd for i in 1:length(y)
        @inbounds y[i] += img[3*(i-1)+1] + img[3*(i-1)+2] << 8 + img[3*i] << 16
    end
    drawimage(0, 1, 0, 1, dims..., y)
    updatews()
end

function play_atari(ind::CGPInd, rom_name::String; seed=0, max_frames=18000, render=false)
    ale = ALE_new()
    setInt(ale, "random_seed", Cint(seed))
    #if render
    #    setBool(ale, "display_screen", true)
    #    setBool(ale, "sound", true)
    #end
    loadROM(ale, rom_name)
    actions = getMinimalActionSet(ale)
    reward = 0.0
    frames = 0
    while ~game_over(ale)
        ram = getRAM(ale) ./ typemax(UInt8)
        output = process(ind, ram)
        action = actions[argmax(output)]
        reward += act(ale, action)
        frames += 1
        if frames > max_frames
            break
        end
        if render
            x = getScreenRGB(ale)
            imshowcolor(x, (Int(getScreenWidth(ale)), Int(getScreenHeight(ale))))
        end
    end
    ALE_del(ale)
    [reward]
end

ale = ALE_new()
loadROM(ale, args["game"])
n_in = length(getRAM(ale))
n_out = length(getMinimalActionSet(ale))
ALE_del(ale)

cfg = get_config(args["cfg"]; game=args["game"], n_in=n_in, n_out=n_out)
Random.seed!(args["seed"])

if length(args["ind"]) > 0
    ind = CGPInd(cfg, read(args["ind"], String))
    reward = play_atari(ind, args["game"]; seed=args["seed"], render=true)
    println(reward)
else
    mutate(i::CGPInd) = goldman_mutate(cfg, i)
    fit(i::CGPInd) = play_atari(i, cfg.game)
    e = CGPEvolution(cfg, fit)
    run!(e)
end
