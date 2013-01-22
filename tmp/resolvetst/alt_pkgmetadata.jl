require("linprog")
require("../../base/git")

module Metadata

using LinProgGLPK

import Git
import GLPK
import Base.isequal, Base.isless, Base.contains, Base.hash

export parse_requires, Version, VersionSet

function packages()
    pkgs = String[]
    open("pkgs.txt") do f
        for l = each_line(f)
            push!(pkgs, chomp(l))
        end
    end
    sort!(pkgs)
    return pkgs
end

type Version
    package::ByteString
    version::VersionNumber
end

isequal(a::Version, b::Version) =
    a.package == b.package && a.version == b.version
function isless(a::Version, b::Version)
    (a.package < b.package) && return true
    (a.package > b.package) && return false
    return a.version < b.version
end

hash(v::Version) = hash([v.(n) for n in Version.names])

function versions(pkgs)
    vers = Version[]
    open("vers.txt") do f
        for l = each_line(f)
            sl = split(l)
            pkg = sl[1]
            ver = convert(VersionNumber, sl[2])
            push!(vers,Version(pkg,ver))
        end
    end
    sort!(vers)
end
versions() = versions(packages())

type VersionSet
    package::ByteString
    versions::Vector{VersionNumber}

    function VersionSet(pkg::ByteString, vers::Vector{VersionNumber})
        if !issorted(vers)
            error("version numbers must be sorted")
        end
        new(pkg,vers)
    end
end
VersionSet(pkg::ByteString) = VersionSet(pkg, VersionNumber[])

isequal(a::VersionSet, b::VersionSet) =
    a.package == b.package && a.versions == b.versions
isless(a::VersionSet, b::VersionSet) = a.package < b.package

function contains(s::VersionSet, v::Version)
    (s.package != v.package) && return false
    for i in length(s.versions):-1:1
        (v.version >= s.versions[i]) && return isodd(i)
    end
    return isempty(s.versions)
end

hash(s::VersionSet) = hash([s.(n) for n in VersionSet.names])

function parse_requires(file::String)
    reqs = VersionSet[]
    open(file) do io
        for line in each_line(io)
            if ismatch(r"^\s*(?:#|$)", line) continue end
            line = replace(line, r"#.*$", "")
            fields = split(line)
            pkg = shift!(fields)
            vers = [ convert(VersionNumber,x) for x=fields ]
            if !issorted(vers)
                error("invalid requires entry for $pkg in $file: $vers")
            end
            # TODO: merge version sets instead of appending?
            push!(reqs,VersionSet(pkg,vers))
        end
    end
    sort!(reqs)
end

function dependencies(pkgs,vers)
    deps = Array((Version,VersionSet),0)
    open("deps.txt") do f
        for l = each_line(f)
            sl = split(l)
            pkg1 = sl[1]
            ver1 = convert(VersionNumber, sl[2])
            v = Version(pkg1, ver1)
            pkg2 = sl[3]
            vers2 = length(sl) > 3 ? [ convert(VersionNumber,x) for x=sl[4:] ] : VersionNumber[]
            d = VersionSet(pkg2, vers2)
            push!(deps,(v,d))
        end
    end
    sort!(deps)
end

older(a::Version, b::Version) = a.package == b.package && a.version < b.version

function verify_sol(x, reqs, pkgs, vers, deps)

    sol = vers[x]
    #print("sol="); showall(sol); println()
    for r in reqs
        pfound = false
        vfound = false
        for s in sol
            if s.package != r.package
                continue
            end
            @assert !pfound
            pfound = true
            @assert contains(r, s)
            vfound = true
        end
        @assert pfound && vfound
    end

    for d in deps
        v = d[1]
        vs = d[2]

        for s in sol
            if s != v
                continue
            end
            found = false
            for s2 in sol
                if contains(vs, s2)
                    found = true
                    break
                end
            end
            @assert found
        end
    end
end

function resolve(reqs::Vector{VersionSet})
    pkgs = packages()
    vers = versions(pkgs)
    deps = dependencies(pkgs,vers)

    n = length(vers)
    z = zeros(Int,n)
    u = ones(Int,n)

    G  = [ v == d[1]        ? 1 : 0  for v=vers, d=deps ]
    G *= [ contains(d[2],v) ? 1 : 0  for d=deps, v=vers ]
    G += [ older(a,b)       ? 2 : 0  for a=vers, b=vers ]
    I = find(G)
    W = zeros(Int,length(I),n)
    for (r,i) in enumerate(I)
        W[r,rem(i-1,n)+1] = -1
        W[r,div(i-1,n)+1] = G[i]
    end
    #mipopts = GLPK.IntoptParam()
    mipopts = GLPK.SimplexParam()
    mipopts["msg_lev"] = GLPK.MSG_ERR
    mipopts["presolve"] = GLPK.ON
    #_, ws, flag, _ = mixintprog(u,W,-ones(Int,length(I)),nothing,nothing,u,nothing,nothing,mipopts)
    #_, ws, flag = linprog_simplex(u,W,-ones(Int,length(I)),nothing,nothing,u,nothing,mipopts)
    _, ws, flag = linprog_exact(u,W,-ones(Int,length(I)),nothing,nothing,u,nothing,mipopts)
    if flag != 0
        msg = sprint(print_linprog_flag, flag)
        error("resolve() failed: $msg.")
    end
    w = iround(ws)


    V = [ p == v.package ? 1 : 0                     for p=pkgs, v=vers ]
    R = [ contains(r,v) ? -1 : 0                     for r=reqs, v=vers ]
    D = [ d[1] == v ? 1 : contains(d[2],v) ? -1 : 0  for d=deps, v=vers ]
    b = [  ones(Int,length(pkgs))
          -ones(Int,length(reqs))
          zeros(Int,length(deps)) ]

    #_, xs, flag, _ = mixintprog(w,[V;R;D],b,nothing,nothing,z,u,nothing,mipopts)
    #_, xs, flag = linprog_simplex(w,[V;R;D],b,nothing,nothing,z,u,mipopts)
    _, xs, flag = linprog_exact(w,[V;R;D],b,nothing,nothing,z,u,mipopts)
    if flag != 0
        msg = sprint(print_linprog_flag, flag)
        error("resolve() failed: $msg.")
    end
    #print("xs="); showall(xs); println();
    x = xs .> 0.5
    #print("x="); showall(x); println();

    verify_sol(x, reqs, pkgs, vers, deps)

    h = (String=>ASCIIString)[]
    for v in vers[x]
        #h[v.package] = readchomp("METADATA/$(v.package)/versions/$(v.version)/sha1")
        h[v.package] = "$(v.version)"
    end
    return h
end

end # module
