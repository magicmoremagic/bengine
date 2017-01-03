make_global('rccmd', 'rc', 0)

local rule_name
function make_rc_job (res_path, rc_path, extra, implicit_inputs)
   if not rule_name then
      rule_name = 'rc'
      make_rule(rule_name, '$rccmd /nologo $extra /i"$include_dir" /i"$deps_dir" /i"$ext_include_dir" /fo"$out" "$in"', 'rc $in', { deps = 'msvc' })
   end 

   local vars
   if extra then
      vars = {{ name = 'extra', value = extra }}
   end

   return job {
      rule = rule_name,
      inputs = { rc_path },
      implicit_inputs = implicit_inputs,
      order_only_inputs = { 'init!' },
      outputs = { res_path },
      vars = vars
   }
end
