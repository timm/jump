# vim: set et ts=2 sw=2;

# Non-parametric optimizers
# ## Uses
using Test
using Random
using Parameters
using ResumableFunctions

# ## Config
@with_kw mutable struct It
  data = (file="auto93.csv", path="./")
  char = (skip='?',less='<',more='>',num='$',klass='!')
  str  = (skip="?")
  some = (max=64,bins=.5, cohen=0.3, trivial=1.05)
  divs = (few=126)
  seed = 1
end

# ## Globals
no = nothing
it=It()
Random.seed!(it.seed)

# ## Columns
@with_kw mutable struct Some  pos=0;txt="";w=1;n=0;_all=[];ok=true end
@with_kw mutable struct Sym   pos=0;txt="";w=1;n=0;seen=Dict() end
@with_kw mutable struct Skip  pos=0;txt="";w=1 end

function col(;txt="",pos=0,c=it.char)
  x = c.less in txt||c.more in txt||c.num in txt ? Some : Sym
  x = c.skip in txt ? Skip : what
  x(txt=txt,pos=pos, w= c.less in txt ? -1 : 1) end

function inc!(i,x;  skip=x==it.char.skip) 
  skip ? x : begin i.n += 1; inc1!(i,x); x end end

function inc1!(i::Skip, x) x end
function inc1!(i::Sym,  x) i.seen[x] = 1+get(i.seen,x,0) end
function inc1!(i::Some, x) 
  m = length(i._all)
  if m < i.some.max
    i.ok = false
    push(i._all,x)
  elseif rand() < m/i.n
    i.ok = false
    i._all[ int(m*rand()) + 1 ] = x end end 

function all(i::Some) 
  i._all = i.ok ? i._all : sort(i._all) 
  i.ok = true
  i._all end

norm(i::Some,x; a=all(i)) = (x-a[1])/(a[end] - a[1]+1E-32)
mid( i::Some,x; a=all(i)) = per(a,.5)
sd(  i::Some;   a=all(i)) = (per(a,.9) - per(a,.1)) / 2.56

# ## Table
@with_kw mutable struct Table ys=[]; xs=[]; rows=[]; cols=[] end
@with_kw mutable struct Row   cells=[]; score=0; klass=no    end

function tbl(file)
  t = Table()
  for row in csv(it.data.dir * "/" * file)
    if length(t.cols) == 0
      t.cols = [col(txt=txt,col=pos) for (pos,txt) in enumerate(row)]
    else
      push(t.rows, 
           Row(cells = [inc(c,row[c.pos]) for c in t.cols])) end end
  t end

# ## Misc Utils
# ### One-liners.
same(s)  = s                                  #noop       
int(x)   = floor(Int,x)                       #round
per(a,n) = a[int(length(a)*n)]                #percentile
thing(x) = try parse(Float64,x) catch _ x end #coerce
sayln(i) = begin say(i); println("") end      #print+nl
any(a)   = a[ int(length(a) * rand()) + 1 ]   #pick any one
few(a,n=it.divs.few) =                        #pick many
  length(a)<n ? a : [any(a) for _ in 1:n] 

# ### How to print a struct
# Skips any fields starting with "`_`".
say(i::String)     = i 
say(i::Char)       = string(i) 
say(i::Number)     = string(i) 
say(i::Array)      = "["*join(map(say,i),", ")*"]" 
say(i::NamedTuple) = "("*join(map(say,i),", ")*")" 
say(i::Dict) = "{"*join(["$k="*say(v) for (k,v) in i],", ")*"}" 
say(i) = begin
  fields(x) = fieldnames(typeof(x))
  s, pre="$(typeof(i)){", ""
  for f in sort!([x for x in fields(i) if !("$x"[1] == '_')])
    s = s * pre * "$f=" * say(getfield(i,f))
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
main() = println(1)

# ## Command line
print(say([1,2,[3,"aa"],it]))
