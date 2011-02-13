mofor is a control structure that supports iteration, mapping, and reduction.

Forms:

1. mapping/iteration, single binding

    mofor var in value
      statement
      ...

1. mapping/iteration, multiple bindings (variables are optional) and filters

    mofor
      var1 in value1
      if expression
      value2
      var3 in value3
        statement
	...

1. reduction and filters

    mofor var [in expr] do
      [var1 in] value1
      if expression
      [var2 in] value2
      var.message arg1, arg2

If the first two forms are used as an expression, they use mapping (map, flatMap).  If used as a statement, they use iteration (forEach).

