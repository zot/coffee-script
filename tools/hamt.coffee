require './util'
[EmptyAMT, arraySubst] = ((amt) -> [amt.EmptyAMT, amt.arraySubst]) require './amt'
[Some, None] = ((opt) -> [opt.Some, opt.None]) require './option'
doHash = require('./hash').doHash

Undefined = {}.undefined

exports.stringHashFunc = stringHashFunc = (str) -> doHash(str, str.length)

exports.hashFunc = hashFunc = (obj) ->
  switch typeof obj
    when 'string' then stringHashFunc(obj)
    when 'number' then obj
    else (if obj.hashCode then obj.hashCode() else obj.identityHash ?= (Math.random() * 0xFFFFFFFFFFFF) & 0xFFFFFFFF)

addValue = (array, value, cmp) ->
  index = array.findIndex(value)
  if index == -1
    s = array[0...array.length]
    return s.push value
  arraySubst array, index, value

exports.HAMT = class HAMT
  constructor: (@hash = hashFunc, @eq = ((a, b) -> a == b), @amt = EmptyAMT) ->
  put: (key, value) -> new HAMT(@hash, @eq, @amt.put @hash(key), (@amt.get(@hash(key)).noneSome (->[[key, value]]), ((v) -> addValue(v, [key, value], @eq))))
  get: (key) -> (mofor
    pairs in @amt.get(@hash key)
    x in pairs.find((x) -> x[0] == key)
      x[1])
  remove: (key) ->
    hash = @hash key
    @amt.get(hash).noneSome (=> this), (v) =>
      i = v.find (item) => item[0] == key
      if i == -1
        return this
      new HAMT(@hash, @eq, if v.length == 1 then @amt.remove(hash) else @amt.put(hash, v.without(i)))
  toString: -> "HAMT(#{@contents()})"
  contents: -> ([0].flatMap (x) => @amt.flatMap (p) -> p.map (v) -> "#{v[0]}: #{v[1]}").join ', '
