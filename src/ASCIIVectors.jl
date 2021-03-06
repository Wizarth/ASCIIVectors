module ASCIIVectors

export ASCIIVector

struct ASCIIVector{T<:AbstractVector{UInt8}}
	val::T
end
# Conversion
ASCIIVector(str::AbstractString) = ASCIIVector(Base.CodeUnits(str))
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
	eltype,
	chomp,
	strip,
	isascii,
	all,
	iscntrl,
	split,
	convert,
	promote_rule,
	size,
	length,
	copy,
	show,
	print,
	parse,
	occursin
	

isempty(v::ASCIIVector) = isempty(v.val)
# The default == implementation doesn't promote, so implement our own
(==)(a::ASCIIVector, b::AbstractArray) = (==)(a.val, b)
(==)(a::AbstractArray, b::ASCIIVector) = (==)(a, b.val)
(==)(a::AbstractString, b::ASCIIVector) = (==)(Base.CodeUnits(a), b)
(==)(a::ASCIIVector, b::AbstractString) = (==)(a, Base.CodeUnits(b))

endswith(v::ASCIIVector, c) = endswith(v.val, c)
firstindex(v::ASCIIVector) = firstindex(v.val)
lastindex(v::ASCIIVector) = lastindex(v.val)
nextind(v::ASCIIVector, i::Int) = nextind(v.val,i)
prevind(v::ASCIIVector, i::Int) = prevind(v.val,i)
keys(v::ASCIIVector) = keys(v.val)
getindex(v::ASCIIVector, i::Int) = getindex(v.val, i)
view(v::ASCIIVector, r) = view(v.val, r)
all(p, v::ASCIIVector) = all(p, v.val)
convert(t::Type{Any}, v::ASCIIVector) = convert(t, v.val)
promote_rule(::Type{ASCIIVector{T}}, t::Type) where {T} = promote_rule(T, t)
size(v::ASCIIVector) = size(v.val)
length(v::ASCIIVector) = length(v.val)
copy(v::ASCIIVector) = ASCIIVector(copy(v.val))
function show(io::IO, v::ASCIIVector)
	write(io, "ASCIIVector(")
	show(io, v.val)
	write(io, ")")
end
function print(io::IO, v::ASCIIVector)
	print(io, String(copy(v.val)))
end
parse(t::Type, v::ASCIIVector) = parse(t, String(copy(v.val)))

# Target for my purposes
#
# eachline   - done
# chomp      - done
# strip      - done
# isascii    - done
# startswith - done
# isempty    - done
# any        - done
# iscntrl    - done
# split	     - done
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
	pos === nothing && return nothing

	eol = findnext(
		isnewline,
		itr.vec, 
		pos
	)
	# No newline found, return to the end of the array
	if eol === nothing
		return (
			ASCIIVector(view(itr.vec, pos:lastindex(itr.vec))),
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
	(ASCIIVector(v), pos)
end

# TODO: This could be calculated, but it would be the same as iterating completely, so...
IteratorSize(::Type{EachLine}) = Base.SizeUnknown()
eltype(::Type{ASCIIVector{T}}) where {T} = SubArray{Uint8,1}

function chomp(v::ASCIIVector) 
	r = view(v.val, :)
	while isnewline(r[end])
		r = @view r[begin:end-1];
	end
	ASCIIVector(r)
end

isspace(c::UInt8) = c == UInt8(' ') || UInt8('\t') <= c <= UInt8('\r')
strip(v::ASCIIVector) = strip(isspace, v)
function strip(pred, v::ASCIIVector)
	isempty(v) && return v
	r = view(v.val, :)
	while pred(r[begin])
		r = @view r[begin+1:end]
		isempty(r) && return ASCIIVector(r)
	end
	while pred(r[end])
		r = @view r[begin:end-1]
		isempty(r) && return ASCIIVector(r)
	end
	ASCIIVector(r)
end

isascii(c::UInt8) = c < 0x80
isascii(v::ASCIIVector) = all(isascii, v)
iscntrl(c::UInt8) = c <= 0x1f || 0x7f <= c <= 0x9f

startswith(v::ASCIIVector, prefix::AbstractString) = startswith(v, Base.CodeUnits(prefix))
startswith(v::ASCIIVector, prefix::AbstractVector{UInt8}) = any((==)(v.val[begin]), prefix)

split(v::ASCIIVector) = split(v, isspace, keepempty=false)
split(v::ASCIIVector, dlm::Char) = split(v, UInt8(dlm))
split(v::ASCIIVector, dlm::UInt8) = split(v, (==)(dlm))
function split(v::ASCIIVector, dlm; keepempty=true)
	r = []
	i = firstindex(v)
	
	next = findnext(
		dlm,
		v.val,
		i
	)
	while next !== nothing
		push!(r, view(v, i:prevind(v.val, next)))
		i = nextind(v.val, next)

		next = findnext(
			dlm,
			v.val,
			i
		)
	end
	push!(r, @view v[i:end])
	if !keepempty
		r = filter(v -> !isempty(v), r)
	end

	return map(ASCIIVector, r)
end

occursin(needle::AbstractString, haystack::ASCIIVector) = occursin(Base.CodeUnits(needle), haystack)
function occursin(needle::AbstractVector{UInt8}, haystack::ASCIIVector)
	matchstart = (==)(needle[begin])
	
	n = findnext(
		matchstart,
		haystack.val,
		firstindex(haystack)
	)
	while n !== nothing
		match = true
		for j in 2:length(needle)
			match &= haystack.val[n+(j-1)] == needle[j]
			match || break
		end
		match && return true
		n = findnext(
			matchstart,
			haystack.val,
			nextind(haystack, n)
		)
	end
	
	return false
end

end # module
