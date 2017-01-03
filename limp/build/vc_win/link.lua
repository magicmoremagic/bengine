local table = table
local fs = be.fs

make_global('linkcmd', 'link', 0)
make_global('pdbcmd', 'mspdbcmf', 0)

make_global('link_base', table.concat({
   '/NOLOGO',
   '/MACHINE:X64',
   '/DYNAMICBASE',
   '/DEBUG:FASTLINK',
   '/NXCOMPAT',
   '/LIBPATH:"$ext_lib_dir"',
   '/MANIFEST:NO'
}, ' '), 9)

make_global('link_baselibs', table.concat({
   'kernel32.lib',
   'user32.lib',
   'gdi32.lib',
   'comdlg32.lib',
   'advapi32.lib',
   'shell32.lib',
   'ole32.lib'
}, ' '), 9)

local function get_linkflags (project, debug)
   local options = { }
   local function add_option (option)
      options[#options+1] = option
   end

   if not project.is_ext_lib then
      add_option '/LIBPATH:"$out_dir"'
      add_option '/WX'  -- warnings are errors
      add_option '/IGNORE:4221' -- No public symbols
   end

   if debug then
      add_option '/INCREMENTAL'
   else
      add_option '/LTCG'   -- Link-time codegen
      add_option '/OPT:REF,ICF'
   end

   if project.console then
      add_option '/SUBSYSTEM:CONSOLE'
   else
      add_option '/SUBSYSTEM:WINDOWS'
   end

   return table.concat(options, ' ')
end

local rule_name
local linkflags = { }
function get_linkflags_var (project, debug)
   local name = { 'linkflags' }
   local function add_name_suffix (suffix)
      name[#name+1] = '_'
      name[#name+1] = suffix
   end
   
   if project.console then add_name_suffix 'console' end
   if project.is_ext_lib then add_name_suffix 'extlib' end

   if debug then add_name_suffix 'debug'
   else add_name_suffix 'release'
   end

   name = table.concat(name)

   if linkflags[name] then
      return '$' .. name
   end

   if not rule_name then
      rule_name = 'link'
      make_rule(rule_name, '$linkcmd $link_base $flags $extra /PDB:"$pdb" /OUT:"$out" @${build_dir}\\${out_file}.in', 'link $out', {
         rspfile = '${build_dir}\\${out_file}.in',
         rspfile_content = '$link_baselibs $in_newline'
      })
   end

   local final = get_linkflags(project, debug)
   linkflags[name] = final
   make_global(name, final, 9)

   return '$' .. name
end

local pdb_rule_name
local pdb_jobs = { }
function make_pdb_job (target, pdb_path, implicit_inputs)
   if not pdb_rule_name then
      pdb_rule_name = 'pdb'
      make_rule(pdb_rule_name, '$pdbcmd $in', 'pdb $in')
   end

   pdb_jobs[#pdb_jobs+1] = target

   return job {
      rule = pdb_rule_name,
      inputs = { pdb_path },
      implicit_inputs = implicit_inputs,
      outputs = { target }
   }
end

function make_meta_pdb_job (target)
   return make_phony_job(target, pdb_jobs)
end

function make_link_job (out_path, pdb_path, input_paths, debug, flags, extra, implicit_inputs, implicit_outputs)
   local imp_outputs = { pdb_path }
   if implicit_outputs then
      for i = 1, #implicit_outputs do
         imp_outputs[#imp_outputs] = implicit_outputs[i]
      end
   end

   job {
      rule = rule_name,
      inputs = input_paths,
      implicit_inputs = implicit_inputs,
      order_only_inputs = { 'init!' },
      outputs = { out_path },
      implicit_outputs = imp_outputs,
      vars = {
         { name = 'out_file', value = fs.path_filename(out_path) },
         { name = 'pdb', value = pdb_path },
         { name = 'flags', value = flags },
         { name = 'extra', value = extra }
      }
   }
   make_pdb_job(pdb_path .. '!', pdb_path)
end
