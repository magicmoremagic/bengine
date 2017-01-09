
make_rule 'rc' {
   command = table.concat ({
      'rc',
      '/nologo',
      '$extra',
      serialize_includes {
         include_dir(),
         deps_dir(),
         ext_include_dir(),
         nil
      },
      '/fo"$out"',
      '"$in"'
   }, ' '),
   description = 'rc $in',
   deps = 'msvc'
}

function make_rc_target (res_path, rc_path)
   if not res_path then error 'icon .res path not specified!' end
   if not rc_path then error 'icon .rc path not specified!' end
   return function (t)
      t.rule = rule 'rc'
      t.inputs = { rc_path }
      t.order_only_inputs = { 'init!' }
      t.outputs = { res_path }
      return make_target(t)
   end
end
