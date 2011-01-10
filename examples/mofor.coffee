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
      return res[0]
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
    for element in item
      ret.push element
  ret

sys.p 1
sys.p (mofor
  a <- [1,2,3]
  b <- [4,5,6]
  if a % 2 == 0 or b % 2 == 0
->
  [a + 1, b + 1])

sys.p (mofor
  a <- new Some(3)
->
  a
)

sys.p (mofor
  a <- new Some(3)
  b <- none
->
  a
)
