Array.prototype.flatMap = (f) ->
  ret = []
  for item in this.map f
    item.forEach (i) -> ret.push i
  ret

Array.prototype.findIndex = (f) ->
  for v, i in this
    if f(v, i)
      return i
  return -1

Array.prototype.without = (d) ->
  a = []
  for v, i in this
    if i != d
      a.push v
  a
