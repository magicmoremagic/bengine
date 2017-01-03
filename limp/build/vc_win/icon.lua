local fs = be.fs

function make_icon_rc_job (res_path, rc_path, icon_path)
   local escaped_icon_path = icon_path:gsub('["\\]', '\\%0')
   local rc_contents = [[
101 ICON "]] .. escaped_icon_path .. [["
GLFW_ICON ICON "]] .. escaped_icon_path .. '"'

   make_putfile_job(rc_path, rc_contents, { icon_path }, { 'init!' })
   return make_rc_job(res_path, rc_path, '/i"./"')
end
