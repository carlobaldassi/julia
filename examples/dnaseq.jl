load("packedarray.jl")

bitstype 8 DNABase

convert(::Type{DNABase}, x) = convert(DNABase, uint8(x))
function convert(::Type{DNABase}, x::Uint8)
    if x >= 4; error("invalid DNABase value"); end
    return box(DNABase, x)
end

convert(::Type{Uint8}, g::DNABase) = boxui8(g)
convert(::Type{Int}, g::DNABase) = int(uint8(g))

dnabase(x) = convert(DNABase, x)

(==)(g::DNABase, h::DNABase) = (uint8(g) == uint8(h))

dnaA = dnabase(0x0)
dnaC = dnabase(0x1)
dnaG = dnabase(0x2)
dnaT = dnabase(0x3)

const _jl_char_dnabase_list = ['A', 'C', 'G', 'T']
const _jl_dnabase_list = [dnaA, dnaC, dnaG, dnaT]

function convert(::Type{DNABase}, x::Char)
    for i = 1:length(_jl_char_dnabase_list)
        if x == _jl_char_dnabase_list[i]
            return _jl_dnabase_list[i]
        end
    end
    error("invalid DNABase character $x")
end

convert(::Type{Char}, g::DNABase) = _jl_char_dnabase_list[uint8(g)+1]

(==)(g::DNABase, h::Char) = (char(g) == h)
(==)(g::Char, h::DNABase) = (g == char(h))

zero(::Type{DNABase}) = dnaA

show(io, g::DNABase) = print(io, char(g))

dnabaserand() = dnabase(randi(4)-1)

complement(g::DNABase) = dnabase(0x3 & ~uint8(g))
#const _jl_compl_dnabase_list = ['T', 'G', 'C', 'A']
#complement(g::DNABase) = return _jl_compl_dnabase_list[uint8(g)+1]

typealias DNASeq PackedVector{DNABase, 2}

function dnarand(n::Int)
    s = PackedArray(DNABase, 2, n)
    for i = 1:n
        s[i] = dnabaserand()
    end
    return s
end

write(s, x::DNABase)    = write(s, char(x))
read(s, ::Type{DNABase}) = dnabase(read(s,Char))

function dnaseq_file_write(filename::String, dnaseq::DNASeq)
    f = open(filename, "w")
    write(f, dnaseq)
    close(f)
    return
end

function dnaseq_file_read(filename::String)
    f = open(filename, "r")
    dnaseq = PackedArray(DNABase, 2, 0)
    i = 1
    while true
        try
            push(dnaseq, read(f, DNABase))
        catch
            break
        end
        i += 1
    end
    close(f)
    return dnaseq
end

complement(dnaseq::DNASeq) = map(complement, dnaseq)
#TODO: improve performance
revcomplement(dnaseq::DNASeq) = reverse!(map(complement, dnaseq))

for f in (:(==), :(!=))
    @eval begin
        function ($f)(P::Char, Q::DNASeq)
            F = BitArray(Bool, size(Q))
            for i = 1:numel(Q)
                F[i] = ($f)(P, Q[i])
            end
            return F
        end
        function ($f)(P::DNASeq, Q::Char)
            F = BitArray(Bool, size(P))
            for i = 1:numel(P)
                F[i] = ($f)(P[i], Q)
            end
            return F
        end
    end
end
