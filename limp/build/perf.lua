local time = require('be.time')
local perf_now = time.perf_now

local begin = { }

function perf_begin (obj)
   begin[obj] = perf_now()
end

function perf_end (obj, name)
   local now = perf_now()
   local elapsed_ms = time.perf_to_seconds(now - begin[obj]) * 1000
   be.log.short_verbose("Performance: " .. (name or tostring(obj)) .. ' took ' .. elapsed_ms .. ' ms')
   begin[obj] = nil
end
