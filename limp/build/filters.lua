
function build_scripts.env.when (fn)
   return function (t)
      if type(t) ~= 'table' then
         error 'Expected table!'
      end
      return function (configured)
         local func = fn
         if type(func) ~= 'function' then
            local err
            func, err = load('return ' .. fn, 'when()', 't', configured)
            if not func then
               error(err .. ' When expression: ' .. fn)
            end
         end

         if func(configured) then
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
