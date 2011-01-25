require './util'
sys = require 'sys'
{Some, None} = require './option'
sys.puts "0: 23, 1: 33, 50: a, 51: b, 5000: 2"
{AMT, shiftPrefixFor, AMTLeaf} = require './amt'
e = EMPTY = AMT
c = e.put(50, 'a').put(51, 'b').put(0, 23).put(1, 33).put(5000, 2)
sys.puts c
sys.puts c.map (x) -> "floop: #{x}"
sys.puts (e.put(1, [1, 2, 3]).put(2, [4, 5, 6]).flatMap (x) -> x).toString()
sys.puts shiftPrefixFor [0, 32]
sys.puts shiftPrefixFor [0, 32, 64]
sys.puts (AMTLeaf.forOpt 33, Some(3)).prefix
(AMTLeaf.forOpt 33, Some(3)).forEach (v, i) -> sys.puts "index: #{i}"
sys.puts "AMTs"
sys.puts EMPTY.put(1, 'a')
sys.puts EMPTY.put(1, 'a').put(2, 'b')
sys.puts EMPTY.put(1, 'a').put(2, 'b').put(33, 'c')
sys.puts EMPTY.put(1, 'a').put(2, 'b').put(33, 'c').put(65, 'd')
sys.puts EMPTY.put(1, 'a').put(2, 'b').put(33, 'c').put(65, 'd').filter (v, i) -> i != 2

sys.puts "details"
sys.puts EMPTY.put(33, 'c').put(65, 'd').dump()
sys.puts EMPTY.put(1, 'a').put(2, 'b').put(33, 'c').put(65, 'd').put(36, 'e').put(70, 'f').dump()
sys.puts EMPTY.putMutable(1, 'a').putMutable(2, 'b').putMutable(33, 'c').putMutable(65, 'd').putMutable(36, 'e').putMutable(70, 'f').dump()
