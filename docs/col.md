

# col.jl

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


