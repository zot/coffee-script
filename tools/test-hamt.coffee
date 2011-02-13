sys=require 'sys'
require './util'
HAMT=require('./hamt').HAMT
sys.puts new HAMT().put('a', 1).get('a')
sys.puts new HAMT().put('a', 1).put('b', 2).get('a')
sys.puts new HAMT().put('a', 1).put('b', 2).get('b')
sys.puts new HAMT().put('a', 1).put('b', 2).put('c', 4).get('a')
sys.puts new HAMT().put('a', 1).put('b', 2).put('c', 4).get('b')
sys.puts new HAMT().put('a', 1).put('b', 2).put('c', 4).get('c')
sys.puts new HAMT().put('a', 1).put('b', 2).put('c', 4).dump()
sys.puts new HAMT().put('a', 1).put('b', 2).put('c', 4).remove('b').remove('a').dump()
