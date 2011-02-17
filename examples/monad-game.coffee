sys=require 'sys'
{Nil, Cons, List} = require '../tools/list'
{Some, None} = require '../tools/option'
{ReductionGizmo} = require '../tools/monad'

class Game extends ReductionGizmo
  constructor: (@commands = Nil, @pos = None) ->
  map: (f) -> new Game (Cons "END WITH #{f()}", @commands), @pos
  print: (msg) -> new Game (Cons "PRINT #{msg}", @commands), @pos
  move: (x, y) -> new Game (Cons "MOVE (#{x}, #{y})", @commands), Some [x, y]
  toString: -> "Game: #{(mofor
    [0]
    @commands.reverse()
  ).join '\n'}"

sys.puts (mofor game in new Game() do
  game.print "Moving ship"
  mofor do
    x in [1,2,3,4,5]
    y in [1,2,3,4,5]
    if ((x + y) % 3) == 0
    game.print "X = #{x}, Y = #{y}, X + Y % 3 = #{(x + y) % 3}"
    game.move x, y
    p in game.pos
    game.print "MOVED TO: #{p[0]}, #{p[1]}"
  game.print "Done moving ship"
    17)