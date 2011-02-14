sys=require 'sys'
{test, assertEq} = require './util'
{Some,None} = require './option'
{HAMT, stringHashFunc}=require('./hamt')
{n2,itemsAdd,AMT}=require('./amt')
t=null
e = (error) ->
  sys.puts error.stack
  if t
    sys.puts "t: #{t}"
    sys.puts "t.dump(): #{t.dump()}"
testEq = (a, b) -> test e, -> assertEq a, b
sys.puts "AMT TESTS"
s=[1]
s.bitset = 1
testEq '1,2', (itemsAdd s, 2).toString()
testEq 3, (itemsAdd s, 2).bitset
testEq '1,2,3', (itemsAdd (itemsAdd s, 2), 3).toString()
testEq 7, (itemsAdd (itemsAdd s, 2), 3).bitset
testEq 'AMT(1)', AMT.add(1).toString()
testEq 'AMT(1, 2)', AMT.add(1).add(2).toString()
testEq 'AMT(1, 3840: 2)', AMT.put(0, 1).put(0xF00, 2).toString()
testEq 'AMT(1, 3840: 2, 3)', AMT.put(0, 1).put(0xF00, 2).add(3).toString()
testEq 'AMT(1, 3840: 2, 3, 4)', AMT.put(0, 1).put(0xF00, 2).add(3).add(4).toString()
testEq 'AMT(1, 3840: 2, 61440: 3, -268435456: 4)', AMT.put(0, 1).put(0xF00, 2).put(0xF000, 3).put(0xF0000000,4).toString()
testEq 'AMT(1, 3840: 2, 61440: 3, -268435456: 4, 5)', AMT.put(0, 1).put(0xF00, 2).put(0xF000, 3).put(0xF0000000,4).add(5).toString()
testEq 'AMT(0>>>35|1001 0|0: AMT(0>>>20|11 0|0: AMT(0>>>15|1001 0|0: AMTLeaf(0|1 0|0: 1), 3|3: AMTLeaf(3840|1 3840|0: 2)), 1|1: AMTLeaf(61440|1 61440|0: 3)), 3|3: AMTLeaf(-268435456|1 -268435456|0: 4))', AMT.put(0, 1).put(0xF00, 2).put(0xF000, 3).put(0xF0000000,4).dump()
testEq 10, AMT.put(0, 1).put(0xF00, 2).put(0xF000, 3).put(0xF0000000,4).reduce ((i, el) -> i + el), 0
testEq 'AMT(2, 3, 4, 5)', AMT.put(0, 1).put(0xF00, 2).put(0xF000, 3).put(0xF0000000,4).flatMap((i) -> [i + 1]).toString()
sys.puts "HAMT TESTS"
testEq Some(1), (t = new HAMT().put('a', 1)).get('a')
testEq Some(1), (t = new HAMT().put('a', 1).put('b', 2)).get('a')
testEq Some(2), (t = new HAMT().put('a', 1).put('b', 2)).get('b')
testEq Some(1), (t = new HAMT().put('a', 1).put('b', 2).put('c', 4)).get('a')
testEq Some(2), (t = new HAMT().put('a', 1).put('b', 2).put('c', 4)).get('b')
testEq Some(4), (t = new HAMT().put('b', 2).put('c', 4)).get('c')
testEq Some(4), (t = new HAMT().put('a', 1).put('b', 2).put('c', 4)).get('c')
testEq 'HAMT(a: 1, b: 2, c: 4)', (t = new HAMT().put('a', 1).put('b', 2).put('c', 4)).toString()
sys.puts 1
sys.puts (t = new HAMT().put('a', 1).put('b', 2).put('c', 4).remove('b').remove('a'))
