local table = table
local fs = be.fs

is_windows = true

function parse_source_path (project, src_path)
   return fs.ancestor_relative(fs.canonical(fs.compose_path(project.path, src_path)), root_dir)
end

function get_output_info (project, debug)
   local base = project.name
   if debug then
      base = base .. '-debug'
   end
   local dir, ext
   if project.is_app then
      dir = '$out_dir'
      ext = '.exe'
   elseif project.is_lib then
      dir = '$out_dir'
      ext = '.lib'
   elseif project.is_dyn_lib then
      dir = '$out_dir'
      ext = '.dll'
   elseif project.is_ext_lib then
      dir = '$ext_lib_dir'
      ext = '.lib'
   end
   local file = base .. ext
   local pdb_file = base .. '.pdb'
   local pch_file = base .. '.pch'
   return {
      base = base,
      path = fs.compose_path(dir, file),
      pdb_path = fs.compose_path(dir, pdb_file),
      build_pdb_path = fs.compose_path('$build_dir', pdb_file),
      pch_path = fs.compose_path('$build_dir', pch_file)
   }
end

include 'build/vc_win/shell'
include 'build/vc_win/limp'
include 'build/vc_win/custom'
include 'build/vc_win/cl'
include 'build/vc_win/rc'
include 'build/vc_win/lib'
include 'build/vc_win/link'
include 'build/vc_win/icon'
include 'build/vc_win/manifest'
include 'build/vc_win/init'

local function get_project_extra (project)
   local defines = get_project_defines(project)
   local extra = { }
   local n = 0
   for k, v in pairs(defines) do
      n = n + 1
      if v == '' then
         extra[n] = '/D' .. k
      elseif string.find(v, '%s') then
         extra[n] = '/D"' .. k .. '=' .. v .. '"'
      else
         extra[n] = '/D' .. k .. '=' .. v
      end
   end

   table.sort(extra)
   extra = table.concat(extra, ' ')

   if project.include then
      local include_paths = expand_pathspec(project.include, { project.path, root_dir })
      for i = 1, #include_paths do
         local include_path = include_paths[i]
         extra = extra .. ' /I"' .. parse_source_path(project, include_path) .. '"'
      end
   elseif not project.is_ext then
      extra = extra .. ' /I"' .. parse_source_path(project, 'include') .. '"'
   end

   return extra 
end

local get_required_libs
local function get_required_lib (lib_entry, debug, lib_list)
   local lib_name
   if type(lib_entry) == 'string' then
      local lib = projects[lib_entry]
      if lib and not lib.is_app then
         get_required_libs(lib, debug, lib_list)
         lib_list[get_output_info(lib, debug).path] = true -- add to inputs list
         return
      end
      -- external lib 'libname'
      lib_name = lib_entry
   else
      -- external lib { 'debugname', 'releasename' }
      if debug then
         lib_name = lib_entry[1]
      else
         lib_name = lib_entry[2]
      end
   end
   lib_name = fs.replace_extension(lib_name, '.lib')
   lib_list[lib_name] = false -- add to extra list
end

get_required_libs = function (project, debug, lib_list)
   if project.libs then
      for i = 1, #project.libs do
         get_required_lib(project.libs[i], debug, lib_list)
      end
   end
end

local function process_project (project, debug)
   if debug and project.release_only then
      return
   end

   local out = get_output_info(project, debug)
   local clflags = get_clflags_var(project, debug)
   local project_extra = get_project_extra(project)

   if project.limp then
      process_limp_spec(project.limp, { project.path, root_dir })
   end

   if project.custom then
      process_custom_spec(project.custom, { project.path, root_dir })
   end

   local obj_paths = { }

   local nopch_src_files = expand_pathspec(project.src.nopch, { project.path, root_dir })
   for i = 1, #nopch_src_files do
      local src_path = nopch_src_files[i]
      local obj_path = get_obj_path(project, src_path, debug)
      obj_paths[#obj_paths+1] = obj_path
      make_cl_job(obj_path, src_path, out.build_pdb_path, clflags, project_extra, implicit_pch)
   end

   local pch_src_path = project.src.pch
   local implicit_pch
   if pch_src_path then
      pch_src_path = parse_source_path(project, pch_src_path)
      local obj_path = get_obj_path(project, pch_src_path, debug)
      project_extra = project_extra .. ' /Fp"' .. out.pch_path .. '"'
      
      make_cl_job(obj_path, pch_src_path, out.build_pdb_path, clflags, project_extra .. ' /Yc"pch.hpp"')
      make_phony_job(out.pch_path, { obj_path }) -- pch was actually created at the same time as obj

      implicit_pch = { out.pch_path }
      project_extra = project_extra .. ' /Yu"pch.hpp"'
   end

   local src_files = expand_pathspec(project.src, { project.path, root_dir })
   for i = 1, #src_files do
      local src_path = src_files[i]
      local obj_path = get_obj_path(project, src_path, debug)
      obj_paths[#obj_paths+1] = obj_path
      if not pch_src_path or not fs.equivalent(pch_src_path, src_path) then
         make_cl_job(obj_path, src_path, out.build_pdb_path, clflags, project_extra, implicit_pch)
      end
   end

   local targets = { out.path }

   if project.is_lib or project.is_ext_lib then
      make_lib_job(out.path, obj_paths, get_libflags_var(project, debug))
   elseif project.is_app then
      local libs = { }
      local inputs = { }
      local extra_inputs = { }
      get_required_libs(project, debug, libs)

      for lib, is_input in pairs(libs) do
         if is_input then
            inputs[#inputs+1] = lib
         else
            extra_inputs[#extra_inputs+1] = lib
         end
      end
      
      table.sort(inputs)
      table.sort(extra_inputs)

      append_sequence(obj_paths, inputs)

      if project.icon then
         local icon_path = fs.ancestor_relative(fs.glob(project.icon, { project.path, root_dir }, 'f?'), root_dir)
         local icon_rc_path = fs.compose_path('$build_dir', out.base .. '.icon.rc')
         local icon_res_path = fs.compose_path('$build_dir', out.base .. '.icon.res')
         make_icon_rc_job(icon_res_path, icon_rc_path, icon_path)
         inputs[#inputs+1] = icon_res_path
      end

      if project.require_admin then
         inputs[#inputs+1] = get_manifest_target('elevated', true)
      else
         inputs[#inputs+1] = get_manifest_target('default')
      end

      local extra = table.concat(extra_inputs, ' ')

      make_link_job(out.path, out.pdb_path, inputs, debug, get_linkflags_var(project, debug), extra)

      local stage_path = fs.compose_path('$stage_dir', fs.path_filename(out.path))
      make_cp_job(stage_path, out.path)
      targets[#targets+1] = stage_path

      if not debug then
         if project.deploy_bin then
            local deploy_target = 'deploy-' .. out.base .. '!'
            local deploy_path = fs.compose_path('$bin_dir', fs.path_filename(out.path))
            make_deploy_job(deploy_path, stage_path)
            make_phony_job(deploy_target, { deploy_path })
            project.deployment_target = deploy_target
         end
      end
   else
      be.log.warning('Skipping unsupported project type for ' .. project.name)
   end

   make_phony_job(out.base .. '!', targets)

   return out
end

function process_projects ()
   make_rule('configure', '"$bin_dir\\limp.exe" -f "build.ninja"', 'configure', {
      generator = 'true'
   })
   job {
      rule = 'configure',
      outputs = { 'configure!' }
   }

   configure_init()
   configure_clean()

   local ext_targets = { }

   for i = 1, #ordered_projects do
      local project = ordered_projects[i]
      local debug_target = process_project(project, true)
      if debug_target then
         debug_target = debug_target.base .. '!'
      end
      local release_target = process_project(project, false).base .. '!'
      if project.is_ext then
         ext_targets[#ext_targets+1] = project.name .. '!'
         if not project.release_only then
            ext_targets[#ext_targets+1] = project.name .. '-debug!'
         end
      else
         make_phony_job(project.name .. '-full!', { release_target, debug_target })
      end
   end

   if #ext_targets > 0 then
      local target = 'all-ext!'
      make_phony_job(target, ext_targets)
   end

   local debug_group_targets = { }
   local release_group_targets = { }
   local deploy_group_targets = { }

   for i = 1, #ordered_groups do
      local group = ordered_groups[i]

      local debug_targets = { }
      local release_targets = { }
      local deploy_targets = { }

      for i = 1, #group.projects do
         local project = group.projects[i]

         release_targets[#release_targets+1] = project.name .. '!'
         
         if not project.release_only then
            debug_targets[#debug_targets+1] = project.name .. '-debug!'
         end

         if project.deployment_target then
            deploy_targets[#deploy_targets+1] = project.deployment_target
         end
      end

      local full_targets = { }
      
      if #debug_targets > 0 then
         local target = 'all-' .. group.name .. '-debug!'
         make_phony_job(target, debug_targets)
         full_targets[#full_targets+1] = target
         debug_group_targets[#debug_group_targets+1] = target
      end

      if #release_targets > 0 then
         local target = 'all-' .. group.name .. '!'
         make_phony_job(target, release_targets)
         full_targets[#full_targets+1] = target
         release_group_targets[#release_group_targets+1] = target
      end

      if #full_targets > 0 then
         local target = 'all-' .. group.name .. '-full!'
         make_phony_job(target, full_targets)
      end

      if #deploy_targets > 0 then
         local target = 'deploy-all-' .. group.name .. '!'
         make_phony_job(target, deploy_targets)
         deploy_group_targets[#deploy_group_targets+1] = target
      end
   end

   local full_targets = { }

   if #debug_group_targets > 0 then
      local target = 'all-debug!'
      make_phony_job(target, debug_group_targets)
      full_targets[#full_targets+1] = target
   end

   if #release_group_targets > 0 then
      local target = 'all-release!'
      make_phony_job(target, release_group_targets)
      full_targets[#full_targets+1] = target
   end

   if #full_targets > 0 then
      make_phony_job('all-full!', full_targets)
      default_targets = { 'all-full!' }
   end

   if #deploy_group_targets > 0 then
      make_phony_job('deploy!!', deploy_group_targets)
   end

   make_meta_pdb_job('pdb!!')
   make_meta_limp_job('limp!!')
end
