if process_projects then
   process_projects()
end

write_template('globals', {
   { name = 'ninja_required_version', value = ninja_required_version },
   { name = 'builddir', value = ninja_dir }
})

write_template('globals', {
   { name = 'ninja_dir', value = ninja_dir },
   { name = 'build_dir', value = build_dir },
   { name = 'out_dir', value = out_dir },
   { name = 'include_dir', value = include_dir },
   { name = 'stage_dir', value = stage_dir },
   { name = 'bin_dir', value = bin_dir },
   { name = 'deps_dir', value = deps_dir },
   { name = 'ext_src_dir', value = ext_src_dir },
   { name = 'ext_include_dir', value = ext_include_dir },
   { name = 'ext_lib_dir', value = ext_lib_dir }
})

local sorted_global_groups = { }
for k in pairs(global_groups) do
   sorted_global_groups[#sorted_global_groups + 1] = k
end
table.sort(sorted_global_groups)
for i = 1, #sorted_global_groups do
   local group = global_groups[sorted_global_groups[i]]
   if #group > 0 then
      write_template('globals', group)
   end
end

writeln '#### Rules ####'
write_template('rules', rules)

writeln '#### Build Edges ####'
write_template('jobs', jobs)

write_template('default_targets', default_targets)
