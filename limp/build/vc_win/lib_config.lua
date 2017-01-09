local fs = require('be.fs')

lib_flags_global_group = 3

set_global('lib_base_flags', table.concat({
   '/NOLOGO',
   '/MACHINE:X64'
}, ' '), lib_flags_global_group)

local rspfile_path = fs.compose_path(build_dir(), '${out_file}.in')

make_rule 'lib' {
   command = table.concat({
      'lib',
      '$lib_base_flags',
      '$flags',
      '$extra',
      '/OUT:"$out"',
      '@' .. rspfile_path
   }, ' '),
   description = 'lib $out',
   rspfile = rspfile_path,
   rspfile_content = '$in_newline'
}

function configure_lib_flags (configured, disable_warning, option, name_suffix)
   if configured.is_ext_lib then
      name_suffix 'extlib'
   else
      option '/WX'  -- warnings are errors
      disable_warning(4221) -- No public symbols
   end

   if configured.configuration == 'debug' then
      name_suffix 'debug'
   else
      name_suffix 'release'
      option '/LTCG'   -- Link-time codegen
   end
end
