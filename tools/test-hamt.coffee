sys=require 'sys'
require './util'
HAMT=require('./hamt').HAMT
sys.puts new HAMT().put('a', 1).put('b', 2).put('c', 4).remove('b').remove('a')
