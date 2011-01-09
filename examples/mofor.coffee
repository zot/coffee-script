sys=require 'sys'
EmptyMonad = (value) ->
Monad = (value) -> this[0] = value
Monad.empty = new EmptyMonad
Monad.flatMap = (subject, func) ->
  res = subject.map(func)
  if res.length == 1
    return res[0]
  else
    ret = []
    for item in res
      for element in item
        ret.push element
    return ret
EmptyMonad.prototype.length = 0
EmptyMonad.prototype.map = (f) -> Monad.empty
EmptyMonad.prototype.filter = (f) -> this
Monad.prototype.length = 1
Monad.prototype.map = (f) -> new Monad(f(this[0]))
Monad.prototype.filter = (f) -> if f(this[0]) then this else Monad.empty
Array.prototype.flatMap = (f) ->
    ret = []
    for item in this.map(f)
      for element in item
        ret.push element
    ret

sys.p 1
sys.p (mofor
  a <- [1,2,3]
  b <- [4,5,6]
  if a % 2 == 0 or b % 2 == 0
->
  [a + 1, b + 1])

sys.p (mofor
  a <- new Monad(3)
->
  a
)
