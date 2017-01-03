local table = table
local fs = be.fs

local rule_name
local limp_files = { }
local limp_jobs = { }
function make_limp_job (limp_file, force, input_paths)
   if limp_files[limp_file] then
      return
   end

   limp_files[limp_file] = true

   if not rule_name then
      rule_name = 'limp'
      make_rule(rule_name, '"$bin_dir\\limp.exe" $extra $path', 'limp $path', {
         generator = 'true',
         restat = 'true'
      })
   end

   local vars = {{ name = 'path', value = limp_file }}
   if force then
      vars[#vars+1] = { name = 'extra', value = '-f' }
   end

   local hash_file = limp_file .. '.limphash'
   local limp_target = limp_file .. '!'

   limp_jobs[#limp_jobs+1] = limp_target
   
   job {
      outputs = { limp_target },
      rule = rule_name,
      implicit_inputs = input_paths,
      order_only_inputs = { 'init!' },
      vars = vars
   }

   if input_paths then
      job {
         outputs = { limp_file },
         rule = rule_name,
         implicit_inputs = input_paths,
         order_only_inputs = { 'init!' },
         vars = vars
      }
   end
end

function make_meta_limp_job(target)
   return make_phony_job(target, limp_jobs)
end

function process_limp_spec (spec, base_path)
   if type(spec) == 'table' then
      if spec.file then
         local path = fs.ancestor_relative(fs.glob(tostring(spec.file), base_path, 'f?'), root_dir)

         local inputs = spec.inputs
         if inputs then
            inputs = expand_pathspec(inputs, base_path)
         end

         local force = spec.force or inputs

         make_limp_job(path, force, inputs)
      else
         for i = 1, #spec do
            process_limp_spec(spec[i], base_path)
         end
      end
   else
      local path = fs.ancestor_relative(fs.glob(tostring(spec), base_path, 'f?'), root_dir)
      make_limp_job(path)
   end
end
