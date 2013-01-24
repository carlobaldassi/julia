require("../../base/pkg")

module MetadataGen

# Generate packages, versions, dependencies and requirements files
# for use by alt_pkgmetadata.jl
#
# Parses R files Rpackages.txt, Rversions.txt, Rdepends.txt

import Metadata.Version, Metadata.VersionSet
import Metadata.older

import Resolve

export generate, clean

# GENERATION PARAMETERS

rseed = int(get(ENV, "GENSEED", 1)) # random seed

eot = 1000
pgen_new_pkg = 0.05

pbump_major = 0.001
pbump_minor = 0.005
pbump_patch = 0.01
pdont_bump = 1.0 - pbump_major - pbump_minor - pbump_patch
@assert all(0 .<= [pbump_major, pbump_minor, pbump_patch, pdont_bump] .<= 1)

pgen_new_dep = 0.05

pdep_same   = 0.8
pdep_bump   = 0.18
pdep_modify = 0.018
pdep_delete = 1.0 - pdep_same - pdep_bump - pdep_modify
@assert all(0 .<= [pdep_same, pdep_bump, pdep_modify, pdep_delete] .<= 1)

pnewdep_any = 0.3
pnewdep_lb  = 0.3
pnewdep_db  = 1.0 - pnewdep_any - pnewdep_lb
@assert all(0 .<= [pnewdep_any, pnewdep_lb, pnewdep_db] .<= 1)

prequire = 0.05

preq_any = 0.65
preq_lb = 0.3
preq_db = 1.0 - preq_any - preq_lb
@assert all(0 .<= [preq_any, preq_lb, preq_db] .<= 1)

function generate()

    srand(rseed)

    Rpkgs = String[]
    open("Rpackages.txt") do f
        for l = each_line(f)
            push!(Rpkgs, chomp(l))
        end
    end
    sort!(Rpkgs)
    np = length(Rpkgs)

    pvers = [ VersionNumber[] for p0 = 1:np ]
    pdict = (String=>Int)[]
    for p0 = 1:np
        pdict[Rpkgs[p0]] = p0
    end

    Rdeps = [ Int[] for p0 = 1:np ]
    open("Rdepends.txt") do f
        for l = each_line(f)
            sl = split(l)
            pkg0 = sl[1]
            pkg1 = sl[2]
            p0 = pdict[pkg0]
            p1 = pdict[pkg1]
            push!(Rdeps[p0], p1)
        end
    end

    pdeps = [ ((VersionNumber,Int)=>Vector{VersionNumber})[] for p0 = 1:np ]

    function bump_version(vn::Union(VersionNumber,Nothing))
        #TODO consider prerelease and build
        x = rand()
        if vn == nothing
            if x < pgen_new_pkg
                return VersionNumber(0)
            else
                return nothing
            end
        end

        if x < pbump_major
            return VersionNumber(vn.major+1)
        end
        x -= pbump_major
        if x < pbump_minor
            return VersionNumber(vn.major,vn.minor+1)
        end
        x -= pbump_minor
        if x < pbump_patch
            return VersionNumber(vn.major,vn.minor,vn.patch+1)
        end
        #x -= pbump_minor
        return nothing
    end

    function gen_new_dep(p1::Int)
        pvers1 = pvers[p1]
        x = rand()

        if x < pnewdep_any
            return VersionNumber[]
        end
        x -= pnewdep_any
        all_majmin = unique([ [v.major, v.minor] for v in pvers1 ])
        if x < pnewdep_lb
            i = rand(1:length(all_majmin))
            return [VersionNumber(all_majmin[i]...)]
        end
        #x -= pnewdep_lb
        # double bounded
        i = rand(1:length(all_majmin))
        vi = VersionNumber(all_majmin[i]...)
        vj = VersionNumber(vi.major+1)
        return [vi, vj]
    end

    function bump_prev_dep(p1::Int, prev_dep::Vector{VersionNumber})
        pvers1 = pvers[p1]
        all_majmin = unique([ [v.major, v.minor] for v in pvers1 ])
        if isempty(prev_dep)
            i = rand(1:length(all_majmin))
            return [VersionNumber(all_majmin[i]...)]
        elseif isodd(length(prev_dep))
            #println("prev_dep=$prev_dep")
            pd = prev_dep[end]
            maxv = max(pvers1)
            if pd == maxv
                return [pd]
            elseif (pd.major, pd.minor) == (maxv.major, maxv.minor)
                while true
                    i = rand(1:length(pvers1))
                    vi = pvers1[i]
                    if pd < vi
                        return [vi]
                    end
                end
            else
                while true
                    i = rand(1:length(all_majmin))
                    vi = VersionNumber(all_majmin[i]...)
                    if pd < vi
                        return [vi]
                    end
                end
            end
        else
            pd = prev_dep[end-1]
            maxv = max(pvers1)
            if pd == maxv
                return [pd, VersionNumber(pd.major+1)]
            elseif (pd.major, pd.minor) == (maxv.major, maxv.minor)
                while true
                    i = rand(1:length(pvers1))
                    vi = pvers1[i]
                    if pd < vi
                        return [vi, VersionNumber(vi.major+1)]
                    end
                end
            else
                while true
                    i = rand(1:length(all_majmin))
                    vi = VersionNumber(all_majmin[i]...)
                    if pd < vi
                        return [vi, VersionNumber(vi.major+1)]
                    end
                end
            end
        end
    end

    function modify_prev_dep(p1::Int, prev_dep::Vector{VersionNumber})
        # TODO
        return bump_prev_dep(p1, prev_dep)
    end

    function bump_dependencies(p0::Int, prev_vn::Union(Nothing,VersionNumber),
                               p1::Int, deps::Dict{(VersionNumber,Int),Vector{VersionNumber}})
        prev_dep = (prev_vn == nothing) ? nothing : get(deps, (prev_vn,p1), nothing)

        x = rand()
        if prev_dep == nothing
            if x < pgen_new_dep
                return gen_new_dep(p1)
            else
                return nothing
            end
        end

        if x < pdep_same
            return prev_dep
        end
        x -= pdep_same
        if x < pdep_bump
            return bump_prev_dep(p1, prev_dep)
        end
        x -= pdep_bump
        if x < pdep_modify
            return modify_prev_dep(p1, prev_dep)
        end
        #x -= pdep_modify

        # delete dependency
        return nothing
    end

    for t = 1:eot
        print("\rt = $t     ")
        for p0 = 1:np
            pvers0 = pvers[p0]
            cvn = isempty(pvers0) ? nothing : pvers0[end]
            nvn = bump_version(cvn)
            if nvn != nothing
                push!(pvers0, nvn)
                pdeps0 = pdeps[p0]
                Rdeps0 = Rdeps[p0]
                for p1 in Rdeps0
                    if isempty(pvers[p1])
                        continue
                    end
                    new_dep = bump_dependencies(p0, cvn, p1, pdeps0)
                    if new_dep != nothing
                        pdeps0[(nvn,p1)] = new_dep
                    end
                end
            end
        end
    end
    println()

    issane = false
    while !issane
        issane = true

        open("pkgs.txt", "w") do f
            for p0 = 1:np
                if !isempty(pvers[p0])
                    println(f, Rpkgs[p0])
                end
            end
        end

        open("vers.txt", "w") do f
            for p0 = 1:np
                p = Rpkgs[p0]
                for v in pvers[p0]
                    println(f, "$p $v")
                end
            end
        end

        open("deps.txt", "w") do f
            for p0 = 1:np
                p = Rpkgs[p0]
                for (w, vs) in pdeps[p0]
                    vn = w[1]
                    p1 = w[2]
                    dvs = join([string(v) for v in vs], " ")
                    println(f, "$p $vn $(Rpkgs[p1]) $dvs")
                end
            end
        end

        try
            Resolve.sanity_check()
        catch err
            issane = false
            if !isa(err, Resolve.MetadataError)
                rethrow(err)
            end
            ins_vers = [ v for (v,pp) in err.info ]
            for p0 = 1:np
                p = Rpkgs[p0]
                pvers0 = pvers[p0]
                for v0 = length(pvers0):-1:1
                    vn = pvers0[v0]
                    if contains(ins_vers, Version(p, vn))
                        delete!(pvers0, v0)
                    end
                end
                pdeps0 = pdeps[p0]
                for ((vn, p1), vs) in pdeps0
                    if contains(ins_vers, Version(p, vn))
                        delete!(pdeps0, (vn, p1))
                    end
                end
            end
        end
    end

    reqs = Array(VersionSet, 0)
    for p0 = 1:np
        if rand() >= prequire
            continue
        end
        p = Rpkgs[p0]

        x = rand()
        if x < preq_any
            r = VersionSet(p)
            push!(reqs, r)
            continue
        end
        x -= preq_any
        pvers0 = pvers[p0]
        all_majmin = unique([ [v.major, v.minor] for v in pvers0 ])
        if x < preq_lb
            i = rand(1:length(all_majmin))
            vi = VersionNumber(all_majmin[i]...)
            r = VersionSet(p, [vi])
            push!(reqs, r)
            continue
        end
        x -= preq_lb
        # double bounded
        i = rand(1:length(all_majmin))
        vi = VersionNumber(all_majmin[i]...)
        vj = VersionNumber(vi.major+1)
        r = VersionSet(p, [vi, vj])
        push!(reqs, r)
    end

    open("reqs.txt", "w") do f
        for r in reqs
            rvs = join([string(v) for v in r.versions], " ")
            println(f, "$(r.package) $rvs")
        end
    end
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
