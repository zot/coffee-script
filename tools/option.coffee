# A monad indicating the absence of a value
exports.None = None =
  length: 0
  map: (f) -> this
  flatMap: (f) -> this
  filter: (f) -> this
  toString: -> 'None'

# A monad indicating the presence of a value
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

  filter: (f) -> if f(this[0]) then this else None

  toString: -> "Some(#{this[0]})"

exports.Some = (x) -> new Some(x)
