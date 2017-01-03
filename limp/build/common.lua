ninja_dir = ninja_dir or 'ninja'
build_dir = build_dir or 'build'
out_dir = out_dir or 'out'
include_dir = include_dir or 'include'
stage_dir = stage_dir or 'stage'
bin_dir = bin_dir or 'bin'
deps_dir = deps_dir or 'deps'
ext_src_dir = ext_src_dir or 'ext_src'
ext_include_dir = ext_include_dir or 'ext_include'
ext_lib_dir = ext_lib_dir or 'ext_lib'

local table = table
local math = math
local fs = be.fs

register_template_dir(fs.compose_path(limp_dir, 'build', 'template'))

function append_sequence(input, output)
   if not output then
      output = { }
   end

   local n = #output
   for i = 1, #input do
      n = n + 1
      output[n] = input[i]
   end

   return output
end

groups = { }
ordered_groups = { }
projects = { }
ordered_projects = { }
local function group (group, group_type, directory)
   if type(group) ~= 'table' then
      error 'Expected table!'
   end
   if not group.name then
      error 'Group name not specified!'
   end
   if groups[group.name] ~= nil then
      error 'Group name is already in use!'
   end

   group.type = group_type
   if not group.path then
      group.path = fs.compose_path(root_dir, directory, group.name)
   end
   group.path = fs.canonical(group.path)
 
   if group.projects == nil then
      error 'No projects specified!'
   end
   if type(group.projects) ~= 'table' then
      error 'Expected table!'
   end

   for i = 1, #group.projects do
      local project = group.projects[i]
      project.group = group.name

      if not project.name then
         project.name = group.name
         if project.suffix then
            project.name = project.name .. '-' .. project.suffix
         end
      end
      if projects[project.name] ~= nil then
         error 'Project name is already in use!'
      end

      if not project.path then
         project.path = group.path
      else
         project.path = fs.canonical(project.path)
      end

      project.is_lib = project.type == 'lib'
      project.is_app = project.type == 'app'
      project.is_dyn_lib = project.type == 'dyn_lib'
      project.is_ext = false
      project.is_ext_lib = false

      if project.suffix == 'test' or project.suffix == 'perf' then
         project.test_type = project.suffix
      end

      if project.console == nil and not project.gui then
         project.console = true
      end

      be.log.short_verbose('Found ' .. group.type .. ' ' .. project.type .. ' ' .. project.name)
      
      projects[project.name] = project
      ordered_projects[#ordered_projects + 1] = project
   end

   groups[group.name] = group
   ordered_groups[#ordered_groups + 1] = group

   return group
end
function module (t)
   return group(t, 'module', 'modules')
end
function demo (t)
   return group(t, 'demo', 'demos')
end
function tool (t)
   return group(t, 'tool', 'tools')
end

external_deps = { }
function deps (t)
   if type(t) ~= 'table' then
      error 'Expected table!'
   end

   if not t.path then
      t.path = fs.compose_path(root_dir, 'dep_modules')
   end
   t.path = fs.canonical(t.path)

   if type(t.projects) == 'table' then
      for i = 1, #(t.projects) do
         local project = t.projects[i]

         if not project.name then
            error 'External project name not specified'
         end
         if projects[project.name] ~= nil then
            error 'Project name is already in use!'
         end

         if project.path then
            project.path = fs.canonical(fs.compose_path(t.path, project.path))
         else
            project.path = t.path
         end

         project.is_lib = false
         project.is_app = false
         project.is_dyn_lib = false
         project.is_ext = true
         project.is_ext_lib = project.type == 'ext_lib'

         be.log.short_verbose('Found ' .. project.type .. ' ' .. project.name)
         
         projects[project.name] = project
         ordered_projects[#ordered_projects + 1] = project
      end
   end

   external_deps = t
   return t
end

function app (t)
   if type(t) ~= 'table' then error 'Expected table!' end
   t.type = 'app'
   return t
end
function lib (t)
   if type(t) ~= 'table' then error 'Expected table!' end
   t.type = 'lib'
   return t
end
function dyn_lib (t)
   if type(t) ~= 'table' then error 'Expected table!' end
   t.type = 'dyn_lib'
   return t
end

function ext_lib (t)
   if type(t) ~= 'table' then error 'Expected table!' end
   t.type = 'ext_lib'
   return t
end

function get_preprocessor_defines (preprocessor, defines)
   if not defines then
      defines = { }
   end

   if preprocessor then
      for k, v in pairs(preprocessor) do
         if type(k) == 'number' then
            defines[v] = ''
         else
            defines[k] = tostring(v)
         end
      end
   end

   return defines
end

function get_lib_defines (project, defines)
   if not defines then
      defines = { }
   end

   if project.libs then
      for i = 1, #project.libs do
         local lib_entry = project.libs[i]
         if type(lib_entry) == 'string' then
            local lib = projects[lib_entry]
            if lib and lib.is_lib then
               get_lib_defines(lib, defines)
               get_preprocessor_defines(lib.exported_preprocessor, defines)
            end
         end
      end
   end

   return defines
end

function get_project_defines (project, defines)
   if not defines then
      defines = { }
   end

   if not project.is_ext then
      defines.BE_TARGET = project.name
      defines.BE_TARGET_BASE = project.group

      get_lib_defines(project, defines)
   end

   get_preprocessor_defines(project.preprocessor, defines)

   return defines
end

function find_projects (path)
   local abs_path = fs.compose_path(root_dir, path)
   local dirs = table.pack(fs.get_dirs(abs_path))
   for i = 1, #dirs do
      local dir = dirs[i]
      local build_script = fs.compose_path(abs_path, dir, 'build.lua')
      if fs.exists(build_script) then
         dofile(build_script)
      end
   end
end

function expand_pathspec (pathspec, base_path)
   if type(pathspec) == 'table' then
      local paths = { }
      for i = 1, #pathspec do
         local subpaths = expand_pathspec(pathspec[i], base_path)
         for i = 1, #subpaths do
            local subpath = subpaths[i]
            local good = true;
            for i = 1, #paths do
               local path = paths[i]
               if fs.equivalent(path, subpath) then
                  good = false
                  break;
               end
            end
            if good then
               paths[#paths + 1] = subpath
            end
         end
      end
      if pathspec.exclude then
         local excluded_paths = expand_pathspec(pathspec.exclude, base_path)
         local new_paths = { }
         local n = 0
         for i = 1, #paths do
            local path = paths[i]
            local good = true
            for i = 1, #excluded_paths do
               local excluded_path = excluded_paths[i]
               if fs.equivalent(path, excluded_path) then
                  good = false
                  break
               end
            end
            if good then
               n = n + 1
               new_paths[n] = path
            end
         end
         paths = new_paths
      end
      table.sort(paths)
      return paths
   else
      local paths = table.pack(fs.glob(tostring(pathspec), base_path, 'f?'))
      for i = 1, #paths do
         paths[i] = fs.ancestor_relative(paths[i], root_dir)
      end
      table.sort(paths)
      return paths
   end
end

ninja_required_version = 1.5
function require_ninja_version (version)
    ninja_required_version = math.max(ninja_required_version or 0, version)
end

global_groups = { }
globals = { }
function make_global (name, value, group)
   if globals[name] ~= nil then error('A global variable named ' .. name .. ' already exists!') end

   if not group then group = 1 end
   local group_globals = global_groups[group]
   if not group_globals then
      group_globals = { }
      global_groups[group] = group_globals
   end

   local g = { name = name, value = value }
   group_globals[#group_globals + 1] = g
   globals[name] = value
   return g
end

rules = { }
function make_rule (name, command, description, extra_vars)
   local vars = {
      {
         name = 'command',
         value = command
      }
   }

   if description then
      vars[#vars + 1] = {
         name = 'description',
         value = description
      }
   end

   if extra_vars then
      extra_vars.command = nil
      if description then
         extra_vars.description = nil
      end
      for k, v in pairs(extra_vars) do
         vars[#vars + 1] = {
            name = k,
            value = v
         }
      end
   end

   table.sort(vars, function (a, b) return a.name < b.name end)
    
   local rule = {
      name = name,
      vars = vars
   }

   rules[#rules + 1] = rule
   return rule
end

jobs = { }
function job (t)
   if type(t) ~= 'table' then error 'Expected table!' end
   if t.rule == nil then error 'No rule specified for job!' end
   if t.implicit_outputs then require_ninja_version(1.7) end

   jobs[#jobs + 1] = t
   return t
end

function make_phony_job (target, inputs, implicit_inputs)
   return job {
      outputs = { target },
      rule = 'phony',
      inputs = inputs,
      implicit_inputs = implicit_inputs
   }
end

default_targets = { }

function ninja_escape (str, escape_dollar)
   local pattern = (escape_dollar and '[\n :$]') or '[\n :]'
   str = str:gsub('\r\n', '\n'):gsub(pattern, '$%0')
   return str
end
