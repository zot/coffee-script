class SimpleMonad
  reduce: (f, v) -> f this, this

# a monad constructed from an object with an object to hold state and a single state transition method
class FMonad extends SimpleMonad
  constructor: (arg, f) ->
    this[p] = v for p, v of arg
    @ff = f
    @f = (args...) -> new FMonad @ff(args...), f

exports.fmonad = (arg, f) -> new FMonad arg, f
exports.SimpleMonad = SimpleMonad
