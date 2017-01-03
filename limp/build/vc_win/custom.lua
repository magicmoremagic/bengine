local table = table
local fs = be.fs

local rules = { }
local custom_outputs = { }
local special_props = {
   name = true,
   command = true,
   generator = true,
   restat = true,
   outputs = true,
   implicit_outputs = true,
   inputs = true,
   implicit_inputs = true,
   order_only_inputs = true
}
function make_custom_job (spec, base_path)
   local outputs = expand_pathspec(spec.outputs, base_path)
   local found, not_found
   for i = 1, #outputs do
      local o = outputs[i]
      if custom_outputs[o] then found = true else not_fount = true end
      custom_outputs[o] = true
   end

   if found and not_found then error 'Some custom build edges have already been defined!' end
   if found then return end

   local rule_name = spec.name
   if not rules[rule_name] then
      rules[rule_name] = spec.command
      local extra
      if spec.generator then
         if not extra then extra = { } end
         extra.generator = 'true'
      end
      if spec.restat then
         if not extra then extra = { } end
         extra.restat = 'true'
      end
      make_rule(rule_name, spec.command, rule_name .. ' $out', extra)
   elseif rules[rule_name] ~= spec.command then
      error('a custom build rule named ' .. rule_name .. 'already exists with a different definition!')
   end

   local implicit_outputs = spec.implicit_outputs and expand_pathspec(spec.implicit_outputs, base_path)

   local inputs = spec.inputs and expand_pathspec(spec.inputs, base_path)
   local implicit_inputs = spec.implicit_inputs and expand_pathspec(spec.implicit_inputs, base_path)
   local order_only_inputs = spec.order_only_inputs and expand_pathspec(spec.order_only_inputs, base_path)

   local vars = { }
   for k, v in pairs(spec) do
      if not special_props[k] then
         vars[#vars+1] = { name = k, value = v }
      end
   end
   if #vars == 0 then
      vars = nil
   end

   table.sort(vars, function (a, b) return a.name < b.name end)

   return job {
      outputs = outputs,
      implicit_outputs = implicit_outputs,
      rule = rule_name,
      inputs = inputs,
      implicit_inputs = implicit_inputs,
      order_only_inputs = order_only_inputs,
      vars = vars
   }
end

function process_custom_spec (spec, base_path)
   if not type(spec) == 'table' then
      error 'custom build edges must specify at least one output, a rule name, and a command!'
   end
   
   if spec.name then
      make_custom_job(spec, base_path)
   else
      for i = 1, #spec do
         process_custom_spec(spec[i], base_path)
      end
   end
   
end
