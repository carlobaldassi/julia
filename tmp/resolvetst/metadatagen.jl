require("pkg")

module MetadataGen

# Generate packages, versions, dependencies and requirements files
# for use by alt_pkgmetadata.jl
#
# Currently generates graphs as follows:
#  1) generates a number of packages
#  2) generates a number of versions for each packages, between 1 and maxver (uniformly distributed)
#  3) generates dependencies:
#     a) for each pair of packages, puts a link with some probability
#     b) if the link is set, a direction is chosen randomly
#     c) for each version of the dependant, a VersionSet is generated for the dependence, either
#        "any" or "at least vXXX" or "between versions vXXX and vYYY"
#  4) generates requirements (each package is required with some probability, the VersionSet is
#     generated as for dependencies)
#

import Metadata.Version, Metadata.VersionSet
import Metadata.older

export generate

# GENERATION PARAMETERS

rseed = int(get(ENV, "GENSEED", 1)) # random seed
pkgn = 100                   # number of packages (remember to modify gen_pkgs "%04d" if more than 9999")
maxver = 20                  # maximum version number (currently only major versions)
linkprob = 0.01              # probability of linking any two packages
reqprob = 0.1                # probability that a package is required
proballv = 0.5               # probability that a VersionSet includes all versions
problb = proballv + 0.3      # (cumulative) probability that a VersionSet is lower bounded
probdb = problb + 0.15       # (cumulative) probability that a VersionSet is double bounded
                             # more complex schemes are unimplemented

function gen_pkgs()
    num2nam(i) = @sprintf("%04d", i) | map(i->'A'+parse_int(string(i)))
    pkgs = ASCIIString[num2nam(i) for i = 0:pkgn-1]
    open("pkgs.txt", "w") do f
        for p in pkgs
            println(f, p)
        end
    end
    return pkgs
end

function gen_vers(pkgs)

    srand(rseed)

    vern = [ randi(maxver) for i = 1:pkgn ]
    totvern = sum(vern)
    pvers = [ Version[] for i = 1:pkgn ]
    vers = Array(Version, totvern)
    i = 1
    for p = 1:pkgn, v = 1:vern[p]
        ver = Version(pkgs[p], VersionNumber(v-1))
        vers[i] = ver
        push!(pvers[p], ver)
        i += 1
    end

    open("vers.txt", "w") do f
        for v in vers
            println(f, "$(v.package) $(v.version)")
        end
    end

    return pvers
end

function gen_deps(pkgs, pvers)

    vern = map(length, pvers)
    deps = Array((Version,VersionSet),0)
    for p1 = 1:pkgn, p2 = p1+1:pkgn
        if rand() >= linkprob
            continue
        end
        if randi(2) == 1
            j1, j2 = p1, p2
        else
            j1, j2 = p2, p1
        end

        pkg2 = pkgs[j2]

        for v = 1:vern[j1]
            ver1 = pvers[j1][v]
            x = rand()
            if x < proballv
                d = (ver1, VersionSet(pkg2))
            elseif x < problb || vern[j2] == 1
                lb2 = randi(vern[j2])
                vlb2 = pvers[j2][lb2].version
                d = (ver1, VersionSet(pkg2, VersionNumber[vlb2]))
            elseif x < probdb || vern[j2] == 2
                lb2 = randi(vern[j2]-1)
                ub2 = lb2 + randi(vern[j2]-lb2)
                vlb2 = pvers[j2][lb2].version
                vub2 = pvers[j2][ub2].version
                d = (ver1, VersionSet(pkg2, VersionNumber[vlb2, vub2]))
            else
                #TODO
                d = (ver1, VersionSet(pkg2))
            end
            push!(deps, d)
        end
    end

    open("deps.txt", "w") do f
        for d in deps
            dvs = join([string(v) for v in d[2].versions], " ")
            println(f, "$(d[1].package) $(d[1].version) $(d[2].package) $dvs")
        end
    end

    return deps
end

function gen_reqs(pkgs, pvers)

    vern = map(length, pvers)
    reqs = Array(VersionSet, 0)
    for p = 1:pkgn
        if rand() >= reqprob
            continue
        end
        pkg = pkgs[p]

        x = rand()
        if x < proballv
            r = VersionSet(pkg)
        elseif x < problb || vern[p] == 1
            lb = randi(vern[p])
            vlb = pvers[p][lb].version
            r = VersionSet(pkg, VersionNumber[vlb])
        elseif x < probdb || vern[p] == 2
            lb = randi(vern[p]-1)
            ub = lb + randi(vern[p]-lb)
            vlb = pvers[p][lb].version
            vub = pvers[p][ub].version
            r = VersionSet(pkg, VersionNumber[vlb, vub])
        else
            #TODO
            r = VersionSet(pkg)
        end
        push!(reqs, r)
    end

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
