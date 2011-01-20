# Array mapped trie.  Each node

[Some, None] = ((opt) -> [opt.Some, opt.None])(require './option')

exports.arraySubst = arraySubst = (a, i, v) ->
  newArray = a.slice(0, a.length)
  newArray[i] = v
  newArray

class EmptyAMT
  shift: 0
  entries: None for i in [0...32]
  children: EmptyAMT for i in [0...32]
  get: (i) -> None
  put: (i, v, shift) -> putWithShift(i, v, 0)
  putWithShift: (i, v, shift) ->
    shifted = i >> shift
    index = i & 31
    if shifted == index then new AMT(@shift, arraySubst(@entries, i, v), @children) else new AMT(@shift, @entries, arraySubst(@children, i, @children[i].putWithShift(i, v, @shift + 5)))

class AMT extends EmptyAMT
  constructor: (@shift, @entries, @children) ->
  get: (i) ->
    shifted = i >> @shift
    index = i & 31
    return if shifted == index then @entries[i] else @children[index].get(i)

exports.EmptyAMT = new EmptyAMT
