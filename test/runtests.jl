using Test
using ASCIIVectors

@testset "constructors" begin
	v = [0x61,0x62,0x63,0x21]

	av = ASCIIVector(v)
	@test av == v
	@test v == av

	av = ASCIIVector( view(v, :) )
	@test av == v

	# Convenience string conversion
	av = ASCIIVector("abc!")
	@test av == v
	# Convert Any[] to UInt8[]
	@test isempty(ASCIIVector([]))

	@test isempty(ASCIIVector(UInt8[]))
	@test isempty(ASCIIVector(view(UInt8[], :)))
	@test !isempty(ASCIIVector(v))
	@test !isempty(ASCIIVector(view(v, :)))
end

@testset "eachline" begin
	# map is redundant here because ASCIIVector will convert Char[] down to UInt8[]
	v = b"abc\ndef"
	linesnoeol = [
		b"abc",
		b"def"
	]
	lineswitheol = [
		b"abc\n",
		b"def"
	]
	
	# Doesn't contruct new arrays
	for line in eachline(ASCIIVector(v))
		@test line isa ASCIIVector
	end

	@test collect(eachline(ASCIIVector(v))) == linesnoeol
	@test collect(eachline(ASCIIVector(v), keep=true)) == lineswitheol

	v = b"abc\r\ndef"
	lineswitheol = [
		b"abc\r\n",
		b"def"
	]
	@test collect(eachline(ASCIIVector(v))) == linesnoeol
	@test collect(eachline(ASCIIVector(v), keep=true)) == lineswitheol

	v = b"abc\r\ndef\r\n"
	lineswitheol = [
		b"abc\r\n",
		b"def\r\n"
	]
	@test collect(eachline(ASCIIVector(v))) == linesnoeol
	@test collect(eachline(ASCIIVector(v), keep=true)) == lineswitheol

	# This matches the behavior of eachline under these circumstances
	v = b"a\n\nb"
	linesnoeol = [
		b"a",
		b"",
		b"b"
	]
	lineswitheol = [
		b"a\n",
		b"\n",
		b"b"
	]
	@test collect(eachline(ASCIIVector(v))) == linesnoeol
	@test collect(eachline(ASCIIVector(v), keep=true)) == lineswitheol
end

@testset "chomp" begin
	@test chomp(ASCIIVector("foo\n")).val == ASCIIVector("foo").val
	@test chomp(ASCIIVector("foo\r\n")).val == ASCIIVector("foo").val
end

@testset "strip" begin
	@test strip(ASCIIVector("")).val == ASCIIVector("").val
	@test strip(ASCIIVector(" ")).val == ASCIIVector("").val
	@test strip(ASCIIVector("  ")).val == ASCIIVector("").val
	@test strip(ASCIIVector("   ")).val == ASCIIVector("").val
	@test strip(ASCIIVector("\t  hi  \n")).val == ASCIIVector("hi").val
end

@testset "isasii" begin
	@test isascii(ASCIIVector("abc"))
	@test !isascii(ASCIIVector(b"abc\xff"))
end

@testset "iscntrl" begin
	@test iscntrl('\x01')
	@test !iscntrl('a')
end

@testset "split" begin
	@test split(ASCIIVector("foo,bar,baz"), 'x') == [b"foo,bar,baz"]
	@test split(ASCIIVector("foo,bar,baz"), ',') == [b"foo",b"bar",b"baz"]

	@test split(ASCIIVector(""), ',') == [b""]
	@test split(ASCIIVector(","), ',') == [b"",b""]
	@test split(ASCIIVector(",,"), ',') == [b"",b"",b""]

	@test split(ASCIIVector("a b c")) == [b"a",b"b",b"c"]
	@test split(ASCIIVector("a  b \t c\n")) == [b"a",b"b",b"c"]
end

@testset "startswith" begin
	@test startswith(ASCIIVector("foo"), b"f")
	@test startswith(ASCIIVector("foo"), b"abcdef")
	@test startswith(ASCIIVector("foo"), "f")
	@test startswith(ASCIIVector("foo"), "abcdef")
end
