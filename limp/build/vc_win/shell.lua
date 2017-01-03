make_global('ninjacmd', 'ninja', 0)

local rules = { }

function make_ninja_job (target, targets_to_build, super, extra, implicit_inputs, implicit_outputs)
   local rule
   if super then
      rule = 'superninja'
      if not rules[rule] then
         rules[rule] = make_rule(rule, '"$bin_dir\\wedo.exe" $ninjacmd $targets $extra', 'sudo ninja $targets', { generator = 'true' })
      end
   else
      rule = 'ninja'
      if not rules[rule] then
         rules[rule] = make_rule(rule, '$ninjacmd $targets $extra', 'ninja $targets', { generator = 'true' })
      end
   end
   if type(targets_to_build) == 'table' then
      targets_to_build = table.concat(targets_to_build, ' ')
   end
   return job {
      outputs = { target },
      rule = rule,
      implicit_inputs = implicit_inputs,
      implicit_outputs = implicit_outputs,
      vars = {
         { name = 'targets', value = targets_to_build },
         { name = 'extra', value = extra },
         
      }
   }
end

function make_ninjatool_job (target, tool, super, extra, implicit_inputs, implicit_outputs)
   local rule
   if super then
      rule = 'superninjatool'
      if not rules[rule] then
         rules[rule] = make_rule(rule, '"$bin_dir\\wedo.exe" $ninjacmd -t $tool $extra', 'sudo ninja -t $tool')
      end
   else
      rule = 'ninjatool'
      if not rules[rule] then
         rules[rule] = make_rule(rule, '$ninjacmd -t $tool $extra', 'ninja -t $tool')
      end
   end
   return job {
      outputs = { target },
      rule = rule,
      implicit_inputs = implicit_inputs,
      implicit_outputs = implicit_outputs,
      vars = {
         { name = 'tool', value = tool },
         { name = 'extra', value = extra }
      }
   }
end

function make_run_job (target, command, super, extra, implicit_inputs, implicit_outputs)
   local rule
   if super then
      rule = 'superrun'
      if not rules[rule] then
         rules[rule] = make_rule(rule, '"$bin_dir\\wedo.exe" $cmd $extra', 'sudo $cmd')
      end
   else
      rule = 'run'
      if not rules[rule] then
         rules[rule] = make_rule(rule, '$cmd $extra', '$cmd')
      end
   end
   return job {
      outputs = { target },
      rule = rule,
      implicit_inputs = implicit_inputs,
      implicit_outputs = implicit_outputs,
      vars = {
         { name = 'cmd', value = command },
         { name = 'extra', value = extra }
      }
   }
end

function make_shell_job (target, command, super, extra, implicit_inputs, implicit_outputs)
   local rule
   if super then
      rule = 'supershell'
      if not rules[rule] then
         rules[rule] = make_rule(rule, '"$bin_dir\\wedo.exe" cmd /s /c "$cmd $extra"', 'sudo $cmd')
      end
   else
      rule = 'shell'
      if not rules[rule] then
         rules[rule] = make_rule(rule, 'cmd /s /c "$cmd $extra"', '$cmd')
      end
   end
   return job {
      outputs = { target },
      rule = rule,
      implicit_inputs = implicit_inputs,
      implicit_outputs = implicit_outputs,
      vars = {
         { name = 'cmd', value = command },
         { name = 'extra', value = extra }
      }
   }
end

function make_mkdir_job (dir, implicit_inputs)
   local rule = 'mkdir'
   if not rules[rule] then
      rules[rule] = make_rule(rule, 'cmd /s /c "if not exist "$out" md "$out""', 'mkdir $out', { generator = 'true' })
   end
   return job {
      outputs = { dir },
      rule = rule,
      implicit_inputs = implicit_inputs
   }
end

function make_touch_job (target, dest_path, implicit_inputs)
   if not target then
      target = dest_path
   elseif not dest_path then
      dest_path = target
   end
   local rule, vars
   if target == dest_path then
      rule = 'touch_self'
      if not rules[rule] then
         rules[rule] = make_rule(rule, 'cmd /s /c "echo:>nul 2>>"$out""', 'touch $out')
      end
   else
      rule = 'touch'
      if not rules[rule] then
         rules[rule] = make_rule(rule, 'cmd /s /c "echo:>nul 2>>"$path""', 'touch $path')
      end
      vars = {{ name='path', value = dest_path }}
   end
   return job {
      outputs = { target },
      rule = rule,
      implicit_inputs = implicit_inputs,
      vars = vars
   }
end

function make_putfile_job (dest_path, contents, implicit_inputs, order_only_inputs)
   local rule = 'putfile'
   if not rules[rule] then
      rules[rule] = make_rule(rule, 'cmd /s /c "(echo:$contents)>"$out""', 'putfile $out')
   end

   local escaped = contents:gsub('[%%&\\<>^|"]', '^%0')
   escaped = escaped:gsub('\r?\n', '&echo:$%0')

   return job {
      outputs = { dest_path },
      rule = rule,
      implicit_inputs = implicit_inputs,
      order_only_inputs = order_only_inputs,
      vars = {{ name = 'contents', value = escaped }}
   }
end

function make_cp_job (dest_path, source_path, implicit_inputs)
   local rule = 'cp'
   if not rules[rule] then
      rules[rule] = make_rule(rule, 'cmd /s /c "copy /Y /B "$in" "$out" /B >nul"', 'cp $out')
   end
   return job {
      outputs = { dest_path },
      rule = rule,
      inputs = { source_path },
      implicit_inputs = implicit_inputs
   }
end

function make_deploy_job (dest_path, source_path, implicit_inputs)
   local rule = 'deploy'
   if not rules[rule] then
      rules[rule] = make_rule(rule, 'cmd /s /c "copy /Y /B "$in" "$out" /B >nul"', 'deploy $out', { generator = 'true' })
   end
   return job {
      outputs = { dest_path },
      rule = rule,
      inputs = { source_path },
      implicit_inputs = implicit_inputs
   }
end

function make_mv_job (dest_path, source_path, implicit_inputs)
   local rule = 'mv'
   if not rules[rule] then
      rules[rule] = make_rule(rule, 'cmd /s /c "move /Y "$in" "$out" >nul"', 'mv $out')
   end
   return job {
      outputs = { dest_path },
      rule = rule,
      inputs = { source_path },
      implicit_inputs = implicit_inputs
   }
end

function make_rm_dir_job (target, path, implicit_inputs)
   local rule = 'rm_dir'
   if not rules[rule] then
      rules[rule] = make_rule(rule, 'cmd /s /c "if exist "$path" rd /Q /S "$path""', 'rm $path')
   end
   return job {
      outputs = { target },
      rule = rule,
      implicit_inputs = implicit_inputs,
      vars = {
         { name = 'path', value = path }
      }
   }
end

function make_rm_file_job (target, path, implicit_inputs)
   local rule = 'rm_file'
   if not rules[rule] then
      rules[rule] = make_rule(rule, 'cmd /s /c "if exist "$path" del /F /Q "$path""', 'rm $path')
   end
   return job {
      outputs = { target },
      rule = rule,
      implicit_inputs = implicit_inputs,
      vars = {
         { name = 'path', value = path }
      }
   }
end

function make_rm_files_job (target, paths, implicit_inputs)
   local rule = 'rm_files'
   if not rules[rule] then
      rules[rule] = make_rule(rule, 'cmd /s /c "del /F /Q $paths >nul 2>&1 || echo. >nul"', 'rm $paths')
   end
   return job {
      outputs = { target },
      rule = rule,
      implicit_inputs = implicit_inputs,
      vars = {
         { name = 'paths', value = paths }
      }
   }
end

function make_dir_link_job (link_path, source_path, implicit_inputs)
   local rule = 'ln_dir'
   if not rules[rule] then
      rules[rule] = make_rule(rule, 'cmd /s /c "if not exist "$out" mklink /J "$out" "$in" >nul"', 'ln $out', { generator = 'true', restat = 'true' })
   end
   return job {
      outputs = { link_path },
      rule = rule,
      inputs = { source_path },
      implicit_inputs = implicit_inputs
   }
end

function make_file_link_job (link_path, source_path, implicit_inputs)
   local rule = 'ln_file'
   if not rules[rule] then
      rules[rule] = make_rule(rule, 'cmd /s /c "if not exist "$out" mklink /H "$out" "$in" >nul"', 'ln $out', { generator = 'true', restat = 'true' })
   end
   return job {
      outputs = { link_path },
      rule = rule,
      inputs = { source_path },
      implicit_inputs = implicit_inputs
   }
end
