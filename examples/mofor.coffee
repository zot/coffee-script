sys=require 'sys'

none =
  length: 0
  map: (f) -> this
  flatMap: (f) -> this
  filter: (f) -> this
  toString: -> 'none'

class Some
  constructor: (value) -> this[0] = value

  length: 1

  flatMap: (func) ->
    res = func(this[0])
    if res.length == 1
      return res
    else
      ret = []
      for item in res
        for element in item
          ret.push element
      return ret

  map: (f) -> new Some(f(this[0]))

  filter: (f) -> if f(this[0]) then this else none

  toString: -> "Some(#{this[0]})"

Array.prototype.flatMap = (f) ->
  ret = []
  for item in this.map(f)
    item.forEach (i) -> ret.push i
  ret

sys.p 1
sys.p (mofor
  a in [1,2,3]
  b in [4,5,6]
  if a % 2 == 0 or b % 2 == 0
    [a + 1, b + 1])

sys.p (mofor
  a in new Some(3)
    a + 1
)

sys.p (mofor
  a in new Some(3)
  b in none
    a
)

sys.p(mofor a in [1,2,3]
  a + 2)

sys.p(mofor _ in new Some(2)
    3)

sys.p(mofor
  a in new Some(5)
  b in new Some(6))

sys.p(mofor
  a in new Some(5)
  new Some(6))
