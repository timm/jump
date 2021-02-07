# vim: set et ts=2 sw=2;

# Non-parametric optimizers
# ## Uses
using Test
using Random
using Parameters
using ResumableFunctions

# ## Config
@with_kw mutable struct It
  data = (file="auto93.csv", dir="data",some=128,best=.75)
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
# Count all the symbols. Keep a sample of the numbers.
@with_kw mutable struct Some pos=0;txt="";w=1;n=0;_all=[];ok=true end
@with_kw mutable struct Sym  pos=0;txt="";w=1;n=0;seen=Dict() end
@with_kw mutable struct Skip pos=0;txt="";w=1;n=0 end

function inc!(i,x::Array) for y in x inc!(i,y) end; i end
function inc!(i,x) 
  inc1!(i::Skip, x) = i 
  inc1!(i::Sym,  x) = begin
    new = i.seen[x] = 1 + get(i.seen,x,0) 
    if new > i.n i.n, i.mode = now, x end end 
  inc1!(i::Some, x) = begin 
    m = length(i._all)
    if m < it.some.max    
      i.ok=false; push!(i._all, x); 
    elseif rand() < m/i.n 
      i.ok=false; i._all[int(m*rand())+1]=x end 
  end
  x==it.char.skip ? x : begin i.n += 1; inc1!(i,x); x end end

function mid(i::Sym) i.mode end
function var(i::Sym) sum(-v/i.n*log(2,v/i.n) for (_,v) in i.seen) end

function mid( i::Some)   a=all(i); per(a,.5) end
function var( i::Some)   a=all(i); (per(a,.9) - per(a,.1)) / 2.56 end
function norm(i::Some,x) a=all(i);
  x==it.char.skip ? x : (x-a[1])/(a[end]-a[1]+1E-32) end 

function all(i::Some) 
  i._all = i.ok ? i._all : sort(i._all) 
  i.ok = true
  i._all end

function combine(i::Some,j::Some, small,lo) 
  mi, mj = mid(i), mid(j)
  if (abs(mi) - abs(mj) < small) || (mi < lo && mi < lo)
    inc!(Some(), [i._all;j._all]) end end

# -------------------------------------------------------------------
# ## Table
# Load rows, Summarize the columns.
@with_kw mutable struct Table ys=[]; xs=[]; rows=[]; cols=[] end
@with_kw mutable struct Row   has=[]; gt=0; tag=no end

function data(file; t=Table())
  col(;txt="", pos=0, c=it.char) = begin
    what = c.less in txt||c.more in txt||c.num in txt ? Some : Sym
    what = c.skip in txt ? Skip : what
    now = what(txt=txt, pos=pos, w= c.less in txt ? -1 : 1) 
    at  = c.less in txt||c.more in txt||c.klass in txt ? t.ys : t.xs
    push!(at, now)  
    now
  end
  cols(a)  = [col(txt=txt, pos=pos) for (pos,txt) in enumerate(a)]
  cells(a) = Row(has= [inc!(c, a[c.pos]) for c in t.cols])
  for a in csv(it.data.dir * "/" * file)
    length(t.cols)==0 ? t.cols=cols(a) : push!(t.rows, cells(a)) end
  t end

# -------------------------------------------------------------------
# ## Classify
# Score rows by how they are better than others.   
# Tag the `best` percent rows.
function tag(t::Table)
  function gt(row1, row2)
    "Zitler's continous domination predicate (from IBEA, 2005)."
    s1, s2, n = 0, 0, length(t.ys)
    for col in t.ysz
      a, b = row1.has[col.pos], row2.has[col.pos]
      a, b = norm(col, a), norm(col, b)
      s1  -= ℯ ^ (col.w * (a - b) / n)
      s2  -= ℯ ^ (col.w * (b - a) / n) end
    s1/n < s2/n 
  end
  n = it.data.some
  print(":::",any(t.rows))
  for row in t.rows 
    row.gt = sum(gt(row, any(t.rows)) for _ in 1:n)/n  end
  for (n, row) in enumerate(sort(t.rows, by = x -> x.gt))
    row.tag = n > length(t.rows) * it.data.best end
  t end

# -------------------------------------------------------------------
# ## Discretize
# Score rows by how they are better than others.   
# Tag the `best` percent rows.
@with_kw mutable struct Span 
   lo=typemax(Int); hi=typemin(Int); _has=[] end

function discretize(x::Some, t:Table)
  function div(xsmall,ysmall,ymin,xy)
    n = length(xy) * the data.xchop
    while n < 4 && n <= length(xy)/2 n+= 1.2 end
    n, now, tmp = int(n), int(n), []
    b4, span    = 1, Span(lo=xy[1][1])
    while now < length(xy) - n
      x=xy[now][1]
      span.hi = x
      now += 1
      if (now - b4 => n    && now < len(xy) - 2 && 
          x != xy[now][1]  && span.hi - span.lo > xsmall) 
        span._has= [z[2] for z in xy[b4:now]]
        tmp += [span]
        span = Span(lo=xy[now][1])
        b4   = now
        now += n end end
     tmp += [Span(lo=xy[b4][1],hi=xy[end][1],
                  _has=[z[2] for z in xy[b4:]])]
     merge(tmp,ysmall,ymin) end 
 
  function merge(b4, ysmall, ymin)
    j, now = 0, []
    while j < length(b4)
      a=b4[j]
      if j < length(b4)
        b = b4[j+1]
        c  = combine(a._has,b._has, ysmall, ymin)
        if c != nothing
          now += [Span(lo=a.lo,hi=
    end 
    length(now) == length(b4) ? b4 : merge(now,ymin,small) 

  for row in rows:
    inc!(y, row.gt)
    push!(xy, (row.has[x.pos], row.gt)) end
  tmp = div(var(x)*it.some.xsmall,
            var(y)*it.some.ysmall,
            per(all(y), it.data.best),
            sort(xy))
  tmp[1].lo = typemin(Int)
  tmp[end].hi = typemax(Int)
  tmp end 
 

 # -------------------------------------------------------------------
# ## Misc Utils
# ### One-liners.
same(s)  = s                                  #noop       
int(x)   = floor(Int,x)                       #round
per(a,n) = a[int(length(a)*n)+1]                #percentile
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
o(i::Dict)       = "{"*join(["$k="*o(v) for (k,v) in i],", ")*"}" 
o(i::Span)       = begin
  if i.lo <= typemin(Int) return "<= $(i.hi)" 
  if i.hi <= typemax(Int) return ">= $(i.lp)" 
  "[$(i.lo)..$(i.hi)]" end
o(i) = begin
  s, pre="$(typeof(i)){", ""
  for f in sort([x for x in fieldnames(typeof(i)) 
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
go()  = include("jump.jl")
function run() 
  t=tag(data("auto.csv"))
  for r in sort(t.rows, by = x -> x.gt)
    print(r.tag) end end

# ## Command line
