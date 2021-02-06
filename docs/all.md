

# all.jl

using Test
using Random
using Parameters
using ResumableFunctions

no = nothing

@with_kw mutable struct It
  char = (skip='?',less='<',more='>',num='$',klass='!') 
  str  = (skip="?") 
  some = (max=32,bins=.5, cohen=0.3, trivial=1.05) 
  seed = 1
end

it=It()

Random.seed!(it.seed)

A file of miscellaneous utilities.
## Meta

```julia
same(s) = s        
```

## Maths
`int`: Round numbers   
`any,few`: Pull one or `n` things from a list (at random) 

```julia
int(x)  = floor(Int,x)
any(a)  = a[ int(length(a) * rand()) + 1]
few(a,n=it.divs.few)=length(a)<n ? a : [any(a) for _ in 1:n]
```

## Strings
`thing`: coerce things to floats or strings   
`say,sayln`: print a struct, maybe with a trailing new line.

```julia
thing(x) = try parse(Float64,x) catch _ x end

sayln(i) = begin ay(i); println("") end

function say(i)
  fields(x) = fieldnames(typeof(x))
  s, pre="$(typeof(i)){", ""
  for f in sort!([x for x in fields(i) if !("$x"[1] == '_')])
    s = s * pre * "$f=$getfield(i,f)"
    pre=", " end
  print(s * "}") end
```

## Files
`csv`: interate over a fiile

```julia
@resumable function csv(file;zap=r"(\s+|#.*)")
  b4=""
  for line in eachline(file)
    line = replace(line,zap =>"")
    if length(line) != 0
      if line[end] == ',' # if line ends with ",",
        b4 = b4 * line    # join it to next
      else
        @yield [thing(x) for x in split(b4*line,",")]
                b4 = "" end end end end  
```

vim: set et ts=2 sw=2:

```julia
@with_kw mutable struct Some
  pos=0; txt=""; w=1; n=0; 
  _all=[]; max=it.some.max; stale=false end

@with_kw mutable struct Sym
  pos=0; txt=""; w=1; n=0; 
  seen=Dict(); mode=no; most=0 end

#---- Create -----------------------------------------------
function col(;txt="",pos=0, c=it.char)
  x= c.less in txt||c.more in txt||c.num in txt ? Some : Sym  
  w= it.char.less in txt ? -1 : 1
  x(txt=txt, pos=pos, w=w) end

#---- Update -----------------------------------------------
inc!(i,x)=
  x==it.char.skip ? x : begin i.n += 1; inc1!(i,x); x end

function inc1!(i::Sym, x)
  new = i.seen[x] = 1 + get(i.seen,x,0)
  if new > i.most
    i.mode, i.most = x,new end end

function inc1!(i::Some, x::Number)
  m = length(i._all)
  if m < i.max 
    i.stale=true
    push!(i._all,x) 
  elseif rand() < m/i.n
    i.stale=true
    i._all[ int(m*rand())+1 ]=x end end

#---- Query ------------------------------------------------
norm!(i::Some,x, a=all(i), skip=x==it.char.skip) =
  skip ? x : max(0,min(1, (x-a[1]) / (a[end] - a[1]+1E-31))) 

mid(i::Some;lo=no,hi=no) = per(i,p=.5,lo=lo,hi=hi)

sd(i::Some;lo=no,hi=no)  = (per(i,p=.9,lo=lo,hi=hi) - 
                            per(i,p=.1,lo=lo,hi=hi)) / 2.564

function per(i::Some;p=.5,lo=no,hi=no, lst=all(i))
  hi = hi==no ? length(lst) : hi
  lo = lo==no ? 1           : lo
  lst[ int(lo + p*(hi - lo +1)) ] end

function all(i::Some)  
  if i.stale i._all=sort(i._all) end
  i.stale=false
  i._all end

```

vim: set et ts=2 sw=2:

```julia
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
```


