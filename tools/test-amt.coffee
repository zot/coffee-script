sys = require 'sys'
sys.puts "0: 23, 1: 33, 50: a, 51: b, 5000: 2"
c = (require './amt').EmptyAMT.put(50, 'a').put(51, 'b').put(0, 23).put(1, 33).put(5000, 2)
sys.puts c
sys.puts c.map (x) -> "floop: #{x}"
