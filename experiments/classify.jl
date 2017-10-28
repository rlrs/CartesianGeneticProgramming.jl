using CGP
using Logging
#using JLD

function read_data(dfile::String)
    df = open(dfile, "r")
    meta = [parse(split(readline(df), ' ')[2]) for i=1:4]
    data = Float64.(readdlm(dfile, ' ', skipstart=4))
    training = data[1:meta[3], :]
    test = data[meta[3]+(1:meta[4]), :]
    meta[1], meta[2], training', test'
end

function classify(c::Chromosome, data::Array{Float64}, nin::Int64, nout::Int64)
    accuracy = 0
    nsamples = size(data, 2)
    for d in 1:nsamples
        outputs = process(c, data[1:nin, d])
        if indmax(outputs) == indmax(data[nin+(1:nout), d])
            accuracy += 1
        end
    end
    accuracy /= nsamples
    accuracy
end

function regression(c::Chromosome, data::Array{Float64}, nin::Int64, nout::Int64)
    error = 0
    nsamples = size(data, 2)
    for d in 1:nsamples
        outputs = process(c, data[1:nin, d])
        for p in eachindex(outputs)
            error += (outputs[p] - data[nin+p, d])^2
        end
    end
    error /= nsamples
    -error
end

seed = 0
dfile = "data/glass.dt"
log = "log"
fitness = classify
if length(ARGS) > 0; seed = parse(Int64, ARGS[1]); end
if length(ARGS) > 1; dfile = ARGS[2]; end
if length(ARGS) > 2; log = ARGS[3]; end
if length(ARGS) > 3; fitness = eval(parse(ARGS[4])); end

# CGP.Config.init("cfg/base.yaml")
# CGP.Config.init("cfg/classic.yaml")
CGP.Config.init("cfg/test.yaml")

Logging.configure(filename=log, level=INFO)
nin, nout, train, test = read_data(dfile)
fit = x->fitness(x, train, nin, nout)

for ea in CGP.EAs
    dists = CGP.distances[:]
    crosses = CGP.crossovers[:]
    if ea!=cgpneat
        dists = CGP.distances[1:1]
    end
    if ea==oneplus
        crosses = CGP.crossovers[1:1]
    end
    for ct in CGP.CTYPES
        for mut in CGP.mutations
            for cross in crosses
                for dist in dists
                    srand(seed)
                    maxfit, best = ea(ct, nin, nout, fit;
                                      f_mutate=mut, f_crossover=cross,
                                      f_distance=dist, seed=seed)
                end
            end
        end
    end
end
