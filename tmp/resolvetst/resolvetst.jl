require("pkg")
reload("alt_pkgmetadata") # overrides Metadata
reload("pkgresolve") # needs reloading after Metadata hijacking

reload("metadatagen.jl")
#reload("metadatagen_R.jl")
println()

# Relevant environment variables:
#  
#  1) RUN_LINPROG : run linear programming
#  2) PKGRESOLVE_DBG : print some debug info
#  3) GENSEED : seed used in generators

function main()
    MetadataGen.generate()

    reqs = Metadata.parse_requires("reqs.txt")
    sort!(reqs)

    ENV["PKGRESOLVE_TEST"] = true

    if get(ENV, "PKGRESOLVE_DBG", "false") == "true"
        println("REQS:")
        for r in reqs
            println("  $(r.package) $(r.versions)")
        end
        println()
    end

    linprog_want = nothing
    if get(ENV, "RUN_LINPROG", "true") == "true"
        println("Running Linear Programming solver")
        println("---------------------------------")
        @time try
            linprog_want = Metadata.resolve(reqs)
        end
    end

    println()
    println("Running MaxSum solver")
    println("---------------------")
    @time maxsum_want = PkgResolve.resolve(reqs)
    println()

    if linprog_want != nothing
        println("linprog_want:")
        println(linprog_want)
        println()
    end

    println("maxsum_want:")
    println(maxsum_want)
    println()

    if linprog_want != nothing && !isequal(maxsum_want, linprog_want)
        warn("RESULTS DIFFER")
    end

    #MetadataGen.clean()
end

main()
