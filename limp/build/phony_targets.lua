
function make_phony_target (target)
   return function (t)
      t.rule = rule 'phony'
      t.outputs = { target }
      return make_target(t)
   end
end
