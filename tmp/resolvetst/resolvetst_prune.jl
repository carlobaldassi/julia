reload("alt_pkgmetadata") # overrides Metadata
reload("pkg/resolve") # needs reloading after Metadata hijacking

#reload("metadatagen.jl")
#reload("metadatagen_R.jl")
reload("metadatagen_R-grow.jl")
println()

# Relevant environment variables:
#
#  1) PKGRESOLVE_DBG : print some debug info
#  2) GENSEED : seed used in generators

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

    ENV["PRUNE_VERS"] = false
    println("Running MaxSum solver, no pruning")
    println("---------------------------------")
    @time maxsum_want_nopr = Resolve.resolve(reqs)
    println()


    ENV["PRUNE_VERS"] = true
    println("Running MaxSum solver, with pruning")
    println("-----------------------------------")
    @time maxsum_want = Resolve.resolve(reqs)
    println()

    delete!(ENV, "PRUNE_VERS")

    println("maxsum nopr want:")
    println(maxsum_want_nopr)
    println()

    println("maxsum_want:")
    println(maxsum_want)
    println()

    if !isequal(maxsum_want_nopr, maxsum_want)
        warn("RESULTS DIFFER")
    end
    @assert isequal(maxsum_want_nopr, maxsum_want)

    MetadataGen.clean()
end

main()
