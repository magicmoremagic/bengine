local fs = require('be.fs')
interpolate_string = require('be.interpolate_string')

function interpolate_sequence (seq, map, out)
   out = out or seq
   for i = 1, #seq do
      out[i] = interpolate_string(seq[i], map)
   end
   return out
end

function shallow_copy (t, out)
   if type(t) ~= 'table' then
      return t
   end

   local target = setmetatable(out or { }, getmetatable(t))
   for k, v in pairs(t) do
      target[k] = v
   end

   return target
end

function deep_copy(t, out, visited)
   if type(t) ~= 'table' then
      return t
   end

   if visited and visited[t] then
      return visited[t]
   end

   visited = visited or { }
   local target = setmetatable(out or { }, getmetatable(t))
   visited[t] = target
   for k, v in pairs(t) do
      target[deep_copy(k, nil, visited)] = deep_copy(v, nil, visited)
   end

   return target
end

function make_append_fn(prefix, suffix, sequence, externally_mutable)
   if type(prefix) == 'function' then
      -- shift other parameters over 1
      externally_mutable = sequence
      sequence = suffix
   end

   sequence = sequence or { }
   local append_one
   if not externally_mutable then -- we can cache the next index
      local n = #sequence
      append_one = function (arg)
         n = n + 1
         sequence[n] = arg
      end
   else
      append_one = function (arg)
         sequence[#sequence + 1] = arg
      end
   end

   if type(prefix) == 'function' then
      local function append (arg, ...)
         if arg ~= nil then
            append_one(prefix(arg))
            append(...)
         end
      end
      return append, sequence
   elseif prefix ~= nil and suffix ~= nil then
      local function append (arg, ...)
         if arg ~= nil then
            append_one(prefix)
            append_one(arg)
            append_one(suffix)
            append(...)
         end
      end
      return append, sequence
   elseif prefix ~= nil then
      local function append (arg, ...)
         if arg ~= nil then
            append_one(prefix)
            append_one(arg)
            append(...)
         end
      end
      return append, sequence
   elseif suffix ~= nil then
      local function append (arg, ...)
         if arg ~= nil then
            append_one(arg)
            append_one(suffix)
            append(...)
         end
      end
      return append, sequence
   else
      local function append (arg, ...)
         if arg ~= nil then
            append_one(arg)
            append(...)
         end
      end
      return append, sequence
   end
end

function append_sequence(input, output, unique)
   if not output then
      output = { }
   end

   local n = #output

   if unique then
      if type(input) ~= 'table' then
         for j = 1, n do
            if output[j] == input then
               return
            end
         end
         n = n + 1
         output[n] = input
      else
         for i = 1, #input do
            local value = input[i]
            local append = true
            for j = 1, n do
               if output[j] == value then
                  append = false
                  break
               end
            end
            if append then
               n = n + 1
               output[n] = input[i]
            end
         end
      end
   else
      if type(input) ~= 'table' then
         n = n + 1
         output[n] = input
      else
         for i = 1, #input do
            n = n + 1
            output[n] = input[i]
         end
      end
   end

   return output
end

function ninja_escape (str, escape_dollar)
   local pattern = (escape_dollar and '[\n :$]') or '[\n :]'
   str = str:gsub('\r\n', '\n'):gsub(pattern, '$%0')
   return str
end

function expand_path (path, search_path)
   if not path then
      return
   end
   if type (search_path) == 'table' then
      for i = 1, #search_path do
         local expanded = expand_path(path, search_path[i])
         if expanded then
            return expanded
         end
      end
   else
      path = fs.compose_path(search_path, path)
      if fs.exists(path) then
         return fs.ancestor_relative(fs.canonical(path), root_dir)
      end
   end
end

function expand_pathspec (pathspec, search_path, configured_project, globtype)
   if type(pathspec) == 'table' then
      local paths = { }

      if pathspec.exclude then
         pathspec[#pathspec + 1] = exclude(pathspec.exclude)
      end

      for i = 1, #pathspec do
         local entry = pathspec[i]
         if type(entry) == 'function' then
            paths = entry(paths, search_path, configured_project, globtype)
         else
            local subpaths = expand_pathspec(entry, search_path, configured_project, globtype)
            for i = 1, #subpaths do
               local subpath = subpaths[i]
               local good = true;
               for i = 1, #paths do
                  local path = paths[i]
                  if fs.equivalent(path, subpath) then
                     good = false
                     break;
                  end
               end
               if good then
                  paths[#paths + 1] = subpath
               end
            end
         end
      end
      table.sort(paths)
      return paths
   else
      local globstring = interpolate_string(tostring(pathspec), configured_project)
      local paths = table.pack(fs.glob(globstring, search_path, globtype or 'f?'))
      for i = 1, #paths do
         paths[i] = fs.ancestor_relative(paths[i], root_dir)
      end
      table.sort(paths)
      return paths
   end
end

function build_scripts.env.exclude (pathspec)
   return function (paths, search_path, configured_project, globtype)
      local excluded_paths = expand_pathspec(pathspec, search_path, configured_project, globtype)
      local new_paths = { }
      local n = 0
      for i = 1, #paths do
         local path = paths[i]
         local good = true
         for i = 1, #excluded_paths do
            local excluded_path = excluded_paths[i]
            if fs.equivalent(path, excluded_path) then
               good = false
               break
            end
         end
         if good then
            n = n + 1
            new_paths[n] = path
         end
      end
      return new_paths
   end
end

function default_configuration_suffix (configuration)
   if configuration == 'release' then
      return ''
   else
      return '-' .. configuration
   end
end

function default_include_paths (configured_project)
   if configured_project.is_ext then
      return { }
   else
      return 'include'
   end
end

function default_source_patterns (configured_project)
   if configured_project.is_ext or (configured_project.src_no_pch and #configured_project.src_no_pch > 0) then
      return { }
   end
   
   if configured_project.test_type then
      return configured_project.test_type .. '/*.cpp'
   else
      return 'src/*.cpp'
   end
end
