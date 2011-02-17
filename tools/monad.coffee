class ReductionGizmo
  reduce: (f, v) -> f this, this
  filter: (f) -> if f this then this else
    t = this
    reduce: (f, v) -> t
    filter: (f) -> this

# a monad constructed from an object with an object to hold state and a single state transition method
class StateGizmo extends ReductionGizmo
  constructor: (@state, f) ->
    @f = (args...) -> new StateGizmo f(@state, args...), f

exports.state = (arg, f) -> new StateGizmo arg, f
exports.ReductionGizmo = ReductionGizmo
