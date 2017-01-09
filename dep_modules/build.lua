deps {
   ext_include_dir 'glm'      { path 'glm/glm' },
   ext_include_dir 'gsl'      { path 'gsl/gsl' },
   ext_include_dir 'glfw'     { path 'glfw/include/GLFW' },
   ext_include_dir 'lua'      { path 'lua/src' },
   ext_include_dir 'pugixml'  { path 'pugixml/src' },
   ext_include_dir 'catch'    { path 'catch/single_include' },
   ext_include_dir 'stb' { },
   ext_include_dir 'zlib' { },

   ext_lib 'zlib-static' {
      path 'zlib',
      force_c,
      src '*.c',
      define {
         'NO_FSEEKO',
         '_CRT_SECURE_NO_DEPRECATE',
         '_CRT_NONSTDC_NO_DEPRECATE'
      }
   },

   ext_lib 'glfw' {
      path 'glfw',
      force_c,
      include { 'include', 'src' },
      src {
         'src/context.c',
         'src/init.c',
         'src/input.c',
         'src/monitor.c',
         'src/vulkan.c',
         'src/window.c'
      },
      toolchain 'vc_win' {
         src {
            'src/win32_*.c',
            'src/wgl_*.c',
            'src/egl_*.c'
         },
         define '_GLFW_WIN32'
      }
   },

   ext_lib 'luaxx' {
      path 'lua',
      force_cxx,
      src {
         'src/*.c',
         exclude 'src/lua.c',
         exclude 'src/luac.c'
      }
   }
}
