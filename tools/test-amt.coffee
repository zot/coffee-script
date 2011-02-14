{assertEq} = require './util'
sys = require 'sys'
{AMTPrinter, log2, countBits, shiftAndPrefixFor, AMT, AMTLeaf} = require './amt'
{Some,None} = require 'option'
{Nil} = require './list'

# old verification code
sys.puts "bit counting"
for nums in [[0..15], -v for v in [0..15]]
  for v in nums
    sys.puts "#{v.toString(16)}(#{(v >>> 0).toString(16)}): #{countBits v}"
sys.puts "0: 23, 1: 33, 50: a, 51: b, 5000: 2"
sys.puts shiftAndPrefixFor 0xFA, 0xFB, (s, p) -> s
sys.puts shiftAndPrefixFor 0xFFFFFFFF, 0x00000000, (s, p) -> s
sys.puts "test AMTPrinter"
sys.puts (mofor p in (new AMTPrinter 0, Nil) do
  p.print 0, 'a'
  p.print 1, 'b'
  p.print 3, 'c'
  p.print 4, 'd').toString()
sys.puts AMT.dump()
sys.puts (AMTLeaf.for 50, 'a').dump()
sys.puts (AMTLeaf.for 50, 'a').items.bitset
sys.puts log2 (AMTLeaf.for 50, 'a').items.bitset
sys.puts AMT.put(50, 'a').dump()
sys.puts "1"
sys.puts AMT.put(50, 'a').put(51, 'b').inSubtree 0
sys.puts "2"
sys.puts AMT.put(50, 'a').put(51, 'b').dump()
sys.puts "3"
AMT.put(50, 'a').put(51, 'b').put(0, 23).forEach (v, i) -> sys.puts "#{i}: #{v}"
c = AMT.put(50, 'a').put(51, 'b').put(0, 23)
sys.puts "4"
sys.puts c.constructor
sys.puts "5"
mofor v, i in AMT.put(50, 'a').put(51, 'b').put(0, 23)
  sys.puts "  #{i}: #{v}"
sys.puts "6"
c = AMT.put(50, 'a').put(51, 'b')
sys.puts c.dump()
c.forEach (v, i) -> sys.puts "#{i}: #{v}"
sys.puts "7"
d = c.put(0, 23)
sys.puts "8"
sys.puts d.dump()
sys.puts d.items.length
sys.puts d.items[0].dump()
sys.puts d.items[1].dump()
sys.puts c.dump()
sys.puts "9"
sys.puts "creating 0: 23, 1: 33, 50: a, 51: b, 5000: 2"
c = AMT.put(50, 'a').put(51, 'b').put(0, 23).put(1, 33).put(5000, 2)
sys.puts "9.1"
sys.puts c
sys.puts "9.2"
sys.puts c.dump()
sys.puts "10"
sys.puts c.map (x) -> "floop - #{x}"
sys.puts AMT.put(1, [1, 2, 3]).put(2, [4, 5, 6]).dump()
sys.puts AMT.put(1, [1, 2, 3]).put(2, [4, 5, 6]).items.bitset
sys.puts AMT.put(1, [1, 2, 3]).put(2, [4, 5, 6]).reduce ((a, x, i) -> sys.puts "reduce: #{i}: #{x}"; x), 0
sys.puts (AMT.put(1, [1, 2, 3]).put(2, [4, 5, 6]).flatMap (x) -> sys.puts "FLAT MAP: #{x}"; x).toString()
#sys.puts shiftAndPrefixFor [0, 32]
#sys.puts shiftAndPrefixFor [0, 32, 64]
sys.puts (AMTLeaf.for 33, 3).prefix
(AMTLeaf.for 33, 3).forEach (v, i) -> sys.puts "index: #{i}"
sys.puts "AMTs"
sys.puts AMT.put(1, 'a')
sys.puts AMT.put(1, 'a').put(2, 'b')
sys.puts AMT.put(1, 'a').put(2, 'b').put(33, 'c')
sys.puts AMT.put(1, 'a').put(2, 'b').put(33, 'c').dump()
sys.puts "11"
sys.puts AMT.put(2, 'b').put(33, 'c').put(65, 'd')
sys.puts "12"
sys.puts AMT.put(1, 'a').put(2, 'b').put(33, 'c').put(65, 'd')
sys.puts AMT.put(1, 'a').put(2, 'b').put(33, 'c').put(65, 'd').filter (v, i) -> sys.puts "FILTER v: #{v}, i: #{i}"; i != 2

sys.puts "details"
sys.puts AMT.put(33, 'c').put(65, 'd').dump()
sys.puts AMT.put(1, 'a').put(2, 'b').put(33, 'c').put(65, 'd').put(36, 'e').put(70, 'f')
sys.puts AMT.put(33, 'c').put(65, 'd').put(36, 'e')
sys.puts AMT.put(33, 'c').put(65, 'd').dump()
sys.puts AMT.put(33, 'c').put(65, 'd').put(36, 'e').dump()
#sys.puts AMT.putMutable(1, 'a').putMutable(2, 'b').putMutable(33, 'c').putMutable(65, 'd').putMutable(36, 'e').putMutable(70, 'f').dump()

# tests
sys.puts "\nSTARTING TESTS"
assertEq Some('a'), AMT.put(626045324, 'a').get(626045324)
sys.puts "\nDONE WITH TESTS"