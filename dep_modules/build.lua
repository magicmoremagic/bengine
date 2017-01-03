local function get_glfw_src()
   local src = {
      'src/context.c',
      'src/init.c',
      'src/input.c',
      'src/monitor.c',
      'src/vulkan.c',
      'src/window.c'
   }

   -- TODO maybe add a system to make specifying platform-specific files cleaner? (ie. without having to resort to a function call)
   if is_windows then
      src[#src+1] = 'src/win32_*.c'
      src[#src+1] = 'src/wgl_*.c'
      src[#src+1] = 'src/egl_*.c'
   end

   return src
end

deps {
   ext_headers = {
      { dest = 'glm', source = 'glm/glm' },
      { dest = 'gsl', source = 'gsl/gsl' },
      { dest = 'glfw', source = 'glfw/include/GLFW' },

      -- TODO wildcard/glob support might be nice here
      { dest = 'zlib.h', source = 'zlib/zlib.h' },
      { dest = 'zconf.h', source = 'zlib/zconf.h' },

      { dest = 'stb_image.h', source = 'stb/stb_image.h' },
      { dest = 'stb_image_resize.h', source = 'stb/stb_image_resize.h' },
      { dest = 'stb_image_write.h', source = 'stb/stb_image_write.h' },

      { dest = 'lua/lua.h', source = 'lua/src/lua.h' },
      { dest = 'lua/luaconf.h', source = 'lua/src/luaconf.h' },
      { dest = 'lua/lualib.h', source = 'lua/src/lualib.h' },
      { dest = 'lua/lauxlib.h', source = 'lua/src/lauxlib.h' },

      { dest = 'catch.hpp', source = 'catch/single_include/catch.hpp' }
   },
   ext_sources = {
      { dest = 'lua', source = 'lua/src' },

      { dest = 'pugiconfig.hpp', source = 'pugixml/src/pugiconfig.hpp' },
      { dest = 'pugixml.hpp', source = 'pugixml/src/pugixml.hpp' },
      { dest = 'pugixml.cpp', source = 'pugixml/src/pugixml.cpp' }
   },

   projects = {
      ext_lib { name = 'zlib-static',
         path = 'zlib',
         force_c = true,
         src = {
            '*.c'
         },
         preprocessor = {
            'NO_FSEEKO',
            '_CRT_SECURE_NO_DEPRECATE',
            '_CRT_NONSTDC_NO_DEPRECATE'
         }
      },
      ext_lib { name = 'glfw',
         path = 'glfw',
         force_c = true,
         include = {
            'include',
            'src'
         },
         src = get_glfw_src(),
         preprocessor = {
            '_GLFW_WIN32'
         }
      },
      ext_lib { name = 'luaxx',
         path = 'lua',
         force_cxx = true,
         src = {
            'src/*.c',
            exclude = {
               'src/lua.c',
               'src/luac.c'
            }
         }
      }
   }
}
