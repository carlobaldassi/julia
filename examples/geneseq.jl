load("packedarray.jl")

bitstype 8 GBase

convert(::Type{GBase}, x) = convert(GBase, uint8(x))
function convert(::Type{GBase}, x::Uint8)
    if x >= 4; error("invalid GBase value"); end
    z = Array(Uint8,1)
    z[1] = x
    y = reinterpret(GBase, z)
    return y[1]
end

convert(::Type{Uint8}, g::GBase) = boxui8(unbox8(g))
convert(::Type{Int}, g::GBase) = int(uint8(g))

gbase(x) = convert(GBase, x)

(==)(g::GBase, h::GBase) = (uint8(g) == uint8(h))

gA = gbase(0x0)
gC = gbase(0x1)
gG = gbase(0x2)
gT = gbase(0x3)

function convert(::Type{GBase}, x::Char)
    if x == 'A'
        return gA
    elseif x == 'C'
        return gC
    elseif x == 'G'
        return gG
    elseif x == 'T'
        return gT
    else
        error("invalid GBase character $x")
    end
end

function convert(::Type{Char}, g::GBase)
    if g == gA
        return 'A'
    elseif g == gC
        return 'C'
    elseif g == gG
        return 'G'
    elseif g == gT
        return 'T'
    end
end

(==)(g::GBase, h::Char) = (char(g) == h)
(==)(g::Char, h::GBase) = (g == char(h))

zero(::Type{GBase}) = gA

show(io, g::GBase) = print(io, char(g))

gbaserand() = gbase(randi(4)-1)

function complement(g::GBase)
    if g == gA
        return 'T'
    elseif g == gC
        return 'G'
    elseif g == gG
        return 'C'
    elseif g == gT
        return 'A'
    end
end

typealias GeneSeq PackedVector{GBase, 2}

function generand(n::Int)
    s = PackedArray(GBase, 2, n)
    for i = 1:n
        s[i] = gbaserand()
    end
    return s
end

write(s, x::GBase)    = write(s, char(x))
read(s, ::Type{GBase}) = gbase(read(s,Char))

function geneseq_file_write(filename::String, geneseq::GeneSeq)
    f = open(filename, "w")
    write(f, geneseq)
    close(f)
    return
end

function geneseq_file_read(filename::String)
    f = open(filename, "r")
    geneseq = PackedArray(GBase, 2, 0)
    i = 1
    while true
        try
            push(geneseq, read(f, GBase))
        catch
            break
        end
        i += 1
    end
    close(f)
    return geneseq
end

complement(geneseq::GeneSeq) = map(complement, geneseq)

for f in (:(==), :(!=))
    @eval begin
        function ($f)(P::Char, Q::GeneSeq)
            F = BitArray(Bool, size(Q))
            for i = 1:numel(Q)
                F[i] = ($f)(P, Q[i])
            end
            return F
        end
        function ($f)(P::GeneSeq, Q::Char)
            F = BitArray(Bool, size(P))
            for i = 1:numel(P)
                F[i] = ($f)(P[i], Q)
            end
            return F
        end
    end
end
