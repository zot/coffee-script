{puts}=require 'sys'
{test, assertEq} = require './util'
{Some,None} = require './option'
{HAMT, stringHashFunc}=require('./hamt')
{setBitset, itemsRemove, n2,itemsAdd,AMT}=require('./amt')
t=null
e = (error) ->
  puts error.stack
  if t
    puts "t: #{t}"
    puts "t.dump(): #{t.dump()}"
testEq = (a, b) -> test e, -> assertEq a, b
testSt = (a, b) -> testEq a.toString(), b.toString()
puts "AMT TESTS"
s=[1]
s.bitset = 1
testSt '1,2', (itemsAdd s, 2)
testEq 3, (itemsAdd s, 2).bitset
testSt '1,2,3', (itemsAdd (itemsAdd s, 2), 3)
testEq 7, (itemsAdd (itemsAdd s, 2), 3).bitset
testSt '0,2,3', itemsRemove(itemsAdd(itemsAdd(itemsAdd(itemsAdd(setBitset([], 0), 0), 1), 2), 3), 1)
testSt 'AMT(1)', AMT.add(1)
testSt 'AMT(1, 2)', AMT.add(1).add(2)
testSt 'AMT(1, 3840: 2)', AMT.put(0, 1).put(0xF00, 2)
testSt 'AMT(1, 3840: 2, 3)', AMT.put(0, 1).put(0xF00, 2).add(3)
testSt 'AMT(1, 3840: 2, 3, 4)', AMT.put(0, 1).put(0xF00, 2).add(3).add(4)
testSt 'AMT(1, 3840: 2, 61440: 3, -268435456: 4)', AMT.put(0, 1).put(0xF00, 2).put(0xF000, 3).put(0xF0000000,4)
testSt 'AMT(1, 3840: 2, 61440: 3, -268435456: 4, 5)', AMT.put(0, 1).put(0xF00, 2).put(0xF000, 3).put(0xF0000000,4).add(5)
testSt 'AMT(0>>>35|1001 0|0: AMT(0>>>20|11 0|0: AMT(0>>>15|1001 0|0: AMTLeaf(0|1 0|0: 1), 3072|3: AMTLeaf(3840|1 3840|0: 2)), 32768|1: AMTLeaf(61440|1 61440|0: 3)), -1073741824|3: AMTLeaf(-268435456|1 -268435456|0: 4))', AMT.put(0, 1).put(0xF00, 2).put(0xF000, 3).put(0xF0000000,4).dump()
testEq 10, AMT.put(0, 1).put(0xF00, 2).put(0xF000, 3).put(0xF0000000,4).reduce ((i, el) -> i + el), 0
testSt 'AMT(2, 3, 4, 5)', AMT.put(0, 1).put(0xF00, 2).put(0xF000, 3).put(0xF0000000,4).flatMap((i) -> [i + 1])
testSt 'AMT(1, 2, 3, 4, 5)', AMT.add(1).add(2).add(3).add(4).add(5)
testSt 'AMT(1, 2, 3: 4, 5)', AMT.add(1).add(2).add(3).add(4).add(5).remove(2)
testSt 'AMT(626045324: 1, 754329161: 2)', AMT.put(626045324, 1).put(754329161, 2)
testSt 'AMT(626045324: 1)', AMT.put(626045324, 1).put(754329161, 2).remove(754329161)
puts "HAMT TESTS"
testEq Some(1), (t = new HAMT().put('a', 1)).get('a')
testEq Some(1), (t = new HAMT().put('a', 1).put('b', 2)).get('a')
testEq Some(2), (t = new HAMT().put('a', 1).put('b', 2)).get('b')
testEq Some(1), (t = new HAMT().put('a', 1).put('b', 2).put('c', 4)).get('a')
testEq Some(2), (t = new HAMT().put('a', 1).put('b', 2).put('c', 4)).get('b')
testEq Some(4), (t = new HAMT().put('b', 2).put('c', 4)).get('c')
testEq Some(4), (t = new HAMT().put('a', 1).put('b', 2).put('c', 4)).get('c')
testSt 'HAMT(a: 1, b: 2, c: 4)', (t = new HAMT().put('a', 1).put('b', 2).put('c', 4))
testSt 'HAMT(a: 1, c: 4)', t = new HAMT().put('a', 1).put('b', 2).put('c', 4).remove('b')
testSt 'HAMT(c: 4)', t = new HAMT().put('a', 1).put('b', 2).put('c', 4).remove('b').remove('a')
puts "DONE"