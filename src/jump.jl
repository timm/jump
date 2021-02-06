# vim: set et ts=2 sw=2;

# Non-parametric optimizers
# ## Uses
using Test
using Random
using Parameters
using ResumableFunctions

# ## Config
@with_kw mutable struct It
  data = (file="auto93.csv", dir="data")
  char = (skip='?',less='<',more='>',num=':',klass='!')
  str  = (skip="?")
  some = (max=64,bins=.5, cohen=0.3, trivial=1.05)
  divs = (few=126)
  seed = 1
end

# ## Globals
it=It()
Random.seed!(it.seed)
no = nothing

# -------------------------------------------------------------------
# ## Columns
@with_kw mutable struct Some pos=0;txt="";w=1;n=0;_all=[];ok=true end
@with_kw mutable struct Sym  pos=0;txt="";w=1;n=0;seen=Dict() end
@with_kw mutable struct Skip pos=0;txt="";w=1;n=0 end

function inc!(i,x) 
  function inc1!(i::Skip, x)  i end
  function inc1!(i::Sym,  x) 
    new = i.seen[x] = 1+get(i.seen,x,0) 
    if new > i.n i.n, i.mode = now, x end end 
  function inc1!(i::Some, x) 
    m = length(i._all)
    if m < it.some.max    
      i.ok=false; push!(i._all, x); 
    elseif rand() < m/i.n 
      i.ok=false; i._all[int(m*rand())+1]=x end end

  x==it.char.skip ? x : begin i.n += 1; inc1!(i,x) end
  x end  

function all(i::Some) 
  i._all = i.ok ? i._all : sort(i._all) 
  i.ok = true
  i._all end

function mid( i::Sym)    i.mode end
function mid( i::Some)   a=all(i); per(a,.5) end
function sd(  i::Some)   a=all(i); (per(a,.9) - per(a,.1)) / 2.56 end
function norm(i::Some,x) a=all(i)
  x==it.char.skip ? x : (x-a[1])/(a[end]-a[1]+1E-32) end 

# -------------------------------------------------------------------
# ## Table
# Load rows, Summarize the columns.
@with_kw mutable struct Table ys=[]; xs=[]; rows=[]; cols=[] end
@with_kw mutable struct Row   has=[]; n=0; klass=no; hi=0; most=no end

function data(file; t=Table())
  function col(;txt="", pos=0, c=it.char)
    x = c.less in txt||c.more in txt||c.num in txt ? Some : Sym
    x = c.skip in txt ? Skip : x
    x(txt=txt, pos=pos, w= c.less in txt ? -1 : 1) end

  cols(a)  = [col(txt=txt, pos=pos) for (pos,txt) in enumerate(a)]
  cells(a) = Row(has= [inc!(c, a[c.pos])     for c in t.cols])
  for a in csv(it.data.dir * "/" * file)
    length(t.cols)==0 ? t.cols=cols(a) : push!(t.rows, cells(a)) end
  t end

# -------------------------------------------------------------------
# ## Misc Utils
# ### One-liners.
same(s)  = s                                  #noop       
int(x)   = floor(Int,x)                       #round
per(a,n) = a[int(length(a)*n)]                #percentile
thing(x) = try parse(Float64,x) catch _ x end #coerce
say(i)   = println(o(i))                      #print+nl
any(a)   = a[ int(length(a) * rand()) + 1 ]   #pick any one
few(a,n=it.divs.few) =                        #pick many
  length(a)<n ? a : [any(a) for _ in 1:n] 

# ### How to print a struct
# Skips any fields starting with "`_`".
o(i::String)     = i 
o(i::SubString)  = i 
o(i::Char)       = string(i) 
o(i::Number)     = string(i) 
o(i::Array)      = "["*join(map(o,i),", ")*"]" 
o(i::NamedTuple) = "("*join(map(o,i),", ")*")" 
o(i::Dict) = "{"*join(["$k="*o(v) for (k,v) in i],", ")*"}" 
o(i) = begin
  s, pre="$(typeof(i)){", ""
  for f in sort!([x for x in fieldnames(typeof(i)) 
                  if !("$x"[1] == '_')])
    s = s * pre * "$f=$(o(getfield(i,f)))"
    pre=", " end
  return s * "}" end

# ### How to read a CSV File
# Skip blank lines. Coerce numeric strings to numbers.
@resumable function csv(file;zap=r"(\s+|#.*)") #iterate on file
  b4=""
  for line in eachline(file)
    line = replace(line,zap =>"")
    if length(line) != 0
      if line[end] == ',' # if line ends with ",",
        b4 = b4 * line    # join it to next
      else
        @yield [thing(x) for x in split(b4*line,",")]
        b4 = "" end end end end  

# ## Tests
go()   = include("jump.jl")
main() = all(data("auto.csv").cols[4])

# ## Command line
