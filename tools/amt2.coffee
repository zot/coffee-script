# Array Mapped Trie -- sort of (high-to-low shifting, to preserve order)
# THIS NEEDS PATH COMPRESSION
# make putWithShiftMutable a private function?

[Some, None] = ((opt) -> [opt.Some, opt.None]) require './option'
require './util'

exports.arraySubst = arraySubst = (a, i, v) ->
  newArray = a.slice(0, a.length)
  newArray[i] = v
  newArray

# map over pairs and return a 32 element array with the values stored at the keys and the default elsewhere
pairMap = (limit, defaultValue, pairs) -> a = (defaultValue for i in [0...limit]); (pairs.forEach (p) -> [i, v] = p; a[i] = v); a


class BasicAMT
  toString: -> "AMT(#{([].flatMap (f) -> @map (v, i) -> "#{i}: #{v}").join ', '})"
  put: (i, v) -> @putOpt i, Some(v)
  remove: (i, v) -> @putOpt i, None
  # mutable put/remove still return a value, but mutate the tree where possible
  putMutable: (i, v) -> @putMutableOpt i, Some(v)
  removeMutable: (i, v) -> @putMutableOpt i, None
  # maps on the values in the entry options
  map: (f) -> @mapOpt (opt, index) -> opt.map (value) -> f(value, index)
  flatMap: (f) ->
    # use mutable operations here because this is encapsulated
    ret = empty
    index = 0
    @forEach (x) -> f(x).forEach (s) -> ret = ret.putWithShiftMutable index++, Some(s), 0
    ret


class EmptyAMT extends BasicAMT
  get: (i) -> None
  putOpt: (i, o) -> o.noneSome (-> this), (_) -> new AMTLeaf i & ~31, pairMap 32, None, [[i & 31, o]]
  # for an EmptyAMT, mutable put/remove is the same as immutable put/remove
  putMutableOpt: (i, o) -> @putOpt i, o
  map: (f) -> this
  mapOpt: (f) -> this
  flatMap: (f) -> this
  putMutable: (i, v) -> @put i, v
  filter: (f) -> this
  forEach: (f) ->

exports.AMT = EMPTY = new EmptyAMT()

class AMTLeaf extends BasicAMT
  constructor: (@prefix, @entries) ->
  entryCount: -> @entries.reduce ((a, b) -> a + b.map 1), 0
  get: (i) -> @entries[i & 31]
  putOpt: (i, o) ->
    if i & @prefix != @prefix
      return if o.isNone then this else AMT.forLeaves this, AMTLeaf.forOpt i, o
    if o.same @entries[i & 31]
      return this
    if o.isNone and @entryCount == 1
      return EMPTY
    new AMTLeaf @prefix, arraySubst @entries, i & 31, o
  putMutableOpt: (i, o) ->
    if i & @prefix != @prefix
      return if o.isNone then this else AMT.forLeaves this, AMTLeaf.forOpt i, o
    if o.same @entries[i & 31]
      return this
    if o.isNone and @entryCount == 1
      return EMPTY
    @entries[i & 31] = o
    this
  # maps on the options in entries; f should return an option (allows removal)
  mapOpt: (f) -> new AMTLeaf @index, @entries.map (opt, index) -> f(opt, @prefix | index)
  filter: (f) ->
    e = @entries.map (v, index) -> v.filter (optV) -> f(optV, @prefix | index)
    if (e.reduce ((a, b) -> a + b.map 1), 0) == 0 then EMPTY else new AMTLeaf @index, e
  forEach: (f) -> @entries.forEach (vOpt, index) -> vOpt.forEach (v) -> f(v, @prefix | index)

AMTLeaf.forOpt = (i, v) -> new AMTLeaf i & ~31, pairMap 32, [[i, v]], None

class AMT extends BasicAMT
  constructor: (@shift, @prefix, @children) ->
  childIndex: (i) -> (i >> @shift) & 31
  childCount: -> @children.reduce ((a, b) -> if b instanceof EMPTY then a else a + 1), 0
  get: (i) -> @children[@childIndex i].get i
  putOpt: (i, v) ->
    index = @childIndex i
    oldChild = @children[index]
    newChild = oldChild.putOpt i, v
    if newChild is oldChild
      return this
    if newChild == EMPTY and @childCount() == 1
      return EMPTY
    return new AMT @shift, @prefix, arraySubst(@children, childIndex, newChild)
  putMutableOpt: (i, v) ->
    index = @childIndex i
    oldChild = @children[index]
    newChild = oldChild.putMutableOpt i, v
    @children[index] = newChild
    return if newChild == EMPTY and @childCount() == 1 then EMPTY else this
  mapOpt: (f) -> new AMT @shift, @prefix, @children.map (v) -> v.mapOpt f
  filter: (f) ->
    c = @children.map (v, index) -> v.filter (optV) -> f(optV, @prefix | index)
    if (c.reduce ((a, b) -> if b instanceof EMPTY then a else a + 1), 0) then EMPTY else new AMT @shift, @prefix, c
  forEach: (f) -> @children.forEach (child) -> child.forEach f

shiftPrefixFor = (leaves, shift = 0, prefix = leaves[0].prefix) ->
  if shift == 30 or leaves.length == 0
    return [30, 0]
  if prefix == leaves[0].prefix
    return shiftPrefixFor leaves[1..], shift, prefix
  shiftPrefixFor leaves, shift + 5, prefix & ~((1 << shift) - 1)

AMT.forLeaves = (leaves...) -> [shift, prefix] = shiftPrefixFor leaves; new AMT shift, prefix, pairMap 32, EMPTY, leaves.map (l) -> [(l.prefix >> shift) & 31, l]

sys=require 'sys'
sys.puts (EMPTY.put 1, 'a')
sys.puts EMPTY.put(1, 'a').put(2, 'b')
EMPTY.put(1, 'a').put(2, 'b').map((v) -> v + "-").forEach (v, i) -> sys.puts "#{i}: #{v}"
