util = require 'util'
[EmptyAMT, arraySubst] = ((amt) -> [amt.EmptyAMT, amt.arraySubst]) require './amt'
[Some, None] = ((opt) -> [opt.Some, opt.None]) require './option'
doHash = require('./hash').doHash

Undefined = {}.undefined

exports.stringHashFunc = stringHashFunc = (str) -> doHash(str, str.length)

exports.hashFunc = hashFunc = (obj) ->
  switch typeof obj
    when 'string' then stringHashFunc(obj)
    else (if obj.hashCode then obj.hashCode() else obj.identityHash ?= (Math.random() * 0xFFFFFFFFFFFF) & 0xFFFFFFFF)

addValue = (array, value, cmp) ->
  index = array.findIndex(value)
  if index == -1
    s = array[0...array.length]
    return s.push value
  arraySubst array, index, value

exports.HAMT = class HAMT
  constructor: (@hash = hashFunc, @eq = ((a, b) -> a == b), @amt = EmptyAMT) ->

  put: (key, value) -> new HAMT(@hash, @eq, @amt.put @hash(key), @amt.get(key).noneSome (->[[key, value]]), ((v) -> addValue(v, [key, value], @eq)))

  get: (key) -> (mofor
    pairs in @amt.get(@hash key)
    x in pairs.find((x) -> x[0] == key)
      x[1])

  toString: "HAMT(#{@contents})"

  contents: -> (@amt.flatMap (p) -> p.map (v) -> "#{v[0]}: #{v[1]}").join ', '
