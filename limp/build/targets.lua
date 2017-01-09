
local targets = { }
local default_targets = { }

function make_target (t)
   if type(t) ~= 'table' then
      error 'Expected table!'
   end

   if type(t.outputs) ~= 'table' then
      error 'At least one output or target name is required!'
   end

   if t.rule == nil then
      error 'No rule specified for target!'
   end

   if t.implicit_outputs then
      require_ninja_version(1.7)
   end

   targets[#targets + 1] = t

   if t.default then
      append_sequence(t.outputs, default_targets)
   end

   return t
end

function write_targets ()
   write_template('targets', targets)
   write_template('default_targets', default_targets)
end
