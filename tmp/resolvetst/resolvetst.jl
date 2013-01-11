require("pkg")
reload("alt_pkgmetadata") # overrides Metadata
reload("pkgresolve") # needs reloading after Metadata hijacking

reload("metadatagen.jl")
println()

function main()
    MetadataGen.generate()

    reqs = Metadata.parse_requires("reqs.txt")
    sort!(reqs)

    ENV["PKGRESOLVE_TEST"] = true

    if has(ENV, "PKGRESOLVE_DBG")
        println("REQS:")
        for r in reqs
            println("  $(r.package) $(r.versions)")
        end
        println()
    end

    println("Running Linear Programming solver")
    println("---------------------------------")
    linprog_want = nothing
    @time try
        linprog_want = Metadata.resolve(reqs)
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

    MetadataGen.clean()
end

main()
