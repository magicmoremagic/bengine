local fs = require('be.fs')

include 'build/vc_win/rules'
include 'build/vc_win/cl'
include 'build/vc_win/rc'
include 'build/vc_win/lib'
include 'build/vc_win/link'
include 'build/vc_win/icon'
include 'build/vc_win/manifest'
include 'build/vc_win/init'

local hooks = { }

make_rule 'configure' {
   command = '"$bin_dir\\limp.exe" -f ' .. fs.ancestor_relative(file_path, root_dir),
   description = 'configure',
   generator = 'true'
}

function hooks.init ()
   make_target {
      rule = rule 'configure',
      outputs = { 'configure!' }
   }
end

function hooks.preprocess_begin ()
   configure_init_begin()
end

function hooks.preprocess_group (configured)
   configure_init_group(configured)
end

function hooks.preprocess_project (configured)
   configure_init_project(configured)

   local ext = ''
   if configured.is_app then
      ext = '.exe'
   elseif configured.is_lib then
      ext = '.lib'
   elseif configured.is_dyn_lib then
      ext = '.dll'
   elseif configured.is_ext_lib then
      ext = '.lib'
   end

   local rel_dir = configured.output_dir
   local abs_dir = configured.output_dir_abs
   local rel_build_dir, abs_build_dir = build_dir()
   local base = configured.output_base

   configured.output_filename = base .. ext
   configured.pdb_filename = base .. '.pdb'
   configured.pch_filename = base .. '.pch'

   configured.output_path = fs.compose_path(rel_dir, configured.output_filename)
   configured.output_path_abs = fs.compose_path(abs_dir, configured.output_filename)

   configured.pdb_path = fs.compose_path(rel_dir, configured.pdb_filename)
   configured.pdb_path_abs = fs.compose_path(abs_dir, configured.pdb_filename)

   configured.build_pdb_path = fs.compose_path(rel_build_dir, configured.pdb_filename)
   configured.build_pdb_path_abs = fs.compose_path(abs_build_dir, configured.pdb_filename)

   configured.pch_path = fs.compose_path(rel_build_dir, configured.pch_filename)
   configured.pch_path_abs = fs.compose_path(abs_build_dir, configured.pch_filename)

   configured.cl_flags = get_cl_flags_var(configured)

   local defines = serialize_defines(configured.define)
   local includes = serialize_includes(configured.include)
   if defines and #defines > 0 and includes and #includes > 0 then
      configured.cl_extra = defines .. ' ' .. includes
   else
      if defines and #defines > 0 then
         configured.cl_extra = defines
      elseif includes and #includes > 0 then
         configured.cl_extra = includes
      end
   end
end

function hooks.preprocess_end ()
   configure_init_end()
   configure_clean()
end

function hooks.process (configured)
   if configured.disabled then
      return
   end

   make_limp_targets(configured)
   make_custom_targets(configured)
   local obj_paths = make_cl_targets(configured)

   if configured.is_lib or configured.is_ext_lib then
      make_lib_target(configured, obj_paths) { }

      return configured.output_path
   end

   if configured.is_app then
      make_link_target(configured, obj_paths) { }
      
      local stage_path = fs.compose_path(stage_dir(), configured.output_filename)
      make_cp_target(stage_path, configured.output_path) { }

      return stage_path
   end

   be.log.warning('Skipping unsupported project type for ' .. configured.name)
end

function hooks.postprocess_begin ()
   make_meta_pdb_target()
end

return hooks
