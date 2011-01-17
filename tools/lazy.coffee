# A monad indicating the absence of a value
exports.None = None =
  length: 0
  map: (f) -> this
  flatMap: (f) -> this
  filter: (f) -> this
  toString: -> 'None'

# A monad indicating the presence of a value
exports.Some = class Some
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

  filter: (f) -> if f(this[0]) then this else None

  toString: -> "Some(#{this[0]})"

# You define a Lazy sequence with a "find" function
# A find function has one argument, a function that returns whether an item passes a test
# The find function runs the test function on each element of the sequence until one passes
# the test.  If an item passes the test, it returns Some(item).  If no item passes the test,
# it returns None.
exports.Lazy = class Lazy
  constructor: (f) -> @find = f

  forEach: (f) -> @find (x)->f(x); false

  filter: (f) -> t = this; new Lazy (test) -> t.find (i) -> if f(i) then test(i) else false

  map: (f) -> t = this; new Lazy (test) -> t.find (i) -> test(f(i))

  flatMap: (f) -> t = this; new Lazy (test) -> t.find (i) -> mofor item in f(i).find test
    return true

  first: -> r = null; (@find (i) -> r = i; true); r

  rest: -> t = this; first = true; new Lazy (test) -> t.find (i) -> if first then first = false else test(i)

  toString: ->
    s = ['Lazy(']
    first = true
    mofor i in this
      if first
        first = false
      else
        s.push ','
      s.push i
    s.push ')'
    s.join ''

Lazy.from = (array) -> new Lazy (f) ->
  for i in array
    if f(i)
      return new Some(i)
  None
# # # # # # #
# Some tests
# # # # # # #
###
sys = require 'sys'
mofor
  i in Lazy.from [0...4]
  j in Lazy.from [5...10]
    sys.puts [i, j]

sys.puts (Lazy.from [0...4]).first()
mofor i in Lazy.from [0...4]
  sys.puts i
sys.puts 'test toString()'
sys.puts Lazy.from [0...4]
sys.puts 'test rest.first'
sys.puts (Lazy.from [0...4]).rest().first()
sys.puts 'test rest'
mofor i in (Lazy.from [0...4]).rest()
  sys.puts i
sys.puts (Lazy.from [0...4]).rest()
sys.puts (Lazy.from [0...4]).find (x) -> x < 0
###
