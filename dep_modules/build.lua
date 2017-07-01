deps {
   ext_include_dir 'glm'       { path 'glm/glm' },
   ext_include_dir 'gsl'       { path 'gsl/gsl' },
   ext_include_dir 'glbinding' { path 'glbinding/source/glbinding/include/glbinding' },
   ext_include_dir 'globjects' { path 'globjects/source/globjects/include/globjects' },
   ext_include_dir 'glfw'      { path 'glfw/include/GLFW' },
   ext_include_dir 'pugixml'   { path 'pugixml/src' },
   ext_include_dir 'catch'     { path 'catch/single_include' },
   ext_include_dir 'lua'       { },
   ext_include_dir 'stb'       { },
   ext_include_dir 'zlib'      { },

   ext_lib 'zlib-static' {
      path 'zlib',
      force_c,
      src {
         'adler32.c',
         'crc32.c',
         'deflate.c',
         'infback.c',
         'inffast.c',
         'inflate.c',
         'inftrees.c',
         'trees.c',
         'zutil.c'
      },
      define {
         'Z_SOLO',
         'ZLIB_CONST',
         'NO_FSEEKO',
         '_CRT_SECURE_NO_DEPRECATE',
         '_CRT_NONSTDC_NO_DEPRECATE'
      },
      export_define {
         'Z_SOLO',
         'ZLIB_CONST'
      }
   },

   ext_lib 'glbinding' {
      path 'glbinding',
      force_cxx,
      include 'source/glbinding/include/glbinding',
      src {
         'source/glbinding/source/Binding_*.cpp',
         pch_src 'source/glbinding/source/Binding_pch.cpp',
         pch 'Binding_pch.h'
      },
      src {
         'source/glbinding/source/gl/functions_*.cpp',
         pch_src 'source/glbinding/source/Binding_pch.cpp',
         pch '../Binding_pch.h'
      },
      src {
         'source/glbinding/source/*.cpp',
         'source/glbinding/source/gl/*.cpp',
         exclude 'source/glbinding/source/Binding_*.cpp',
         exclude 'source/glbinding/source/gl/functions_*.cpp'
      },
      define 'GLBINDING_STATIC_DEFINE',
      export_define 'GLFW_INCLUDE_NONE',
      toolchain 'vc_win' {
         link 'opengl32'
      }
   },

   ext_lib 'globjects' {
      path 'globjects',
      force_cxx,
      include 'source/globjects/include/globjects',
      src {
         'source/globjects/source/*.cpp',
         'source/globjects/source/base/*.cpp',
         'source/globjects/source/implementations/*.cpp',
         'source/globjects/source/registry/*.cpp'
      },
      define 'GLOBJECTS_STATIC_DEFINE',
      link_project 'glbinding'
   },

   ext_lib 'glfw' {
      path 'glfw',
      force_c,
      include 'include',
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
         define '_GLFW_WIN32',
         link 'opengl32'
      }
   },

   ext_lib 'luaxx' {
      path 'lua',
      force_cxx,
      src {
         '*.c',
         exclude 'lua.c',
         exclude 'luac.c'
      }
   }
}
