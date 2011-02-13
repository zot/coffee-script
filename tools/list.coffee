require './util'

exports.Nil = Nil =
  map: (f) -> this
  flatMap: (f) -> this
  filter: (f) -> this
  forEach: (f) ->
  toString: -> 'Nil'
  append: (l) -> l
  reduce: (f, v) -> v
  reverse: (r) -> r
  join: (sep) -> ""

class Cons
  constructor: (@car, @cdr) ->
  map: (f) -> new Cons @car.map(f), @cdr.map(f)
  flatMap: (f) -> (@car.map f).append @cdr.flatMap f
  filter: (f) -> if f @car then new Cons @car, @cdr.filter f else @cdr.filter f
  forEach: (f) -> f @car; @cdr.forEach f
  append: (l) -> new Cons @car, @cdr.append l
  reduce: (f, v) -> @cdr.reduce f, (f v, @car)
  reverse: (r = Nil) -> @cdr.reverse new Cons @car, r
  toString: -> "List(#{@join ', '})"
  join: (sep) -> (mofor
    [0]
    this).join sep

exports.List = List = (items...) -> ListOf(items, 0)

ListOf = (items, i) -> if items.length == i then Nil else new Cons items[i], ListOf items, i + 1

exports.Cons = (a, b) -> new Cons a, b
