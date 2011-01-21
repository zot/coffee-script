require './util'
sys = require 'sys'
sys.puts "0: 23, 1: 33, 50: a, 51: b, 5000: 2"
e = (require './amt').EmptyAMT
c = e.put(50, 'a').put(51, 'b').put(0, 23).put(1, 33).put(5000, 2)
sys.puts c
sys.puts c.map (x) -> "floop: #{x}"
sys.puts (e.put(1, [1, 2, 3]).put(2, [4, 5, 6]).flatMap (x) -> x).toString()
