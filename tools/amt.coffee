# AMT (Array Mapped Tree) -- high-to-low shifting, to preserve order
# Very much like an array mapped trie, but this isn't a trie; the data is all in leaf nodes
# It supports path compression so that there won't be any inner nodes with only one child (single children "bubble up")
# TODO: combine prefix and shift?

{Some, None} = require './option'
{Cons, Nil} = require './list'
{SimpleMonad} = require './monad'
require './util'

#### compressed arrays
#### array with a bitset value to indicate which of the 32 potential elements have values

#create a new array with a value substitution
exports.arraySubst = arraySubst = (a, i, v) ->
  newArray = a[0...a.length]
  newArray[i] = v
  setBitset newArray, a.bitset

countBits = (x) ->
  # from http://bits.stephan-brumme.com/countBits.html
  x -= (x >>> 1) & 0x55555555
  x = (x & 0x33333333) + ((x >>> 2) & 0x33333333)
  (((x + (x >>> 4)) & 0xF0F0F0F) * 0x01010101) >>> 24

lowestOneBit = (x) -> x & -x

MultiplyDeBruijnBitPosition = [
  0, 9, 1, 10, 13, 21, 2, 29, 11, 14, 16, 18, 22, 25, 3, 30,
  8, 12, 20, 28, 15, 17, 24, 7, 19, 27, 23, 6, 26, 5, 4, 31
]

log2 = (v) ->
  v |= v >> 1 # first round down to one less than a power of 2
  v |= v >> 2
  v |= v >> 4
  v |= v >> 8
  v |= v >> 16
  MultiplyDeBruijnBitPosition[(v * 0x07C4ACDD) >>> 27]

MultiplyDeBruijnBitPosition2 = [
  0, 1, 28, 2, 29, 14, 24, 3, 30, 22, 20, 15, 25, 17, 4, 8,
  31, 27, 13, 23, 21, 19, 16, 7, 26, 12, 18, 6, 11, 5, 10, 9
]

evenLog2 = (v) -> MultiplyDeBruijnBitPosition2[(v * 0x077CB531) >>> 27]

trailingZeroes = (x) -> evenLog2 x & -x

exports.n2 = nextPowerOf2 = (v) ->
  v--
  v |= v >>> 1
  v |= v >>> 2
  v |= v >>> 4
  v |= v >>> 8
  v |= v >>> 16
  ++v

setBitset = (array, bitset) -> array.bitset = bitset; array

itemsGet = (values, index) -> values[countBits ((1 << index) - 1) & values.bitset]

# itemsFor = (i1, v1, i2, v2) -> if i1 <= i2 then setBitset [v1, v2], (1 << i1) | (1 << i2) else itemsFor i2, v2, i1, v1

itemsSet = (values, index, value) ->
  member = 1 << index
  pos = countBits (member - 1) & values.bitset
  return arraySubst values, pos, value if member & values.bitset
  n = values[0...values.length]
  n.splice pos, 0, value
  setBitset n, values.bitset | member

itemsSetLast = (values, value) ->
  n = values[0...values.length]
  n[n.length - 1] = value
  setBitset n, values.bitset

itemsHas = (values, index) -> values.bitset & (1 << index)

itemsRemove = (values, index) ->
  member = 1 << index
  return values if !(member & values.bitset)
  n = values[0...values.length]
  n.splice countBits(values.bitset & (member - 1)), 1
  setBitset n, values.bitset & ~member

itemsDo = (values, f) ->
  set = values.bitset
  pos = 0
  while set
    b = lowestOneBit set
    f values[pos], evenLog2 b
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

itemsReduceArg = (values, f, v, set, pos) -> if !set then v else b = lowestOneBit set; itemsReduceArg values, f, f(v, values[pos], evenLog2 b), set & ~b, pos + 1

exports.itemsAdd = itemsAdd = (items, v) ->
  i = items[...items.length]
  i.splice i.length, 0, v
  setBitset i, items.bitset | (nextPowerOf2 items.bitset + 1)

#shiftAndPrefixFor = (pf1, pf2, resultFunc) ->
#  for shift in [5..30] by 5
#    if (pf1 & ~((1 << shift) - 1)) == (pf2 & ~((1 << shift) - 1))
#      return resultFunc shift, pf1 & ~((1 << shift) - 1)
#  resultFunc 32, 0


#### AMT DEFS

# BasicAMTs have
# @prefix -- the bit prefix of the subtree's item indices
# @items -- the children or values
class BasicAMT
  # if the value fits in the current tree, return null
  # otherwise, return a new subtree, containing the current tree and a new leaf
  newSubtree: (add, i, v) -> if !add then this else AMT.for this, AMTLeaf.for i, v
  put: (i, v) -> @mod true, i, v
  remove: (i) -> @mod false, i
  add: (v) -> if t = @subadd v or this instanceof AMTLeaf or this.shift == 35 then t else @put @prefix | (((log2 @items.bitset) + 1) << (shift - 5)), v
  flatMap: (f) -> @reduce ((tree, item, index) -> (f item, index).reduce ((tree, item) -> tree.add item), tree), EMPTY
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


exports.AMTLeaf = class AMTLeaf extends BasicAMT
  # shift is always 5
  constructor: (@prefix, @items) ->
  inSubtree: (i) -> (i & ~31) == @prefix
  get: (i) -> if (i & ~31) == @prefix and itemsHas @items, i then Some(itemsGet @items, i) else None
  mod: (add, i, v) ->
    if !@inSubtree i then @newSubtree add, i, v
    else if add == (itemsHas @items, i) and (!add or v == itemsGet @items, i) then this
#    else if add then sys.puts "Leaf mod, i: #{i & 31}"; new AMTLeaf @prefix, itemsSet @items, i, v
    else if add then new AMTLeaf @prefix, itemsSet @items, i, v
    else if @items.length == 1 then EMPTY
    else new AMTLeaf @prefix, itemsRemove @items, i
  subadd: (v) -> if @items.bitset & 0x80000000 then null else new AMTLeaf @prefix, itemsAdd @items, v
  # maps on the options in entries; f should return an option (allows removal)
  map: (f) -> new AMTLeaf @prefix, itemsMap @items, (v, i) => f v, @prefix | i
  filter: (f) ->
    newEntries = itemsFilter @items, (v, i) => f v, @prefix | i
    if !newEntries.length then EMPTY else if newEntries.length == @items.length then this else new AMTLeaf @prefix, newEntries
  reduceNoArg: (f) -> itemsReduceRest @items, ((a, v, i) => f a, v, @prefix | i), @items[0]
  reduceArg: (f, a) -> itemsReduceRest @items, ((a, v, i) => f a, v, @prefix | i), f a, @items[0], @prefix | trailingZeroes @items.bitset
  forEach: (f) -> itemsDo @items, (v, i) => f v, @prefix | i
  dump: -> "AMTLeaf(#{@prefix}|#{@items.bitset.toString(2)} #{(itemsMap @items, (v, i) => "#{@prefix | i}|#{i}: #{v}").join ', '})"
#  @for = (i, v) -> sys.puts "Leaf for, i: #{i & 31}"; new AMTLeaf i & ~31, setBitset [v], 1 << (i & 31)
  @for = (i, v) -> new AMTLeaf i & ~31, setBitset [v], 1 << (i & 31)

exports.AMT = EMPTY = new AMTLeaf -1, setBitset [], 0
EMPTY.mod = (add, i, v) -> if add then AMTLeaf.for i, v else this
EMPTY.dump = -> "EMPTY"
EMPTY.add = (v) -> AMTLeaf.for 0, v

class AMT extends BasicAMT
  constructor: (@shift, @prefix, @items) ->
  inSubtree: (i) -> @shift == 35 or (i & ~((1 << @shift) - 1)) == @prefix
  childIndex: (i) -> (i >>> @shift - 5) & 31
#  get: (i) -> if @inSubtree i and itemsHas @items, (ind = @childIndex i) then sys.puts "#{i} in subtree, index = #{ind}, bitset = #{@items.bitset.toString(2)}, prefix = #{@prefix}"; (itemsGet @items, ind).get i else sys.puts "#{i} not in subtree"; None
  get: (i) -> if @inSubtree i and itemsHas @items, (ind = @childIndex i) then (itemsGet @items, ind).get i else None
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
  subadd: (v) ->
    if c = @items[@items.length - 1].add v then new AMT @shift, @prefix, itemsSetLast @items, c
    else if @items.bitset & 0x80000000 then null
    else @put @prefix | ((evenLog2 nextPowerOf2 @items.bitset + 1) << (shift - 5)), v
  map: (f) -> new AMT @shift, @prefix, setBitset (v.map f for v in @items), @items.bitset
  filter: (f) ->
    c = itemsFilter @items, (v) => (v.filter f) != EMPTY
    if !c.length then EMPTY else if c.length == 1 then c[0] else if c.length == @items.length then this else AMT @shift, @prefix, c
  forEach: (f) -> for child in @items
    child.forEach f
  reduceNoArg: (f) -> @items[1..].reduce ((a, child) -> child.reduceArg f, a), @items[0].reduceNoArg f
  reduceArg: (f, a) -> @items[1..].reduce ((a, child) -> child.reduceArg f, a), @items[0].reduceArg f, a
#  dump: -> "AMT(#{@prefix}>>>#{@shift}|#{@items.bitset.toString(2)} #{(c.dump() for c in @items).join ', '})"
  dump: -> "AMT(#{@prefix}>>>#{@shift}|#{@items.bitset.toString(2)} #{(itemsMap @items, (c, i) => "#{@prefix | i}|#{i}: #{c.dump()}").join ', '})"
#  @for: (ch1, ch2) -> shiftAndPrefixFor ch1.prefix, ch2.prefix, 10, (shift, prefix) -> new AMT shift, prefix, itemsFor (ch1.prefix >>> shift - 5) & 31, ch1, (ch2.prefix >>> shift - 5) & 31, ch2
  @for: (c1, c2) -> @forImpl c1, c2, 10
  @forImpl: (c1, c2, shift) ->
    s = if shift < 32 then ~((1 << shift) - 1) else 0
    p = c1.prefix & s
    if p != (c2.prefix & s)
      return @forImpl c1, c2, shift + 5
    i1 = (c1.prefix >>> (shift - 5)) & 31
    i2 = (c2.prefix >>> (shift - 5)) & 31
#    sys.puts "AMT, i1: #{i1}, i2: #{i2}"
    new AMT shift, p, setBitset (if i1 < i2 then [c1, c2] else [c2, c1]), (1 << i1) | (1 << i2)


# for testing

sys=require 'sys'
#exports.shiftAndPrefixFor = shiftAndPrefixFor
exports.evenLog2 = evenLog2
exports.countBits = countBits
exports.AMTPrinter = AMTPrinter
