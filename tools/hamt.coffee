# HAMT
#
# TODO: make addValue and put more conservative

require './util'
[AMT, arraySubst] = ((amt) -> [amt.AMT, amt.arraySubst]) require './amt'
[Some, None] = ((opt) -> [opt.Some, opt.None]) require './option'
doHash = require('./hash').doHash

exports.stringHashFunc = stringHashFunc = (str) -> doHash(str, str.length)

exports.hashFunc = hashFunc = (obj) ->
  switch typeof obj
    when 'string' then stringHashFunc(obj)
    when 'number' then obj
    # nonfunctional code here -- maybe store a hash based on the toSource() string?
    else (if obj.hashCode then obj.hashCode() else obj.identityHash ?= (Math.random() * 0xFFFFFFFFFFFF) & 0xFFFFFFFF)

addValue = (array, value, cmp) ->
  index = array.findIndex(value)
  if index == -1
    s = array[0...array.length]
    return s.push value
  arraySubst array, index, value

exports.HAMT = class HAMT
  constructor: (@hash = hashFunc, @eq = ((a, b) -> a == b), @amt = AMT) ->
  put: (key, value) -> new HAMT(@hash, @eq, @amt.put @hash(key), (@amt.get(@hash(key)).noneSome (->[[key, value]]), ((v) -> addValue(v, [key, value], @eq))))
  get: (key) ->
#    sys.puts "hash = #{@hash key}, amt = #{@amt.dump()}"
    mofor
      pairs in (@amt.get @hash key)
      p in pairs.find((x) => @eq x[0], key)
        p[1]
  remove: (key) ->
    hash = @hash key
#    @amt.get(hash).noneSome (=> sys.puts 'none'; this), (pairs) =>
    @amt.get(hash).noneSome (=> this), (pairs) =>
#      sys.puts 'some'
      i = pairs.find (item) => @eq item[0], key
      if i == -1
#        sys.puts 'not found'
        return this
#      new HAMT(@hash, @eq, if v.length == 1 then sys.puts 'with'; @amt.remove(hash) else sys.puts 'without'; @amt.put(hash, v.without(i)))
      new HAMT(@hash, @eq, if v.length == 1 then @amt.remove(hash) else @amt.put(hash, v.without(i)))
  toString: -> "HAMT(#{@contents()})"
  dump: -> "HAMT(#{@amt.dump()})"
  contents: ->
#    ([0].flatMap (x) => @amt.flatMap (pairs) -> pairs.map (pair) -> "#{pair[0]}: #{pair[1]}").join ', '
    (mofor
      _ in [0]
      pairs in @amt
      pair in pairs
        "#{pair[0]}: #{pair[1]}").join ', '


sys=require 'sys'