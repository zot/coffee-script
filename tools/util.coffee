Array.prototype.flatMap = (f) ->
  ret = []
  for item in this.map(f)
    item.forEach (i) -> ret.push i
  ret

Array.prototype.findIndex = (f) ->
  for v, i in this
    if f(v)
      return i
  return -1
