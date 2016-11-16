# hindley-milner-playground
(Web-)REPL for the HM type system

- [x] Console REPL
- [ ] Web
- [ ] Deploy
- [ ] Fix

# Usage
``./hm.rb '\x -> \y -> let f = if (x == y) in f 10 20``

    \x -> \y -> (let f = (if ((== x) y)) in ((f 10) 20))
    Inferred type: x_0 -> y_0 -> #app_4,
      with constraints:
      (Int -> Int -> Bool) ~ (x_0 -> #app_0)
      (#app_0) ~ (y_0 -> #app_1)
      (Bool -> a_0 -> a_0 -> a_0) ~ (#app_1 -> #app_2)
      (#app_2) ~ (Int -> #app_3)
      (#app_3) ~ (Int -> #app_4)

    Final inferred type: Int -> Int -> Int
