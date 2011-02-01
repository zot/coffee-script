# Array mapped tree -- high-to-low shifting, to preserve order
# Very much like an array mapped trie, but the data is all at the leaves and there is path compression

[Some, None] = ((opt) -> [opt.Some, opt.None]) require './option'
require './util'

exports.arraySubst = arraySubst = (a, i, v) ->
  newArray = a.slice(0, a.length)
  newArray[i] = v
  newArray

# map over pairs and return a 32 element array with the values stored at the keys and the default elsewhere
pairMap = (limit, defaultValue, pairs) -> a = (defaultValue for i in [0...limit]); (pairs.forEach (p) -> [i, v] = p; a[i] = v); a


class BasicAMT
  putElsewhere: (i, o) ->
    if (i & ~31) != @prefix
      return o.noneSome (=> this), (_) => AMT.forChildren this, AMTLeaf.forOpt i, o
    return null
  put: (i, v) -> @putOpt i, Some(v)
  remove: (i, v) -> @putOpt i, None
  # mutable put/remove still return a value, but mutate the tree where possible
  putMutable: (i, v) -> @putMutableOpt i, Some(v)
  removeMutable: (i, v) -> @putMutableOpt i, None
  # maps on the values in the entry options
  map: (f) -> @mapOpt (opt, index) -> mofor value in opt
    f(value, index)
  flatMap: (f) ->
    # use mutable operations here because this is encapsulated
    ret = EMPTY
    index = 0
    @forEach (x) -> f(x).forEach (s) -> ret = ret.putMutable index++, s
    ret
  toString: -> "AMT(" + (mofor
    [0]
    v, i in this
      "#{i}: #{v}").join(', ') + ")"


class EmptyAMT extends BasicAMT
  get: (i) -> None
  putOpt: (i, o) -> o.noneSome (-> this), (_) -> AMTLeaf.forOpt i, o
  # for an EmptyAMT, mutable put/remove is the same as immutable put/remove
  putMutableOpt: (i, o) -> @putOpt i, o
  map: (f) -> this
  mapOpt: (f) -> this
  flatMap: (f) -> this
  putMutable: (i, v) -> @put i, v
  filter: (f) -> this
  forEach: (f) ->
  dump: -> "EMPTY"

exports.AMT = EMPTY = new EmptyAMT()


exports.AMTLeaf = class AMTLeaf extends BasicAMT
  # shift is always 5
  constructor: (@prefix, @entries) ->
  entryCount: -> @entries.reduce ((a, b) -> b.noneSome (-> a), (_) -> a + 1), 0
  get: (i) -> if (i & ~31) == @prefix then @entries[i & 31] else None
  putOpt: (i, o) ->
    return e if (e = @putElsewhere i, o) != null
    if o.same @entries[i & 31]
      return this
    if o.isNone and @entryCount() == 1 then EMPTY else new AMTLeaf @prefix, arraySubst @entries, i & 31, o
  putMutableOpt: (i, o) ->
    return e if (e = @putElsewhere i, o) != null
    @entries[i & 31] = o
    if @entryCount() == 0 then EMPTY else this
  # maps on the options in entries; f should return an option (allows removal)
  mapOpt: (f) -> new AMTLeaf @prefix, (f(opt, @prefix | index) for opt, index in @entries)
  filter: (f) ->
    e = ((opt.filter (v) -> f v, @prefix | index) for opt, index in @entries)
    if (e.reduce ((a, b) -> a + b.map (x) -> 1), 0) == 0 then EMPTY else new AMTLeaf @prefix, e
  forEach: (f) -> @entries.forEach (vOpt, index) => vOpt.forEach (v) => f(v, @prefix | index)
  dump: -> "AMTLeaf(#{@prefix} #{(mofor
    o, i in @entries
    v in o
      "#{i | @prefix}: #{v}").join ', '})"

AMTLeaf.forOpt = (i, v) -> new AMTLeaf i & ~31, pairMap 32, None, [[i & 31, v]]

class AMT extends BasicAMT
  constructor: (@shift, @prefix, @children) ->
  childIndex: (i) -> (i >> @shift) & 31
  childCount: -> @children.reduce ((a, b) -> if b == EMPTY then a else a + 1), 0
  get: (i) -> if (i & ~((32 << @shift) - 1)) then @children[@childIndex i].get i else None
  putOpt: (i, o) ->
    return e if (e = @putElsewhere i, o) != null
    index = @childIndex i
    oldChild = @children[index]
    newChild = oldChild.putOpt i, o
    if newChild is oldChild
      return this
    if newChild == EMPTY and @childCount() == 1
      return EMPTY
    return new AMT @shift, @prefix, arraySubst(@children, index, newChild)
  putMutableOpt: (i, o) ->
    return e if (e = @putElsewhere i, o) != null
    index = @childIndex i
    oldChild = @children[index]
    newChild = oldChild.putMutableOpt i, o
    @children[index] = newChild
    return if @childCount() == 0 then EMPTY else this
  mapOpt: (f) -> new AMT @shift, @prefix, (v.mapOpt f for v in @children)
  filter: (f) ->
    c = ((child.filter f) for child in @children)
    if (c.reduce ((a, b) -> if b == EMPTY then a else a + 1), 0) == 0 then EMPTY else new AMT @shift, @prefix, c
  forEach: (f) -> @children.forEach (child) -> child.forEach f
  dump: -> "AMT(#{@prefix}>>#{@shift} #{(c.dump() for c, i in @children when c != EMPTY).join ', '}"

exports.shiftPrefixFor = shiftPrefixFor = (prefixes, shift = 0, prefix = prefixes[0]) ->
  if shift == 30 or prefixes.length == 0
    return [shift, prefix]
  if prefix == (prefixes[0] & ~((1 << (shift + 5)) - 1))
    return shiftPrefixFor prefixes[1..], shift, prefix
  shiftPrefixFor prefixes, shift + 5, prefix & ~((1 << (shift + 10)) - 1)


AMT.forChildren = (ch...) -> ([shift, prefix] = shiftPrefixFor (l.prefix for l in ch)); new AMT shift, prefix, pairMap 32, EMPTY, ([(l.prefix >> shift) & 31, l] for l in ch)
