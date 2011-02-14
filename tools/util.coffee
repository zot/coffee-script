sys=require 'sys'

Array.prototype.flatMap = (f) -> this.reduce ((output, item) -> (f item).reduce ((output, item) -> output.push item; output), output), []

Array.prototype.findIndex = (f) ->
  for v, i in this
    if f(v, i)
      return i
  return -1

Array.prototype.without = (d) ->
  a = []
  for v, i in this
    if i != d
      a.push v
  a

exports.equals = equals = (a, b) -> a is b or a?.equals? b

exports.assertEq = (expected, actual, msg) -> if !equals(expected, actual)
  throw new Error("#{if msg then ' ' + msg + ', ' else ''}expected <#{expected}>, but got <#{actual}>")

exports.test = (e, f) ->
  try
    if f then f() else e()
  catch error
    if f then e(error) else sys.puts error.stack
