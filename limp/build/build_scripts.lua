
local fs = require('be.fs')

build_scripts = {
   env = { }
}

register_template_dir(fs.compose_path(limp_dir, 'build', 'templates'))

local n = 0
local function search_relative (path, parent_path)
   local build_script = fs.compose_path(parent_path, path, 'build.lua')
   if fs.exists(build_script) then
      local contents = fs.get_file_contents(build_script)
      local fn = load(contents, '@' .. build_script .. '.lua', 'bt', build_scripts.env)
      n = n + 1
      build_scripts[n] = fn
   end
end

function build_scripts.try (path)
   search_relative(path, root_dir)
end

function build_scripts.search (path)
   local abs_path = fs.compose_path(root_dir, path)
   local dirs = table.pack(fs.get_dirs(abs_path))
   for i = 1, #dirs do
      search_relative(dirs[i], abs_path)
   end
end

function build_scripts.execute ()
   for i = 1, n do
      build_scripts[i]()
   end
end
