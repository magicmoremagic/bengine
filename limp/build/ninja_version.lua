
local default_version = 1.5
local global = 'ninja_required_version'
local global_group = -1

set_global(global, default_version, global_group)

function get_required_ninja_version ()
   return get_global(global) or default_version
end

function set_required_ninja_version (version)
   local current_version = get_required_ninja_version()
   version = version or default_version

   if version ~= current_version then
      set_global(global, version, global_group)
   end
end

function require_ninja_version (version)
   set_required_ninja_version(math.max(get_required_ninja_version(), version))
end
