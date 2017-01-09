
function build_scripts.env.when (fn)
   return function (t)
      if type(t) ~= 'table' then
         error 'Expected table!'
      end
      return function (configured)
         if type(fn) ~= 'function' then
            local newfn = load('return ' .. tostring(fn), 'when()', 't', configured)
            if not newfn then
               error('Invalid when expression: ' .. fn)
            end
            fn = newfn
         end

         if fn(configured) then
            for i = 1, #t do
               t[i](configured)
            end
         end
      end
   end
end

function build_scripts.env.toolchain (spec)
   if type(spec) ~= 'table' then
      spec = { spec }
   end

   return build_scripts.env.when(function (configured)
      for i = 1, #spec do
         local tc = interpolate_string(tostring(spec[i]), configured)
         if tc == configured.toolchain then
            return true
         end
      end
      return false -- toolchain didn't match any values in provided spec
   end)
end

function build_scripts.env.configuration (spec)
if type(spec) ~= 'table' then
      spec = { spec }
   end

   return build_scripts.env.when(function (configured)
      for i = 1, #spec do
         local config = interpolate_string(tostring(spec[i]), configured)
         if config == configured.configuration then
            return true
         end
      end
      return false -- configuration didn't match any values in provided spec
   end)
end
