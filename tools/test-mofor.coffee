sys=require 'sys'

class Context
  value: 3
  test: -> sys.puts (mofor v in [1,2,3]
    v + @value)

(new Context()).test()
