local fs = require('be.fs')

local limp_files = { }
local limp_targets = { }

local function limp_target (limp_file, force, input_paths)
   if limp_files[limp_file] then
      return
   end
   limp_files[limp_file] = true

   local t = {
      outputs = { limp_file .. '!' },
      implicit_inputs = input_paths,
      vars = {{ name = 'path', value = limp_file }}
   }

   if force then
      t.vars[#t.vars+1] = { name = 'extra', value = '-f' }
   end

   return t
end

local function configure_limp_target (t, configured, search_paths)
   if type(t) == 'table' then
      if not t.file then
         error 'LIMP file not specified!'
      end
      
      local path = expand_path(t.file, search_paths)
      local inputs = expand_pathspec(t.inputs or { }, search_paths, configured)
      local force = t.force or inputs ~= nil

      return limp_target(path, force, inputs)
   else
      local path = expand_path(t, search_paths)
      return limp_target(path)
   end
end

function build_scripts.env.limp (t)
   return function (configured)
      configured.limp = append_sequence({ t }, configured.limp)
   end
end

function make_limp_targets (configured)
   if configured.limp then
      for i = 1, #configured.limp do
         local t = configure_limp_target(configured.limp[i], configured, { configured.path, root_dir })
         if t then
            t.rule = rule 'limp'
            make_target(t)
            append_sequence(t.outputs, limp_targets)
         end
      end
   end
end

function make_meta_limp_target (t)
   t = t or {}
   t.inputs = limp_targets
   make_phony_target('limp!')(t)
end
