using Test
using ASCIIVectors

@testset "constructors" begin
	v = [0x61,0x62,0x63,0x21]

	av = ASCIIVector(v)
	@test av.val == v
	@test av == v
	@test v == av

	av = ASCIIVector( view(v, :) )
	@test av.val == v
	@test av == v

	@test isempty(ASCIIVector([]))
	@test isempty(ASCIIVector(view([], :)))
	@test !isempty(ASCIIVector(v))
	@test !isempty(ASCIIVector(view(v, :)))
end

@testset "eachline" begin
	# map is redundant here because ASCIIVector will convert Char down to UInt8
	v = ['a', 'b', 'c', '\n', 'd', 'e', 'f']
	linesnoeol = [
		map(UInt8, ['a', 'b', 'c']),
		map(UInt8, ['d', 'e', 'f'])
	]
	lineswitheol = [
		map(UInt8, ['a', 'b', 'c', '\n']),
		map(UInt8, ['d', 'e', 'f'])
	]
	
	@test collect(eachline(ASCIIVector(v))) == linesnoeol
	@test collect(eachline(ASCIIVector(v), keep=true)) == lineswitheol

	v = ['a', 'b', 'c', '\r', '\n', 'd', 'e', 'f']
	lineswitheol = [
		map(UInt8, ['a', 'b', 'c', '\r', '\n']),
		map(UInt8, ['d', 'e', 'f'])
	]
	@test collect(eachline(ASCIIVector(v))) == linesnoeol
	@test collect(eachline(ASCIIVector(v), keep=true)) == lineswitheol

	v = ['a', 'b', 'c', '\r', '\n', 'd', 'e', 'f', '\r', '\n']
	lineswitheol = [
		map(UInt8, ['a', 'b', 'c', '\r', '\n']),
		map(UInt8, ['d', 'e', 'f', '\r', '\n'])
	]
	@test collect(eachline(ASCIIVector(v))) == linesnoeol
	@test collect(eachline(ASCIIVector(v), keep=true)) == lineswitheol

	# This matches the behavior of eachline under these circumstances
	v = [ 'a', '\n', '\n', 'b']
	linesnoeol = [
		[UInt8('a') ],
		[],
		[UInt8('b')]
	]
	lineswitheol = [
		[UInt8('a'), UInt8('\n') ],
		[UInt8('\n')],
		[UInt8('b')]
	]
	@test collect(eachline(ASCIIVector(v))) == linesnoeol
	@test collect(eachline(ASCIIVector(v), keep=true)) == lineswitheol
end
