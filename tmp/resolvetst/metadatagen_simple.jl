require("pkg")

module MetadataGen

# Generate packages, versions, dependencies and requirements files
# for use by alt_pkgmetadata.jl

import Metadata.Version, Metadata.VersionSet
import Metadata.older

export generate

# GENERATION PARAMETERS

function gen_pkgs()
    pkgs = ["A", "B"]
    open("pkgs.txt", "w") do f
        for p in pkgs
            println(f, p)
        end
    end
    return pkgs
end

sv(p::String, n::Int) = Version(p, VersionNumber(n))

function gen_vers(pkgs)

    pvers = Vector{Version}[Version[sv("A", 0), sv("A", 1)],
                            Version[sv("B", 0), sv("B", 1)]]

    vers = Version[]
    i = 1
    for pv in pvers, v in pv 
        push!(vers, v)
    end

    open("vers.txt", "w") do f
        for v in vers
            println(f, "$(v.package) $(v.version)")
        end
    end

    return pvers
end

svs(p::String, n::Int...) = VersionSet(p, VersionNumber[VersionNumber(i) for i in [n...]])

function gen_deps(pkgs, pvers)

    #deps = [(sv("A", 0), svs("B", 1)),
            #(sv("A", 1), svs("B", 0, 1))]
    deps = [(sv("B", 0), svs("A", 1)),
            (sv("B", 1), svs("A", 0, 1))]

    open("deps.txt", "w") do f
        for d in deps
            dvs = join([string(v) for v in d[2].versions], " ")
            println(f, "$(d[1].package) $(d[1].version) $(d[2].package) $dvs")
        end
    end

    return deps
end

function gen_reqs(pkgs, pvers)

    reqs = VersionSet[svs("B"), svs("A")]

    open("reqs.txt", "w") do f
        for r in reqs
            rvs = join([string(v) for v in r.versions], " ")
            println(f, "$(r.package) $rvs")
        end
    end

    return reqs
end

function generate()
    pkgs = gen_pkgs()
    pvers = gen_vers(pkgs)
    deps = gen_deps(pkgs, pvers)
    reqs = gen_reqs(pkgs, pvers)
    return
end

function clean()
    rm("pkgs.txt")
    rm("vers.txt")
    rm("deps.txt")
    rm("reqs.txt")
    return
end

end # module
