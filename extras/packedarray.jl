load("bitarray.jl")

type PackedArray{T, B, N} <: AbstractArray{T, N}
    bits::Array{BitArray{Int,N},1}
    dims::Vector{Int}
    function PackedArray(dims::Int...)
        if !isa(T, BitsKind)
            error("PackedArrays are only available for BitKinds types")
        end
        if length(dims) == 0
            dims = 0
        end
        bits = Array(BitArray{Int,N}, B)
        for i = 1:B
            bits[i] = BitArray(Int, dims)
        end
        return new(bits, [i::Int for i in dims])
    end
end

PackedArray{T}(::Type{T}, B::Integer, dims::Dims) = PackedArray{T, B, max(length(dims), 1)}(dims...)
PackedArray{T}(::Type{T}, B::Integer, dims::Int...) = PackedArray{T, B, max(length(dims), 1)}(dims...)

typealias PackedVector{T,B} PackedArray{T,B,1}
typealias PackedMatrix{T,B} PackedArray{T,B,2}

## utility functions ##

length(P::PackedArray) = prod(P.dims)
eltype{T}(P::PackedArray{T}) = T
ndims{T,B,N}(P::PackedArray{T,B,N}) = N
numel(P::PackedArray) = prod(P.dims)
size(P::PackedArray) = tuple(P.dims...)

packsize{T,B}(P::PackedArray{T,B}) = B

similar{T,B}(P::PackedArray{T,B}) = PackedArray(T, B, P.dims...)
similar{R,S,B}(P::PackedArray{R,B}, T::Type{S}, dims::Dims) = PackedArray(T, B, dims)

_jl_pkget(x, i::Int) = (int(x) >>> (i-1)) & 1

function fill!{T, B}(P::PackedArray{T, B}, x)
    y = convert(T, x)
    for i = 1:B
        fill!(P.bits[i], _jl_pkget(y, i))
    end
    return P
end

# disambiguation
# (this is going to throw an error anyway)
fill(P::PackedArray, x::(Int64...,)) = error("wrong syntax")
# end disambiguation
fill{T}(P::PackedArray{T}, x::Integer) = fill!(similar(P), x)
fill{T}(P::PackedArray{T}, x) = fill!(similar(P), x)

packedzeros{T}(::Type{T}, B::Int, args...) = fill!(PackedArray(T, B, args...), zero(T))
packedones{T}(::Type{T}, B::Int, args...) = fill!(PackedArray(T, B, args...), one(T))

function reshape{T,B,N}(P::BitArray{T}, dims::NTuple{N,Int})
    if prod(dims) != numel(P)
        error("reshape: invalid dimensions")
    end
    Pr = PackedArray{T,B,N}()
    for j = 1:B
        Pr.bits[j] = reshape(P.bits[j], dims)
    end
    Pr.dims = [i::Int for i in dims]
    return Pr
end

function ref{T,B}(P::PackedArray{T,B}, i::Integer)
    if i < 1 || i > length(P)
        throw(BoundsError())
    end
    x = 0
    for j = 1:B
        x |= P.bits[j][i] << (j-1)
    end
    return convert(T, x)
end

# 0d packedarray
ref{T,B}(P::PackedArray{T,B,0}) = P[1]

ref(P::PackedArray, i0::Integer, i1::Integer) = P[i0 + size(P,1)*(i1-1)]
ref(P::PackedArray, i0::Integer, i1::Integer, i2::Integer) =
    P[i0 + size(P,1)*((i1-1) + size(P,2)*(i2-1))]
ref(P::PackedArray, i0::Integer, i1::Integer, i2::Integer, i3::Integer) =
    P[i0 + size(P,1)*((i1-1) + size(P,2)*((i2-1) + size(P,3)*(i3-1)))]

function ref{T,B}(P::PackedArray{T,B}, I::Integer...)
    ndims = length(I)
    index = I[1]
    stride = 1
    for k=2:ndims
        stride *= size(P, k - 1)
        index += (I[k] - 1) * stride
    end
    return P[index]
end

function assign{T,B}(P::PackedArray{T,B}, x, i::Integer)
    if i < 1 || i > length(P)
        throw(BoundsError())
    end
    y = convert(T, x)
    for j = 1:B
        P.bits[j][i] = _jl_pkget(y, j)
    end
    return P
end

assign(P::PackedArray, x, i0::Integer, i1::Integer) =
    P[i0 + size(P,1)*(i1-1)] = x

assign(P::PackedArray, x, i0::Integer, i1::Integer, i2::Integer) =
    P[i0 + size(P,1)*((i1-1) + size(P,2)*(i2-1))] = x

assign(P::PackedArray, x, i0::Integer, i1::Integer, i2::Integer, i3::Integer) =
    P[i0 + size(P,1)*((i1-1) + size(P,2)*((i2-1) + size(P,3)*(i3-1)))] = x

function assign{T,B}(P::PackedArray{T,B}, x, I0::Integer, I::Integer...)
    index = I0
    stride = 1
    for k = 1:length(I)
        stride = stride * size(P, k)
        index += (I[k] - 1) * stride
    end
    P[index] = x
    return P
end

function push{T,B}(P::PackedVector{T,B}, item)
    item = convert(T, item)
    for j = 1:B
        push(P.bits[j], _jl_pkget(item, j))
    end
    P.dims[1] += 1
    return P
end


function append!{T,B}(P::PackedVector{T,B}, items::PackedVector{T,B})
    n0 = length(P)
    n1 = length(items)
    if n1 == 0
        return P
    end
    for j=1:B
        append!(P.bits[j], items.bits[j])
    end
    P.dims[1] += n1
    return P
end

function grow{T,B}(P::PackedVector{T,B}, n::Integer)
    n0 = length(P)
    for j=1:B
        grow(P.bits[j], n)
    end
    P.dims[1] += n
    return P
end

function pop{T,B}(P::PackedVector{T,B})
    if isempty(P)
        error("pop: packedarray is empty")
    end
    x = 0
    for j = 1:B
        x |= pop(P.bits[j]) << (j-1)
    end
    P.dims[1] -= 1
    return convert(T, x)
end

function enqueue{T,B}(P::PackedVector{T,B}, item)
    item = convert(T, item)
    for j = 1:B
        enqueue(P.bits[j], _jl_pkget(item, j))
    end
    P.dims[1] += 1
    return P
end

function shift{T,B}(P::PackedVector{T,B})
    if isempty(P)
        error("shift: packedarray is empty")
    end
    item = P[1]
    x = 0
    for j = 1:B
        x |= shift(P.bits[j]) << (j-1)
    end
    P.dims[1] -= 1
    return convert(T, x)
end

function insert{T,B}(P::PackedVector{T,B}, i::Integer, item)
    if i < 1
        throw(BoundsError())
    end
    item = convert(T, item)
    n = length(P)
    if i > n
        x = packedzeros(T, B, i - n)
        append!(P, x)
    else
        for j = 1:B
            insert(P.bits[j], i, _jl_pkget(item, j))
        end
        P.dims[1] += 1
    end
    return item
end

function del{T,B}(P::PackedVector{T,B}, i::Integer)
    n = length(P)
    if !(1 <= i <= n)
        throw(BoundsError())
    end

    for j = 1:B
        del(P.bits[j], i)
    end
    P.dims[1] -= 1

    return P
end

function del{T,B}(P::PackedVector{T,B}, r::Range1{Int})
    n = length(P)
    i_f = first(r)
    i_l = last(r)
    if !(1 <= i_f && i_l <= n)
        throw(BoundsError())
    end
    if i_l < i_f
        return P
    end
    for j = 1:B
        del(P.bits[j], r)
    end
    P.dims[1] -= i_l - i_f + 1
    return P
end

function del_all{T,B}(P::PackedVector{T,B})
    for j = 1:B
        del_all(P.bits[j])
    end
    P.dims[1] = 0
    return P
end

# note: these return BitArray{Bool}
for f in (:(==), :(!=))
    @eval begin
        function ($f)(P::PackedArray, Q::PackedArray)
            F = BitArray(Bool, promote_shape(size(P),size(Q)))
            for i = 1:numel(F)
                F[i] = ($f)(P[i], Q[i])
            end
            return F
        end
        ($f){T<:BitArray}(P::T, Q::PackedArray{T}) = error("")
        function ($f){T}(P::T, Q::PackedArray{T})
            F = BitArray(Bool, size(Q))
            for i = 1:numel(Q)
                F[i] = ($f)(P, Q[i])
            end
            return F
        end
        ($f){T<:BitArray}(P::PackedArray{T}, Q::T) = error("")
        function ($f){T}(P::PackedArray{T}, Q::T)
            F = BitArray(Bool, size(P))
            for i = 1:numel(P)
                F[i] = ($f)(P[i], Q)
            end
            return F
        end
    end
end

function map{T,B}(f, P::PackedArray{T,B})
    if isempty(P); return P; end
    Q = similar(P)
    for i = 1:length(P)
        Q[i] = f(P[i])
    end
    return Q
end

function reverse!{T,B}(P::PackedVector{T,B})
    for j = 1:B
        reverse!(P.bits[j])
    end
    return P
end

reverse(P::PackedVector) = reverse!(copy(P))

function nnz{T,B}(P::PackedArray{T,B})
    x = bitzeros(Int, P.dims...)
    for j = 1:B
        x |= P.bits[j]
    end
    return nnz(x)
end

function find{T}(P::PackedArray{T})
    nnzB = nnz(P)
    I = Array(Int, nnzB)
    count = 1
    for i = 1:length(P)
        if P[i] != zero(T)
            I[count] = i
            count += 1
        end
    end
    return I
end

findn(P::PackedVector) = find(P)

function findn{T}(P::PackedMatrix{T})
    nnzP = nnz(P)
    I = Array(Int, nnzP)
    J = Array(Int, nnzP)
    count = 1
    for j=1:size(P,2), i=1:size(P,1)
        if P[i,j] != zero(T)
            I[count] = i
            J[count] = j
            count += 1
        end
    end
    return (I, J)
end

function hcat{T,B}(P::PackedVector{T,B}...)
    height = length(P[1])
    width = length(P)
    for j = 2:width
        if length(P[j]) != height; error("hcat: mismatched dimensions"); end
    end
    M = PackedArray(T, B, 1, 1)
    for j = 1:B
        M.bits[j] = hcat(map(x->x.bits[j],P)...)
    end
    M.dims = [height, length(P)]
    return M
end

function vcat{T,B}(P::PackedVector{T,B}...)
    n = 0
    for Pk in P
        n += length(Pk)
    end
    Q = PackedArray(T, B, 1)
    for j = 1:B
        Q.bits[j] = vcat(map(x->x.bits[j],P)...)
    end
    Q.dims = [n]
    return Q
end

function hcat{T,B}(A::Union(PackedMatrix{T,B},PackedVector{T,B})...)
    nargs = length(A)
    nrows = size(A[1], 1)
    ncols = 0
    dense = true
    for j = 1:nargs
        Aj = A[j]
        nd = ndims(Aj)
        ncols += (nd==2 ? size(Aj,2) : 1)
        if size(Aj, 1) != nrows; error("hcat: mismatched dimensions"); end
    end

    P = PackedArray(T, B, nrows, ncols)
    for j = 1:B
        P.bits[j] = hcat(map(x->x.bits[j],A)...)
    end
    P.dims = [nrows, ncols]
    return P
end

function vcat{T,B}(A::PackedMatrix{T,B}...)
    nargs = length(A)
    nrows = sum(a->size(a, 1), A)::Int
    ncols = size(A[1], 2)
    for j = 2:nargs
        if size(A[j], 2) != ncols; error("vcat: mismatched dimensions"); end
    end
    P = PackedArray(T, B, 1, 1)
    for j = 1:B
        P.bits[j] = vcat(map(x->x.bits[j],A)...)
    end
    P.dims = [nrows, ncols]
    return P
end

function isequal{T,B}(P::PackedArray{T,B}, Q::PackedArray{T,B})
    if size(P) != size(Q)
        return false
    end
    for j = 1:B
        if !isequal(P.bits[j], Q.bits[j])
            return false
        end
    end
    return true
end
