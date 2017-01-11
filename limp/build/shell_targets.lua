local fs = require('be.fs')

local function set_srule (t, baserule)
   if t.super then
      t.rule = rule('super' .. baserule)
   else
      t.rule = rule(baserule)
   end
end

function make_ninja_target (target)
   if not target then error 'ninja target not specified!' end
   return function (t)
      if type(t.targets) == 'table' then
         t.targets = table.concat(t.targets, ' ')
      end
      set_srule(t, 'ninja')
      t.outputs = { target }
      t.vars = {
         { name = 'file', value = fs.ancestor_relative(file_path, root_dir) }
      }
      if t.targets then
         t.vars[#t.vars+1] = { name = 'targets', value = t.targets }
      end
      if t.extra then
         t.vars[#t.vars+1] = { name = 'extra', value = t.extra }
      end
      return make_target(t)
   end
end

function make_ninja_tool_target (target, tool)
   if not target then error 'ninjatool target not specified!' end
   if not tool then error 'ninjatool tool not specified!' end
   return function (t)
      set_srule(t, 'ninjatool')
      t.outputs = { target }
      t.vars = {
         { name = 'tool', value = tool },
         { name = 'file', value = fs.ancestor_relative(file_path, root_dir) }
      }
      if t.extra then
         t.vars[#t.vars+1] = { name = 'extra', value = t.extra }
      end
      return make_target(t)
   end
end

function make_run_target (target)
   if not target then error 'run target not specified!' end
   return function (t)
      set_srule(t, 'run')
      t.outputs = { target }
      t.vars = {
         { name = 'cmd', value = t.command },
         { name = 'extra', value = t.extra }
      }
      return make_target(t)
   end
end

function make_shell_target (target)
   if not target then error 'shell target not specified!' end
   return function (t)
      set_srule(t, 'shell')
      t.outputs = { target }
      t.vars = {
         { name = 'cmd', value = t.command },
         { name = 'extra', value = t.extra }
      }
      return make_target(t)
   end
end

function make_mkdir_target (dir)
   if not dir then error 'mkdir directory not specified!' end
   return function (t)
      t.rule = rule 'mkdir'
      t.outputs = { dir }
      return make_target(t)
   end
end

function make_touch_target (target)
   if not target then error 'touch target not specified!' end
   return function (t)
      t.outputs = { target }
      if not t.path or target == t.path then
         t.rule = rule 'touchself'
      else
         t.rule = rule 'touch'
         t.vars = { { name='path', value = t.path } }
      end
      return make_target(t)
   end
end

function make_putfile_target (dest_path, content)
   if not dest_path then error 'putfile destination path not specified!' end
   if putfile_escape then
      content = putfile_escape(content)
   end
   if not content then error 'putfile content not specified!' end
   return function (t)
      t.rule = rule 'putfile'
      t.outputs = { dest_path }
      t.vars = { { name = 'contents', value = content } }
      return make_target(t)
   end
end

function make_cp_target (dest_path, src_path)
   if not dest_path then error 'cp destination path not specified!' end
   if not src_path then error 'cp source path not specified!' end
   return function (t)
      t.rule = rule 'cp'
      t.outputs = { dest_path }
      t.inputs = { src_path }
      return make_target(t)
   end
end

function make_mv_target (dest_path, src_path)
   if not dest_path then error 'mv destination path not specified!' end
   if not src_path then error 'mv source path not specified!' end
   return function (t)
      t.rule = rule 'mv'
      t.outputs = { dest_path }
      t.inputs = { src_path }
      return make_target(t)
   end
end

function make_rmdir_target (target)
   if not target then error 'rmdir target not specified!' end
   return function (t)
      if not t.path then
         t.path = target
      end
      t.rule = rule 'rmdir'
      t.outputs = { target }
      t.vars = { { name = 'path', value = t.path } }
      return make_target(t)
   end
end

function make_rmfile_target (target)
   if not target then error 'rmfile target not specified!' end
   return function (t)
      if not t.path then
         t.path = target
      end
      t.rule = rule 'rmfile'
      t.outputs = { target }
      t.vars = { { name = 'path', value = t.path } }
      return make_target(t)
   end
end

function make_rmfiles_target (target, paths)
   if not target then error 'rmfiles target not specified!' end
   if not paths then error 'rmfiles paths not specified!' end
   if type(paths) == 'table' then
      paths = table.concat(paths, ' ')
   end
   return function (t)
      t.rule = rule 'rmfiles'
      t.outputs = { target }
      t.vars = { { name = 'paths', value = paths } }
      return make_target(t)
   end
end

function make_lndir_target (link_path, src_path)
   if not link_path then error 'lndir link path not specified!' end
   if not src_path then error 'lndir source path not specified!' end
   return function (t)
      t.rule = rule 'lndir'
      t.outputs = { link_path }
      t.inputs = { src_path }
      return make_target(t)
   end
end

function make_lnfile_target (link_path, src_path)
   if not link_path then error 'lnfile link path not specified!' end
   if not src_path then error 'lnfile source path not specified!' end
   return function (t)
      t.rule = rule 'lnfile'
      t.outputs = { link_path }
      t.inputs = { src_path }
      return make_target(t)
   end
end
