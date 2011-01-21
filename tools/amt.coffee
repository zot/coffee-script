# Array Mapped Trie (high-to-low shifting, to preserve order)
# THIS NEEDS PATH COMPRESSION
# make putWithShiftMutable a private function?

[Some, None] = ((opt) -> [opt.Some, opt.None]) require './option'

exports.arraySubst = arraySubst = (a, i, v) ->
  newArray = a.slice(0, a.length)
  newArray[i] = v
  newArray

class EmptyAMT
  size: 0
  shift: 30
  entries: None for i in [0...32]
  get: (i) -> None
  put: (i, v) -> @putWithShift(i, Some(v), 30)
  remove: (i) -> @putWithShift(i, None, 30)
  putWithShift: (i, v, shift) ->
    shifted = i >> shift
    index = shifted & 31
    if (i & ((1 << shift) - 1)) == 0
      if @size == 1 and v == None
        return @empty
      if @entries[index] == v
        return this
      return new AMT(shift, arraySubst(@entries, index, v), @children, @size + 1)
    else
      child = @children[index].putWithShift(i, v, shift - 5)
      if child == @children[index]
        return this
      newSize = @size + child.size - @children[index].size
      if newSize == 0
        return @empty
      return new AMT(shift, @entries, arraySubst(@children, index, child), newSize)
  map: (f) -> this
  flatMap: (f) -> this
  forEach: (f) ->
  subFor: (f, index) ->
  toString: -> t = this; "AMT(#{t.contents()})"
  contents: ->
    r = []
    @forEach (v, i) -> r.push "#{i}: #{v}"
    r.join ', '

exports.EmptyAMT = EmptyAMT.prototype.empty = new EmptyAMT
EmptyAMT.prototype.children = (EmptyAMT.prototype.empty for i in [0...32])
EmptyAMT.prototype.putWithShiftMutable = EmptyAMT.prototype.putWithShift

class AMT extends EmptyAMT
  constructor: (@shift, @entries, @children, @size) ->
  get: (i) ->
    shifted = i >> @shift
    index = shifted & 31
    if (i & ((1 << @shift) - 1)) == 0 then @entries[index] else @children[index].get(i)
  putWithShiftMutable: (i, v, shift) ->
    shifted = i >> shift
    index = shifted & 31
    if (i & ((1 << shift) - 1)) == 0
      if @entries[index] != v
        @entries[index] = v
        if v == None
          @size--
        else
          @size++
    else
      oldSize = @children[index].size
      @children[index] = @children[index].putWithShiftMutable(i, v, shift - 5)
      @size += @children[index].size - oldSize
    return if @size == 0 then @empty else this
  map: (f) -> new AMT(@shift, @entries.map((e) -> e.map f), @children.map((child) -> child.map f), @size)
  flatMap: (f) ->
    # use mutable operations here because this is encapsulated
    ret = @empty
    index = 0
    @forEach (x) -> f(x).forEach (s) -> ret = ret.putWithShiftMutable index++, Some(s), 0
    ret
  forEach: (f) -> @subFor f, 0
  subFor: (f, index) ->
    for i in [0...32]
      @entries[i].forEach (e) -> f(e, index | (i << @shift))
    for i in [0...32]
      @children[i].subFor(f, index | (i << @shift))
