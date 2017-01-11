local fs = require('be.fs')

link_flags_global_group = 9

set_global('link_base_flags', table.concat({
   '/NOLOGO',
   '/MACHINE:X64',
   '/DYNAMICBASE',
   '/NXCOMPAT',
   '/LIBPATH:"' .. ext_lib_dir() .. '"',
   '/MANIFEST:NO'
}, ' '), link_flags_global_group)

set_global('link_base_libs', table.concat({
   'kernel32.lib',
   'user32.lib',
   'gdi32.lib',
   'comdlg32.lib',
   'advapi32.lib',
   'shell32.lib',
   'ole32.lib'
}, ' '), link_flags_global_group)

local rspfile_path = fs.compose_path(build_dir(), '${out_file}.in')

make_rule 'link' {
   command = table.concat({
      'link',
      '$link_base_flags',
      '$flags',
      '$extra',
      '/PDB:"$pdb"',
      '/OUT:"$out"',
      '@' .. rspfile_path
   }, ' '),
   description = 'link $out',
   rspfile = rspfile_path,
   rspfile_content = '$link_base_libs $in_newline'
}

make_rule 'pdb' {
   command = 'mspdbcmf /nologo $in',
   description = 'pdb $in'
}

function configure_link_flags (configured, ignore_warning, option, name_suffix)
   if configured.console then
      name_suffix 'console'
      option '/SUBSYSTEM:CONSOLE'
   else
      option '/SUBSYSTEM:WINDOWS'
   end

   if configured.is_ext_lib then
      name_suffix 'extlib'
   else
      option('/LIBPATH:"' .. out_dir() .. '"')
      option '/WX'  -- warnings are errors
      ignore_warning(4221) -- No public symbols
   end

   if configured.configuration == 'debug' then
      name_suffix 'debug'
      option '/DEBUG:FASTLINK'
      option '/INCREMENTAL'
   else
      name_suffix 'release'
      option '/DEBUG'
      option '/LTCG'   -- Link-time codegen
      option '/OPT:REF,ICF'
   end
end
