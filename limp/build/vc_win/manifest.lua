local fs = be.fs

local manifests = { }
function get_manifest_target (manifest_name, elevated, extra)
   local manifest_file = fs.compose_path('$build_dir', manifest_name .. '.manifest')
   local rc_file = fs.compose_path('$build_dir', manifest_name .. '.manifest.rc')
   local res_file = fs.compose_path('$build_dir', manifest_name .. '.manifest.res')

   local uacLevel
   if elevated then
      uacLevel = 'requireAdministrator'
   else
      uacLevel = 'asInvoker'
   end

   local manifest_contents = [[
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
   <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">
      <security>
         <requestedPrivileges>
            <requestedExecutionLevel level="]] .. uacLevel .. [[" uiAccess="false"/>
         </requestedPrivileges>
      </security>
   </trustInfo>
]] .. (extra or '') .. [[
</assembly>]]

   if manifests[manifest_name] then
      if manifests[manifest_name] ~= manifest_contents then
         error('There is already a manifest named "' .. manifest_name .. '" but its contents are different!')
      end
   else
      manifests[manifest_name] = manifest_contents

      make_putfile_job(manifest_file, manifest_contents, nil, { 'init!' })
      make_putfile_job(rc_file, [[
#include <winuser.h>
1 RT_MANIFEST "]] .. manifest_name .. '.manifest"', { manifest_file })
      make_rc_job(res_file, rc_file)
   end

   return res_file
end
