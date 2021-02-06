

# jump.jl

vim: set et ts=2 sw=2;

```julia
```

Non-parametric optimers
## Uses

```julia
using Test
using Random
using Parameters
using ResumableFunctions
```

## Config

```julia
@with_kw mutable struct It
  char = (skip='?',less='<',more='>',num='$',klass='!')
  str  = (skip="?")
  some = (max=32,bins=.5, cohen=0.3, trivial=1.05)
  divs = (few=126)
  seed = 1
end
```

## Globals

```julia
no = nothing
it=It()
Random.seed!(it.seed)
```

## Misc Utils
One-liners.

```julia
same(s)  = s                                  # noop       
thing(x) = try parse(Float64,x) catch _ x end # coerce
sayln(i) = begin say(i); println("") end      # print+nl
int(x)   = floor(Int,x)                       # round
any(a)   =  a[ int(length(a) * rand()) + 1]   # get any
few(a,n=it.divs.few) =                        # get many
  length(a)<n ? a : [any(a) for _ in 1:n] 
```

### Struct Printer

```julia
say(i::String) = i 
say(i::Number) = string(i) 
say(i::Array) = "["*join(map(say,i),", ")*"]" 
say(i::NamedTuple) = "("*join(map(say,i),", ")*")" 
say(i::Dict) = "{"*join(["$k="*say(v) for (k,v) in i],", ")*"}" 
say(i) = begin
  fields(x) = fieldnames(typeof(x))
  s, pre="$(typeof(i)){", ""
  for f in sort!([x for x in fields(i) if !("$x"[1] == '_')])
    v= say(getfield(i,f))
    s = s * pre * "$f=$v"
    pre=", " end
  return s * "}" end
```

### CSV Reader

```julia
@resumable function csv(file;zap=r"(\s+|#.*)") # iterate on a file
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

## Tests

```julia
main() = println(1)
```

## Command line

```julia
print(say([1,2,[3,"aa"],it]))
```


