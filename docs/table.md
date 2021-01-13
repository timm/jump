

# table.jl

@@with_kw mutable struct Table
  ys=[]; xs=[]; rows=[]; cols=[] end

@with_kw mutable struct Row
  cells=[]; dom=0; y=no end

goalp(s,c=it.char) = c.less in s || c.more in s || c.klass in s

```


