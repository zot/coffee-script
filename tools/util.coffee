Array.prototype.flatMap = (f) ->
  ret = []
  for item in this.map(f)
    item.forEach (i) -> ret.push i
  ret
