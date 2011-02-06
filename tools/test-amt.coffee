require './util'
sys = require 'sys'
{AMTPrinter, log2, countBits, shiftAndPrefixFor, AMT, AMTLeaf} = require './amt'
{Nil} = require './list'
sys.puts "bit counting"
for nums in [[0..15], -v for v in [0..15]]
  for v in nums
    sys.puts "#{v.toString(16)}(#{(v >>> 0).toString(16)}): #{countBits v}"
sys.puts "0: 23, 1: 33, 50: a, 51: b, 5000: 2"
sys.puts shiftAndPrefixFor 0xFA, 0xFB, (s, p) -> s
sys.puts shiftAndPrefixFor 0xFFFFFFFF, 0x00000000, (s, p) -> s
e = EMPTY = AMT
sys.puts "test AMTPrinter"
sys.puts (mofor p in (new AMTPrinter 0, Nil) do
  p.print 0, 'a'
  p.print 1, 'b'
  p.print 3, 'c'
  p.print 4, 'd').toString()
sys.puts EMPTY.dump()
sys.puts (AMTLeaf.for 50, 'a').dump()
sys.puts (AMTLeaf.for 50, 'a').items.bitset
sys.puts log2 (AMTLeaf.for 50, 'a').items.bitset
sys.puts EMPTY.put(50, 'a').dump()
sys.puts "1"
sys.puts EMPTY.put(50, 'a').put(51, 'b').inSubtree 0
sys.puts "2"
sys.puts EMPTY.put(50, 'a').put(51, 'b').dump()
sys.puts "3"
#EMPTY.put(50, 'a').put(51, 'b').put(0, 23).forEach (i, v) -> sys.puts "#{i}: #{v}"
c = EMPTY.put(50, 'a').put(51, 'b').put(0, 23)
sys.puts "4"
sys.puts c.constructor
sys.puts "5"
mofor v, i in EMPTY.put(50, 'a').put(51, 'b').put(0, 23)
  sys.puts "  #{i}: #{v}"
sys.puts "6"
sys.puts EMPTY.put(50, 'a').put(51, 'b').put(0, 23).dump()
c = e.put(50, 'a').put(51, 'b').put(0, 23).put(1, 33).put(5000, 2)
sys.puts c
sys.puts c.map (x) -> "floop - #{x}"
sys.puts e.put(1, [1, 2, 3]).put(2, [4, 5, 6]).dump()
sys.puts e.put(1, [1, 2, 3]).put(2, [4, 5, 6]).items.bitset
sys.puts e.put(1, [1, 2, 3]).put(2, [4, 5, 6]).reduce ((a, x, i) -> sys.puts "reduce: #{i}: #{x}"; x), 0
sys.puts (e.put(1, [1, 2, 3]).put(2, [4, 5, 6]).flatMap (x) -> sys.puts "FLAT MAP: #{x}"; x).toString()
#sys.puts shiftAndPrefixFor [0, 32]
#sys.puts shiftAndPrefixFor [0, 32, 64]
sys.puts (AMTLeaf.for 33, 3).prefix
(AMTLeaf.for 33, 3).forEach (v, i) -> sys.puts "index: #{i}"
sys.puts "AMTs"
sys.puts EMPTY.put(1, 'a')
sys.puts EMPTY.put(1, 'a').put(2, 'b')
sys.puts EMPTY.put(1, 'a').put(2, 'b').put(33, 'c')
sys.puts EMPTY.put(1, 'a').put(2, 'b').put(33, 'c').put(65, 'd')
sys.puts EMPTY.put(1, 'a').put(2, 'b').put(33, 'c').put(65, 'd').filter (v, i) -> sys.puts "FILTER v: #{v}, i: #{i}"; i != 2

sys.puts "details"
sys.puts EMPTY.put(33, 'c').put(65, 'd').dump()
sys.puts EMPTY.put(1, 'a').put(2, 'b').put(33, 'c').put(65, 'd').put(36, 'e').put(70, 'f').dump()
sys.puts EMPTY.putMutable(1, 'a').putMutable(2, 'b').putMutable(33, 'c').putMutable(65, 'd').putMutable(36, 'e').putMutable(70, 'f').dump()
