class SimpleMonad
  reduce: (f, v) -> f this, this
  filter: (f) -> if f this then this else
    t = this
    reduce: (f, v) -> t
    filter: (f) -> this

# a monad constructed from an object with an object to hold state and a single state transition method
class StateMonad extends SimpleMonad
  constructor: (@state, f) ->
    @f = (args...) -> new StateMonad f(@state, args...), f

exports.state = (arg, f) -> new StateMonad arg, f
exports.SimpleMonad = SimpleMonad
