module ASCIIVectors

export ASCIIVector

struct ASCIIVector{T<:AbstractVector{UInt8}}
	val::T
end
# Type deduction from parameter type
ASCIIVector(val::T) where {T<:AbstractVector{UInt8}} = ASCIIVector{T}(val)
# Conversion
function ASCIIVector(str::AbstractString)
	v = UInt8[]
	for c in str
		push!(v,c)
	end
	ASCIIVector(v)	
end
# Any AbstractArray that doesn't meet AbtractVector{UInt8} goes through here
ASCIIVector(val::AbstractArray) = ASCIIVector( convert(Vector{UInt8}, val ) )

import Base: isempty,
	==,
	startswith,
	endswith,
	eachline,
	firstindex,
	lastindex,
	nextind,
	prevind,
	keys,
	getindex,
	IteratorSize,
	iterate,
	view,
	eltype

isempty(v::ASCIIVector) = isempty(v.val)
# TODO: Investigate if it's more correct that ASCIIVector should implement promote, then equality falls out through the default implementation
(==)(a::ASCIIVector, b::AbstractArray) = (==)(a.val, b)
(==)(a::AbstractArray, b::ASCIIVector) = (==)(a, b.val)

startswith(v::ASCIIVector, c) = startswith(v.val, c)
endswith(v::ASCIIVector, c) = endswith(v.val, c)
firstindex(v::ASCIIVector) = firstindex(v.val)
lastindex(v::ASCIIVector) = lastindex(v.val)
nextind(v::ASCIIVector, i::Int) = nextind(v.val,i)
prevind(v::ASCIIVector, i::Int) = prevind(v.val,i)
keys(v::ASCIIVector) = keys(v.val)
getindex(v::ASCIIVector, i::Int) = getindex(v.val, i)
view(v::ASCIIVector, r) = view(v.val, r)

# Target for my purposes
#
# eachline
# chomp
# strip
# isascii
# startswith
# isempty
# any
# iscntrl
# split
# popfirst!
# parse(Float32)
# occursin(::String, ::UInt8)

struct EachLine
	vec::ASCIIVector
	keep::Bool

	EachLine(vec::ASCIIVector, keep::Bool) = new(vec, keep)
end

"""
Returns a structure like Base.EachLine, which can be called with iterate
"""
function eachline(v::ASCIIVector; keep::Bool=false)
	EachLine(v, keep)
end

function isnewline(c)
	c == UInt8('\n') || c == UInt8('\r') 
end
isnotnewline(c) = !isnewline(c)

function iterate(itr::EachLine, pos=findnext(isnotnewline, itr.vec, firstindex(itr.vec)) )
	pos == nothing && return nothing

	eol = findnext(
		isnewline,
		itr.vec, 
		pos
	)
	# No newline found, return to the end of the array
	if eol == nothing
		return (
			view(itr.vec, pos:lastindex(itr.vec)),
			nothing
		)
	end
	# Handle Keep
	if !itr.keep
		eos = prevind(itr.vec, eol)
	end
	# Consume a \r\n pair
	if itr.vec[eol] == UInt8('\r')
		i = nextind(itr.vec, eol)
		if i !== nothing
			if itr.vec[i] == UInt8('\n')
				eol = i
			end
		end
	end
	if itr.keep
		eos = eol
	end
	v = view(itr.vec, pos:eos)
	pos = nextind(itr.vec, eol)
	# If the last character is a newline, don't return an empty array at the end
	if pos > lastindex(itr.vec)
		pos = nothing
	end
	(v, pos)
end

# TODO: This could be calculated, but it would be the same as iterating completely, so...
IteratorSize(::Type{EachLine}) = Base.SizeUnknown()
eltype(::Type{ASCIIVector{T}}) where {T} = typeof(view(T,:))

end # module
