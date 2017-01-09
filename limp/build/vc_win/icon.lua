local fs = require('be.fs')

function make_icon_rc_target (res_path, rc_path, icon_path)
   if not icon_path then error 'icon path not specified!' end
   local rc_func = make_rc_target(res_path, rc_path)

   local escaped_icon_path = icon_path:gsub('["\\]', '\\%0')
   local rc_contents = '101 ICON "' .. escaped_icon_path .. '"\nGLFW_ICON ICON "' .. escaped_icon_path .. '"'

   local putfile_func = make_putfile_target(rc_path, rc_contents)

   return function (t)
      t.extra = serialize_include('./')
      putfile_func {
         implicit_inputs = { icon_path },
         order_only_inputs = { 'init!' }
      }
      return rc_func(t)
   end
end
