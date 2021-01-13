
r0() = Random.seed!(it.seed)

function ok()
  @testset "ALL" begin 
    _lib(); _some(); _sym() end end

function _lib()
  r0()
  @testset "lib" begin
    @test few("abcdefgh",2) == ['b','c'] 
    @test thing("string") == "string"
    @test thing(11.5) == 11.5
    all = [row for row in csv("data/weather.csv")] 
    @test 5       == length(all[1])
    @test 15      == length(all)
    @test Float64 == typeof(all[2][2]) end end 

function _sym()
  @testset "some" begin
    s=  col(txt="a") 
    @test typeof(s)==Sym
    for i in "aaaabbc" inc!(s,i) end
    @test s.mode == 'a'
    @test s.most == 4 end end 

function _some()
  r0()
  @testset "some" begin
    s=  col(txt="<a") 
    @test typeof(s)==Some
    s.max = 32
    for i in 1:1000 inc!(s,int(100*rand())) end
    lst = all(s)
    @test lst[1] < lst[end]
    @test mid(s,lo=16) == 69
    @test 32.37 < sd(s) < 32.38
    @test s.w == -1
    @test .78 < norm!(s,75) < .79 end end 
````

