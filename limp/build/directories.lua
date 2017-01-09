
local global_group = 0

function set_directory (name, path)
   local global = name .. '_dir'
   set_global(global, path, global_group)
   if name == 'ninja' then
      set_global('builddir', path, global_group)
   end
end

function get_directory (name, default_path)
   local global = name .. '_dir'
   local current = get_global(global)

   if current == nil then
      default_path = default_path or name
      set_directory(name, default_path)
      current = default_path
   end

   return '$' .. global, current
end

function ninja_dir () return get_directory('ninja') end
function build_dir () return get_directory('build') end
function out_dir () return get_directory('out') end
function include_dir () return get_directory('include') end
function stage_dir () return get_directory('stage') end
function bin_dir () return get_directory('bin') end
function deps_dir () return get_directory('deps') end
function ext_include_dir () return get_directory('ext_include') end
function ext_lib_dir () return get_directory('ext_lib') end

ninja_dir()
build_dir()
