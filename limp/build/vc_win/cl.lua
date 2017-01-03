local table = table
local fs = be.fs

make_global('clcmd', 'cl', 0)

make_global('cl_base', table.concat({
   '/nologo',
   '/c',
   '/showIncludes',
   '/utf-8',
   '/FS',
   '/std:c++latest',
   '/Gd',   -- __cdecl calling convention
   '/Gm-',  -- Disable minimal rebuild
   '/Gy',   -- Enable function-level linking
   '/GF',   -- Enable string pooling
   '/Zi',   -- Create PDB
   '/EHs',  -- C++ exceptions
   '/fp:precise',
   '/volatile:iso',
   '/w44746', -- Enable volatile access warning
   '/Qpar',
   '/Zc:rvalueCast'
}, ' '), 2)

make_global('cl_base_defines', table.concat({
   '/D_WINDOWS',
   '/DWIN32',
   '/D_WIN32',
   '/D_WIN32_WINNT=0x0601',
   '/DBE_NO_LEAKCHECK' -- VLD installer only adds paths to MSBuild config, not vcvarsall.bat
}, ' '), 2)

local function get_clflags (project, debug, optref)
   local options = { }
   local function add_option (option)
      options[#options+1] = option
   end

   local defines = { }
   local function add_define (define)
      defines[#defines+1] = define
   end

   if debug then
      add_define '_DEBUG'
      add_define 'DEBUG'

      add_option '/Od'   -- Disable optimization
      add_option '/MDd'  -- Multithreaded Debug DLL CRT
      add_option '/RTC1' -- Runtime stack/uninitialized checks
      add_option '/sdl-' -- Disable extra SDL checks
      add_option '/GS'   -- buffer overrun check
   else
      add_define 'NDEBUG'

      add_option '/Ox'   -- Full optimization
      add_option '/MD'   -- Multithreaded DLL CRT
      add_option '/GL'   -- Whole Program Optimization
      add_option '/sdl-' -- Disable extra SDL checks
      add_option '/GS'   -- buffer overrun check
   end

   if project.is_ext_lib then
      add_define '_CRT_SECURE_NO_WARNINGS'

      add_option '/W3'
      add_option '/wd4334' -- result of 32-bit shift implicitly converted to 64 bits (Lua)
   else
      add_define 'BE_ID_EXTERNS'
      add_define 'NOMINMAX'
      add_define '_HAS_AUTO_PTR_ETC=1'
      add_define 'GLM_FORCE_SSE4'
      add_define 'SQLITE_WIN32_GETVERSIONEX=0'

      if debug then
         add_define 'BE_DEBUG'
         add_define 'BE_DEBUG_TIMERS'
         add_define 'BE_ENABLE_MAIN_THREAD_ASSERTIONS'
      else
         add_define 'GSL_UNENFORCED_ON_CONTRACT_VIOLATION'
      end

      add_option '/W4'     -- warning level 4
      add_option '/WX'     -- warnings are errors
      add_option '/wd4201' -- nameless struct/union
      --add_option '/wd4310' -- cast truncates literal
      add_option '/wd4324' -- struct padding due to alignas()
      --add_option '/wd4351' -- elements of array 'array' will be default initialized
      add_option '/wd4458' -- declaration hides class member
      add_option '/wd4503' -- 'identifier' : decorated name length exceeded, name was truncated
      add_option '/wd4592' -- symbol will be dynamically initialized
      add_option '/wd5030' -- Unrecognized attribute
   end

   if project.is_lib then
      add_define 'BE_STATIC_LIB'
   end

   if project.test_type == 'perf' then
      add_define 'BE_TEST_PERF'
      add_option '/wd4702' -- Unreachable code
   elseif project.test_type then
      add_define 'BE_TEST'
      add_option '/wd4702' -- Unreachable code
   end

   if project.force_cxx then
      add_option '/TP'
   elseif project.force_c then
      add_option '/TC'
   end

   if project.rtti then
      add_option '/GR'
   else
      add_option '/GR-'
      add_define 'BOOST_NO_TYPEID'
      add_define 'BOOST_NO_RTTI'
   end

   if not project.is_dyn_lib then
      add_option '/GA'   -- TLS Optimization
   end

   if optref then
      add_option '/Gw'         -- Optimize globals
      add_option '/Zc:inline'  -- Remove unused symbols
   end

   for i = 1, #defines do
      local define = defines[i]
      if define and define ~= '' then
         if string.find(define, '%s') then
            add_option('/D"' .. define .. '"')
         else
            add_option('/D' .. define)
         end
      end
   end

   return table.concat(options, ' ')
end 

local rule_name
local clflags = { }
function get_clflags_var (project, debug)
   local name = { 'clflags' }
   local function add_name_suffix (suffix)
      name[#name+1] = '_'
      name[#name+1] = suffix
   end

   if project.force_cxx then add_name_suffix 'cxx'
   elseif project.force_c then add_name_suffix 'c'
   end

   if project.test_type then add_name_suffix(project.test_type) end
   if project.rtti then add_name_suffix 'rtti' end

   local optref
   if project.is_dyn_lib then add_name_suffix 'dll'
   elseif project.is_lib then add_name_suffix 'lib'
   elseif project.is_ext_lib then add_name_suffix 'extlib'
   else optref = true
   end

   if debug then add_name_suffix 'debug'
   else add_name_suffix 'release'
   end

   name = table.concat(name)

   if clflags[name] then
      return '$' .. name
   end

   if not rule_name then
      rule_name = 'cl'
      make_rule(rule_name, '$clcmd $cl_base $flags $cl_base_defines $extra /I"$include_dir" /I"$deps_dir" /I"$ext_include_dir" /Fo"$out" /Fd"$pdb" "$in"', 'cl $in', { deps = 'msvc' })
   end 

   local final = get_clflags(project, debug, optref)
   clflags[name] = final
   make_global(name, final, 2)

   return '$' .. name
end

function make_cl_job (obj_path, input_path, pdb_path, flags, extra, implicit_inputs)
   job {
      rule = rule_name,
      inputs = { input_path },
      implicit_inputs = implicit_inputs,
      order_only_inputs = { 'init!' },
      outputs = { obj_path },
      vars = {
         { name = 'pdb', value = pdb_path },
         { name = 'flags', value = flags },
         { name = 'extra', value = extra }
      }
   }
end

function get_obj_path (project, src_path, debug)
   local configuration = (debug and 'debug') or 'release'
   local relative_path = fs.ancestor_relative(fs.compose_path(root_dir, src_path), project.path)
   return fs.compose_path('$build_dir', configuration, project.name, fs.replace_extension(relative_path, '.obj'))
end
