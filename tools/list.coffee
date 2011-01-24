exports.Nil = Nil =
  map: (f) -> this
  flatMap: (f) -> this
  filter: (f) -> this
  forEach: (f) ->
  toString: -> 'Nil'
  append: (l) -> l
  inject: (f, v) -> v

class Cons
  constructor: (@car, @cdr) ->
  map: (f) -> new Cons @car.map(f), @cdr.map(f)
  flatMap: (f) -> (@car.map f).append @cdr.flatMap f
  filter: (f) -> if f @car then new Cons @car, @cdr.filter f else @cdr.filter f
  forEach: (f) -> f @car; @cdr.forEach f
  append: (l) -> new Cons @car, @cdr.append l
  inject: (f, v) -> @cdr.inject f, (f v, @car)

exports.List = List = (items...) -> ListOf(items)

ListOf = (items) if items.length == 0 then Nil else new Cons items[0], ListOf items[1..]...

exports.Cons = (a, b) -> new Cons a, b
