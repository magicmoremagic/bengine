
local rule_names = { phony = { enabled = false } }
local rules = { }

function make_rule (name)
   if not name then
      error 'Rule must have a name!'
   end

   return function (t)
      if rule_names[name] then
         error('A rule named "' .. name .. '" already exists!')
      end

      if not t.command then
         error 'Rule command is requred!'
      end

      local vars = { }

      for k, v in pairs(t) do
         vars[#vars + 1] = { name = k, value = v }
      end

      table.sort(vars, function (a, b) return a.name < b.name end)
      
      local r = { name = name, vars = vars }
      rules[#rules + 1] = r
      rule_names[name] = r
   end
end

function rule (name)
   local r = rule_names[name]
   if r then
      if r.enabled == nil then
         r.enabled = true
      end
   else
      error 'Undefined rule used!'
   end
   return name
end

function write_rules ()
   local enabled_rules = { }
   for i = 1, #rules do
      if rules[i].enabled then
         enabled_rules[#enabled_rules+1] = rules[i]
      end
   end
   write_template('rules', enabled_rules)
end
