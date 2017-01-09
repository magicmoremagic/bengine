
include 'build/vc_win/lib_config'

local lib_flags = { }
local function ignore () end

function get_lib_flags_var (configured)
   local add_name_suffix, name = make_append_fn('_', nil, { 'lib_flags' })
   configure_lib_flags(configured, ignore, ignore, add_name_suffix)

   name = table.concat(name)
   if not lib_flags[name] then
      local add_option, options = make_append_fn()
      local disable_warning, disabled_warnings = make_append_fn(function (n) return '/IGNORE:' .. n end)

      configure_lib_flags(configured, disable_warning, add_option, ignore)
      table.sort(disabled_warnings)
      add_option(table.concat(disabled_warnings, ' '))
      
      lib_flags[name] = true
      set_global(name, table.concat(options, ' '), lib_flags_global_group)
   end

   return '$' .. name
end

function make_lib_target (configured, input_paths)
   return function (t)
      t.rule = rule 'lib'
      t.outputs = { configured.output_path }
      t.inputs = input_paths
      t.order_only_inputs = { 'init!' }
      t.vars = {
         { name = 'out_file', value = configured.output_filename },
         { name = 'flags', value = get_lib_flags_var(configured) }
      }
      if t.extra then
         t.vars[#t.vars+1] = { name = 'extra', value = t.extra }
      end
      make_target(t)
   end
end
