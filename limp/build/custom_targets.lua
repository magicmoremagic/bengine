
local custom_rules = { }
local custom_targets = { }
local protected_properties = {
   rule = true,
   command = true,
   generator = true,
   restat = true,
   outputs = true,
   implicit_outputs = true,
   inputs = true,
   implicit_inputs = true,
   order_only_inputs = true,
   vars = true
}

local function configure_custom_target (t, configured, search_paths)
   t.outputs = expand_pathspec(t.outputs, search_paths, configured)
   local found, not_found
   for i = 1, #t.outputs do
      local o = t.outputs[i]
      if custom_targets[o] then found = true else not_found = true end
      custom_targets[o] = true
   end

   if found and not_found then error 'Some custom targets have already been defined!' end
   if found then return end

   if not custom_rules[t.rule] then
      custom_rules[t.rule] = t.command

      local extra = {
         command = t.command,
         description = t.rule .. ' $out'
      }

      if t.generator then
         extra.generator = 'true'
      end

      if t.restat then
         extra.restat = 'true'
      end

      make_rule(t.rule)(extra)
         
   elseif custom_rules[t.rule] ~= t.command then
      error('a custom build rule named ' .. t.rule .. 'already exists with a different definition!')
   end

   t.implicit_outputs = t.implicit_outputs and expand_pathspec(t.implicit_outputs, search_paths, configured)

   t.inputs = t.inputs and expand_pathspec(t.inputs, search_paths, configured)
   t.implicit_inputs = t.implicit_inputs and expand_pathspec(t.implicit_inputs, search_paths, configured)
   t.order_only_inputs = t.order_only_inputs and expand_pathspec(t.order_only_inputs, search_paths, configured)

   t.vars = t.vars or { }
   for k, v in pairs(t) do
      if not protected_properties[k] then
         t.vars[#t.vars+1] = { name = k, value = v }
      end
   end
   if #t.vars == 0 then
      t.vars = nil
   end

   table.sort(t.vars, function (a, b) return a.name < b.name end)

   return t
end

function build_scripts.env.custom (t)
   if type(t) ~= 'table' or not t.outputs or not t.rule or not t.command then
      error 'custom build step must specify at least one output, a rule name, and a command!'
   end
   return function (configured)
      configured.custom = append_sequence({ t }, configured.custom)
   end
end

function make_custom_targets (configured)
   if configured.custom then
      for i = 1, #configured.custom do
         local t = configure_custom_target(configured.custom[i], configured, { configured.path, root_dir })
         if t then
            t.rule = rule(t.rule)
            make_target(t)
         end
      end
   end
end
