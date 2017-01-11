local fs = require('be.fs')

function msvc_build_dir () return get_directory('msvc_build') end
function msvc_out_dir () return get_directory('msvc_out') end
function msvc_ipch_dir () return get_directory('msvc_ipch', 'ipch') end
function msvc_debug_dir () return get_directory('msvc_debug', 'Debug') end

make_rule 'build_boost' {
   command = 'cmd /s /c "call build_boost.cmd"',
   description = 'build_boost',
   generator = 'true',
   rspfile = 'build_boost.cmd',
   rspfile_content = [[@echo off & $
cd %BOOST_HOME% & $
(if not exist b2.exe call bootstrap.bat) & $
((.\b2.exe "--stagedir=%~dp0]] .. ext_lib_dir() .. [[" "--build-dir=%~dp0]] .. build_dir() .. [[" $
--build-type=complete -d1 -j4 --with-system --with-locale --with-type_erasure $
define=BOOST_NO_RTTI define=BOOST_NO_TYPEID link=static threading=multi runtime-link=shared address-model=64 $
stage > "%~dp0]] .. build_dir() .. [[\.boost_log" 2>&1 ) && $
(move /Y %~dp0]] .. ext_lib_dir() .. [[\lib\*.lib %~dp0]] .. ext_lib_dir() .. [[ && $
rd /Q /S %~dp0]] .. ext_lib_dir() .. [[\lib ) >nul )]]
}

local function make_build_boost_target (target)
   if not target then error 'build_boost target not specified!' end
   return function (t)
      t.rule = rule 'build_boost'
      t.outputs = { target }
      t.implicit_inputs = { (build_dir()) }
      return make_target(t)
   end
end

local init_targets = { }
local function add_init_target (target)
   append_sequence(target.outputs, init_targets)
end

local mkdir_init_targets = { }
local function add_mkdir_init_target (dir)
   if not mkdir_init_targets[dir] then
      local t = { }
      local parent = fs.parent_path(dir)
      if parent and parent ~= '' then
         add_mkdir_init_target(parent)
         t.implicit_inputs = { parent }
      end
      t = make_mkdir_target(dir)(t)
      mkdir_init_targets[dir] = t
      add_init_target(t)
   end
end

local deinit_targets = { }
local function add_deinit_target (target)
   append_sequence(target.outputs, deinit_targets)
end

function configure_init_begin ()
   add_mkdir_init_target((build_dir()))
   add_mkdir_init_target((out_dir()))
   add_mkdir_init_target((include_dir()))
   add_mkdir_init_target((stage_dir()))
   add_mkdir_init_target((bin_dir()))
   add_mkdir_init_target((deps_dir()))
   add_mkdir_init_target((ext_include_dir()))
   add_mkdir_init_target((ext_lib_dir()))
end

function configure_init_group (configured)
   if configured.ext_include_dirs then
      local implicit_inputs = { (ext_include_dir()) }
      for i = 1, #configured.ext_include_dirs do
         add_init_target(configured.ext_include_dirs[i] {
            implicit_inputs = implicit_inputs
         })
      end
   end
end

local include_link_targets = { }
function configure_init_project (configured)
   if configured.configured_group.has_include_headers then
      local abs_source_path = fs.compose_path(configured.path, 'include')
      local link_parent_path = fs.compose_path(include_dir(), configured.namespace_path)
      local link_path = fs.compose_path(link_parent_path, configured.configured_group.name)

      if not mkdir_init_targets[link_path] and fs.exists(abs_source_path) then
         add_mkdir_init_target(link_parent_path)
         local rel_source_path = expand_path('include', configured.path)
         local t = make_lndir_target(link_path, rel_source_path) {
            implicit_inputs = { link_parent_path }
         }
         mkdir_init_targets[link_path] = t
         append_sequence(t.outputs, include_link_targets)
      end
   end
end

function configure_init_end ()
   add_init_target(make_phony_target 'init_include_links!' {
      inputs = include_link_targets
   })

   local boost_log_target = fs.compose_path(build_dir(), '.boost_log')
   make_build_boost_target(boost_log_target) { }
   make_phony_target '%BOOST_HOME%\\boost' {
      inputs = { boost_log_target }
   }

   add_init_target(make_lndir_target(fs.compose_path(ext_include_dir(), 'boost'), '%BOOST_HOME%\\boost') {
      implicit_inputs = { (ext_include_dir()) }
   })

   local initialized_target = fs.compose_path(build_dir(), '.i9d')

   make_touch_target(initialized_target) {
      path = initialized_target,
      implicit_inputs = init_targets
   }

   make_phony_target 'init!' {
      inputs = { initialized_target }
   }
end

function configure_clean ()
   make_ninja_tool_target('clean-ninja!', 'clean') { }

   make_rmfiles_target('clean-rm-out_dir!', fs.compose_path(out_dir(), '*.*')) {
      implicit_inputs = { 'clean-ninja!' }
   }
   make_rmfiles_target('clean-rm-pch!', fs.compose_path(build_dir(), '*.pch')) { }
   make_rmfiles_target('clean-rm-pdb!', fs.compose_path(build_dir(), '*.pdb')) { }

   local clean_targets = { 'clean-ninja!', 'clean-rm-out_dir!', 'clean-rm-pch!', 'clean-rm-pdb!' }

   make_phony_target 'clean!' {
      inputs = clean_targets
   }
   
   local function rmdir_target (dir, implicit_inputs)
      add_deinit_target(make_rmdir_target('rm_' .. dir .. '_dir!') {
         path = get_directory(dir),
         implicit_inputs = implicit_inputs
      })
   end

   rmdir_target('build', clean_targets)
   rmdir_target('out', clean_targets)
   rmdir_target('include', clean_targets)
   
   rmdir_target('ext_include', clean_targets)
   rmdir_target('ext_lib', clean_targets)

   msvc_build_dir() msvc_out_dir() msvc_ipch_dir() msvc_debug_dir()

   rmdir_target('msvc_build')
   rmdir_target('msvc_out')
   rmdir_target('msvc_ipch')
   rmdir_target('msvc_debug')
   add_deinit_target(make_rmfile_target 'rm_msvc_db!' {
      path = 'msvc.VC.db'
   })
   add_deinit_target(make_rmfile_target 'rm_vscode_db!' {
      path = '.vscode\\.browse.VC.db'
   })

   make_phony_target 'deinit!' {
      inputs = deinit_targets
   }
end
