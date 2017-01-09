
local globals = { }

function set_global (name, value, group)
   if not name then
      error 'Global name not specified!'
   end

   if not group then
      group = 0
   end

   if value == nil then
      globals[name] = nil
   else
      globals[name] = { group, value }
   end
end

function get_global (name)
   local data = globals[name]
   if data then
      return data[2]
   end
end

function write_globals ()
   local tdata = { }
   for name, data in pairs(globals) do
      local group = data[1]
      local value = data[2]

      local group_tdata = tdata[group]
      if not group_tdata then
         group_tdata = { }
         tdata[group] = group_tdata
      end

      group_tdata[#group_tdata+1] = { name = name, value = value }
   end

   local sorted_groups = { }
   for group in pairs(tdata) do
      sorted_groups[#sorted_groups + 1] = group
   end
   table.sort(sorted_groups)
   for i = 1, #sorted_groups do
      local group = sorted_groups[i]
      local group_tdata = tdata[group]
      if #group_tdata > 0 then
         table.sort(group_tdata, function (a, b) return a.name < b.name end)
         write_template('globals', group_tdata)
      end
   end
end
