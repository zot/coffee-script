# Array mapped tree -- high-to-low shifting, to preserve order
# Very much like an array mapped trie, but the data is all at the leaves and there is path compression
# TODO: compress entries/children using popct and a bitmap for presence -- this would remove the need for EmptyAMT
# TODO: next, combine prefix and shift

{Some, None} = require './option'
{Cons, Nil} = require './list'
{SimpleMonad} = require './monad'
require './util'


# BasicAMTs have
# @prefix -- the bit prefix of the subtree's item indices
# @items -- the children or values
class BasicAMT
  # if the value fits in the current tree, return null
  # otherwise, return a new subtree, containing the current tree and a new leaf
  newSubtree: (add, i, v) -> if !add then this else AMT.for this, AMTLeaf.for i, v
  put: (i, v) -> @mod true, i, v
  remove: (i, v) -> @mod false, i
  # mutable put/remove still return a value, but mutate the tree where possible
  putMutable: (i, v) -> @modMutable true, i, v
  removeMutable: (i, v) -> @modMutable false, i
  flatMap: (f) -> @reduce ((a, item, index) -> f(item, index).reduce ((b, item) -> [(b[0].put b[1], item), b[1] + 1]), a), [EMPTY, 0]
  reduce: (f, a...) -> if a.length then @reduceArg f, a[0] else @reduceNoArg f
  toString: -> "AMT(" + (mofor acc in (new AMTPrinter 0, Nil) do
    v, i in this
    acc.print i, v).toString() + ")"


class AMTPrinter extends SimpleMonad
  constructor: (@expected, @output) ->
  print: (i, v) -> new AMTPrinter i + 1, Cons (if i == @expected then v else i + ': ' + v), @output
  toString: -> (mofor
    [0]
    @output.reverse()).join ', '


## compressed arrays
## array with a bitset value to indicate which of the 32 potential elements have values

#create a new array with a value substitution
exports.arraySubst = arraySubst = (a, i, v) ->
  newArray = a[0...a.length]
  newArray[i] = v
  setBitset newArray, a.bitset

countBits = (x) ->
  # from http://bits.stephan-brumme.com/countBits.html
  x  = x - ((x >>> 1) & 0x55555555)
  x  = (x & 0x33333333) + ((x >>> 2) & 0x33333333)
  (((x + (x >>> 4)) & 0xF0F0F0F) * 0x01010101) >>> 24

lowestOneBit = (x) -> x & -x

MultiplyDeBruijnBitPosition2 = [
  0, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15, 25, 17, 4, 8,
  31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9
]

log2 = (v) -> MultiplyDeBruijnBitPosition2[(v * 0x077CB531) >>> 27]

trailingZeroes = (x) -> log2 x & -x

setBitset = (array, bitset) -> array.bitset = bitset; array

itemsGet = (values, index) -> values[countBits ((1 << index) - 1) & values.bitset]

itemsFor = (i1, v1, i2, v2) -> if i1 <= i2 then setBitset [v1, v2], (1 << i1) | (1 << i2) else itemsFor i2, v2, i1, v1

itemsSet = (values, index, value) ->
  member = 1 << index
  pos = countBits (member - 1) & values.bitset
  return arraySubst values, pos, value if member & values.bitset
  n = values[0...values.length]
  n.splice pos, 0, value
  setBitset n, values.bitset | member

itemsHas = (values, index) -> values.bitset & (1 << index)

itemsRemove = (values, index) ->
  member = 1 << index
  return values if !(member & values.bitset)
  n = values[0...values.length]
  n.splice countBits values.bitset & (member - 1), 1
  setBitset n, values.bitset & ~member

itemsDo = (values, f) ->
  set = values.bitset
  pos = 0
  while set
    b = lowestOneBit set
    f values[pos], log2 b
    set = set & ~b
    pos++

itemsMap = (values, f) ->
  res = setBitset [], values.bitset
  itemsDo values, (v, i) -> res.push f(v, i)
  res

itemsFilter = (values, f) -> itemsReduce values, ((result, v, i) ->
  if f(v, i)
    result.push v
    result.bitset |= (1 << i)
  result), (setBitset [], 0)

itemsReduce = (values, f, v) -> itemsReduceArg values, f, v, values.bitset, 0

itemsReduceRest = (values, f, v) -> itemsReduceArg values, f, v, values.bitset & ~(lowestOneBit values.bitset), 1

itemsReduceArg = (values, f, v, set, pos) -> if !set then v else b = lowestOneBit set; itemsReduceArg values, f, f(v, values[pos], log2 b), set & ~b, pos + 1

shiftAndPrefixFor = (pf1, pf2, resultFunc) ->
  for shift in [5..30] by 5
    if (pf1 & ~((1 << shift) - 1)) == (pf2 & ~((1 << shift) - 1))
      return resultFunc shift, pf1 & ~((1 << shift) - 1)
  resultFunc 32, 0

exports.AMTLeaf = class AMTLeaf extends BasicAMT
  # shift is always 5
  constructor: (@prefix, @items) ->
  inSubtree: (i) -> (i & ~31) == @prefix
  get: (i) -> if (i & ~31) == @prefix and (i & @items.bitset) != 0 then Some(itemsGet @items, i) else None
  mod: (add, i, v) ->
    if !@inSubtree i then @newSubtree add, i, v
    else if (add and (itemsHas @items, i) and v == itemsGet @items, i) or (!add and !itemsHas @items, i) then this
    else if add then new AMTLeaf @prefix, itemsSet @items, i, v
    else if @items.length == 1 then EMPTY
    else new AMTLeaf @prefix, itemsRemove @items, i
  modMutable: (add, i, v) ->
    return @putInNewSubtree i, v if !@inSubtree i
    if add
      @items = itemsSet @entires, i, v
    else if itemsHas i
      return EMPTY if @items.length == 1
      @items = itemsRemove @items, i
    this
  # maps on the options in entries; f should return an option (allows removal)
  map: (f) -> new AMTLeaf @prefix, itemsMap @items, (v, i) => f v, @prefix | i
  filter: (f) ->
    newEntries = itemsFilter @items, (v, i) => f v, @prefix | i
    if !newEntries.length then EMPTY else if newEntries.length == @items.length then this else new AMTLeaf @prefix, newEntries
  reduceNoArg: (f) -> itemsReduceRest @items, ((a, v, i) => f a, v, @prefix | i), @items[0]
  reduceArg: (f, a) -> itemsReduceRest @items, ((a, v, i) => f a, v, @prefix | i), f a, @items[0], @prefix | trailingZeroes @items.bitset
  forEach: (f) -> itemsDo @items, (v, i) => f v, @prefix | i
  dump: -> "AMTLeaf(#{@prefix} #{(itemsMap @items, (v, i) => "#{@prefix | i}: #{v}").join ', '})"
  @for = (i, v) -> new AMTLeaf i & ~31, setBitset [v], 1 << (i & 31)

exports.AMT = EMPTY = new AMTLeaf -1, []
EMPTY.mod = (add, i, v) -> if add then AMTLeaf.for i, v else this
EMPTY.dump = -> "EMPTY"

class AMT extends BasicAMT
  constructor: (@shift, @prefix, @items) ->
  inSubtree: (i) -> (i & ~((1 << @shift) - 1)) == @prefix
  childIndex: (i) -> (i >> @shift - 5) & 31
  get: (i) -> if @inSubtree i then (itemsGet @items, childIndex i).get i else None
  mod: (add, i, v) ->
    return @newSubtree add, i, v if !@inSubtree i
    index = @childIndex i
    has = itemsHas @items, index
    return this if !add and !has
    if !has
      newChild = AMTLeaf.for i, v
    else
      oldChild = itemsGet @items, index
      newChild = oldChild.mod add, i, v
      return @items[(countBits @items.bitSet & (1 << index) - 1) * -2 + 1] if newChild == EMPTY and @items.length == 2
      return this if newChild is oldChild
    return new AMT @shift, @prefix, itemsSet @items, index, newChild
  modMutable: (add, i, v) ->
    return @newSubtree add, i, v if !@inSubtree i
    index = @childIndex i
    newChild = (itemsGet @items, index).modMutable add, i, v
    if newChild is EMPTY
      itemsRemove @items, index
    else
      itemsSet @items, index, newChild
    return if !@items.length then EMPTY else this
  map: (f) -> new AMT @shift, @prefix, setBitset (v.map f for v in @items), @items.bitset
  filter: (f) ->
    c = itemsFilter @items, (v) => (v.filter f) != EMPTY
    if !c.length then EMPTY else if c.length == 1 then c[0] else if c.length == @items.length then this else AMT @shift, @prefix, c
  forEach: (f) -> for child in @items
    child.forEach f
  reduceNoArg: (f) -> @items[1..].reduce ((a, child) -> child.reduceArg f, a), @items[0].reduceNoArg f
  reduceArg: (f, a) -> @items[1..].reduce ((a, child) -> child.reduceArg f, a), @items[0].reduceArg f, a
  dump: -> "AMT(#{@prefix}>>#{@shift} #{(c.dump() for c in @items when c != EMPTY).join ', '})"
  @for: (ch1, ch2) -> shiftAndPrefixFor ch1.prefix, ch2.prefix, (shift, prefix) -> new AMT shift, prefix, itemsFor (ch1.prefix >> shift - 5) & 31, ch1, (ch2.prefix >> shift - 5) & 31, ch2

# for testing

sys=require 'sys'
exports.shiftAndPrefixFor = shiftAndPrefixFor
exports.log2 = log2
exports.countBits = countBits
exports.AMTPrinter = AMTPrinter
