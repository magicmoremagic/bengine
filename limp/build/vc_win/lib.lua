local table = table
local fs = be.fs

make_global('libcmd', 'lib', 0)

make_global('lib_base', table.concat({
   '/NOLOGO',
   '/MACHINE:X64'
}, ' '), 3)

local function get_libflags (project, debug)
   local options = { }
   local function add_option (option)
      options[#options+1] = option
   end

   if not project.is_ext_lib then
      add_option '/WX'  -- warnings are errors
      add_option '/IGNORE:4221' -- No public symbols
   end

   if not debug then
      add_option '/LTCG'   -- Link-time codegen
   end

   return table.concat(options, ' ')
end
 
local rule_name
local libflags = { }
function get_libflags_var (project, debug)
   local name = { 'libflags' }
   local function add_name_suffix (suffix)
      name[#name+1] = '_'
      name[#name+1] = suffix
   end

   if project.is_ext_lib then add_name_suffix 'extlib' end

   if debug then add_name_suffix 'debug'
   else add_name_suffix 'release'
   end

   name = table.concat(name)

   if libflags[name] then
      return '$' .. name
   end

   if not rule_name then
      rule_name = 'lib'
      make_rule(rule_name, '$libcmd $lib_base $flags $extra /OUT:"$out" @${build_dir}\\${out_file}.in', 'lib $out', {
         rspfile = '${build_dir}\\${out_file}.in',
         rspfile_content = '$in_newline'
      })
   end

   local final = get_libflags(project, debug)
   libflags[name] = final
   make_global(name, final, 3)

   return '$' .. name
end

function make_lib_job (lib_path, input_paths, flags, extra)
   job {
      rule = rule_name,
      inputs = input_paths,
      order_only_inputs = { 'init!' },
      outputs = { lib_path },
      vars = {
         { name = 'out_file', value = fs.path_filename(lib_path) },
         { name = 'flags', value = flags },
         { name = 'extra', value = extra }
      }
   }
end
