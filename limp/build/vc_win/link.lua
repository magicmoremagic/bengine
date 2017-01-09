local fs = require('be.fs')

local pdb_targets = { }
function make_pdb_target (target, pdb_path)
   return function (t)
      pdb_targets[#pdb_targets+1] = target

      t.rule = rule 'pdb'
      t.inputs = { pdb_path }
      t.outputs = { target }

      return make_target(t)
   end
end

function make_meta_pdb_target ()
   return make_phony_target 'pdb!' {
      inputs = pdb_targets
   }
end


include 'build/vc_win/link_config'

local link_flags = { }
local function ignore () end

function get_link_flags_var (configured, debug)
   local add_name_suffix, name = make_append_fn('_', nil, { 'link_flags' })
   configure_link_flags(configured, ignore, ignore, add_name_suffix)

   name = table.concat(name)
   if not link_flags[name] then
      local add_option, options = make_append_fn()
      local disable_warning, disabled_warnings = make_append_fn(function (n) return '/IGNORE:' .. n end)

      configure_link_flags(configured, disable_warning, add_option, ignore)
      table.sort(disabled_warnings)
      add_option(table.concat(disabled_warnings, ' '))
      
      link_flags[name] = true
      set_global(name, table.concat(options, ' '), link_flags_global_group)
   end

   return '$' .. name
end

function make_link_target (configured, obj_paths)
   return function (t)
      t.rule = rule 'link'
      t.outputs = { configured.output_path }
      t.implicit_outputs = append_sequence({ configured.pdb_path }, t.implicit_outputs)
      t.order_only_inputs = { 'init!' }
      t.inputs = { }
      for i = 1, #configured.link_internal do
         t.inputs[i] = fs.replace_extension(configured.link_internal[i], '.lib')
      end

      table.sort(t.inputs)
      append_sequence(obj_paths, t.inputs)

      if configured.icon then
         local icon_rc_path = fs.compose_path(build_dir(), configured.output_base .. '.icon.rc')
         local icon_res_path = fs.compose_path(build_dir(), configured.output_base .. '.icon.res')
         make_icon_rc_target(icon_res_path, icon_rc_path, configured.icon) { }
         t.inputs[#t.inputs+1] = icon_res_path
      end

      if configured.require_admin then
         t.inputs[#t.inputs+1] = get_manifest_target('elevated', true)
      else
         t.inputs[#t.inputs+1] = get_manifest_target('default')
      end

      local extra = { }
      for i = 1, #configured.link do
         extra[i] = fs.replace_extension(configured.link[i], '.lib')
      end

      t.vars = {
         { name = 'out_file', value = configured.output_filename },
         { name = 'pdb', value = configured.pdb_path },
         { name = 'flags', value = get_link_flags_var(configured) },
         { name = 'extra', value = table.concat(extra, ' ') }
      }

      make_pdb_target(configured.pdb_path .. '!', configured.pdb_path) { }

      return make_target(t)
   end
end
