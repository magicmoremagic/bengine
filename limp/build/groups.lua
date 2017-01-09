local fs = require('be.fs')

local groups = {
   all = { }
}

local default_directories = {
   module = 'modules',
   tool = 'tools',
   demo = 'demos',
   deps = 'dep_modules'
}

protected_config_properties = {
   name = true,
   suffix = true,
   type = true,
   projects = true,
   fns = true,
   group = true,
   project = true,
   toolchain = true,
   configuration = true,
   configurations = true,
   configured_group = true,
   src = true,
   src_no_pch = true,
   include = true,
   link = true,
   link_internal = true,
   link_project = true,
   define = true,
   export_define = true
}

local function group (group_type, name)
   if not name then
      error 'Group name not specified!'
   end

   local group = groups.all[name]
   if not group then
      group = {
         name = name,
         type = group_type,
         configurations = { },
         projects = { },
         fns = { },
         define = { },
         export_define = { }
      }
      groups.all[name] = group
      groups[#groups + 1] = group
   end

   if group.type ~= group_type then
      error('"' .. name .. '" is a ' .. group.type .. ', not a ' .. group_type .. '!')
   end

   return function (t)
      if type(t) ~= 'table' then
         error 'Expected table!'
      end

      for k, v in pairs(t) do
         if type(k) == 'number' then
            group.fns[#group.fns + 1] = v
         elseif type(k) == 'string' and not protected_config_properties[k] then
            group[k] = v
         else
            error('The ' .. k .. ' property cannot be set directly!')
         end
      end
   end
end

function build_scripts.env.module (name)
   return group('module', name)
end

function build_scripts.env.tool (name)
   return group('tool', name)
end

function build_scripts.env.demo (name)
   return group('demo', name)
end

function build_scripts.env.deps (t)
   return group('deps', 'deps')(t)
end

function build_scripts.env.ext_include_dir (name)
   return function (t)
      for i = 1, #t do
         t[i](t)
      end
      t.name = name
      if not t.path then
         t.path = t.name
      end
      return function (configured_group)
         if t then
            configured_group.ext_include_dirs = append_sequence({ t }, configured_group.ext_include_dirs)
            t = nil
         end
      end
   end
end

function configure_group (group, toolchain, configuration)
   local configured = deep_copy(group)
   group.configurations[configuration] = configured
   configured.group = group
   configured.toolchain = toolchain
   configured.configuration = configuration
   configured.configurations = group.configurations
   configured.configuration_suffix = default_configuration_suffix(configuration)

   for f = 1, #group.fns do
      group.fns[f](configured)
   end

   if not configured.path then
      if configured.type == 'deps' then
         configured.path = fs.compose_path(root_dir, default_directories.deps)
      else
         configured.path = fs.compose_path(root_dir, default_directories[configured.type], configured.name)
      end
   end
   configured.path = fs.canonical(configured.path)
   local search_paths = { configured.path, root_dir }

   if not configured.namespace_path then
      configured.namespace_path = 'be'
   end

   if configured.ext_include_dirs then
      for i = 1, #configured.ext_include_dirs do
         local t = configured.ext_include_dirs[i]
         local dest_path = fs.compose_path(ext_include_dir(), t.name)
         local source_path = expand_path(t.path, search_paths)
         configured.ext_include_dirs[i] = make_lndir_target(dest_path, source_path)
      end
   end

   for k, v in pairs(configured) do
      if not protected_config_properties[k] and type(v) == 'string' then
         configured[k] = interpolate_string(v, configured)
      end
   end

   return configured
end

return groups
