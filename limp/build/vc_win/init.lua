local table = table
local fs = be.fs

make_global('msvc_build_dir', 'msvc_build', -1)
make_global('msvc_out_dir', 'msvc_out', -1)
make_global('msvc_ipch_dir', 'ipch', -1)
make_global('msvc_debug_dir', 'Debug', -1)

local build_boost_rule
function make_build_boost_job (target)
   local rule = 'build_boost'
   if not build_boost_rule then
      make_rule('build_boost', 'cmd /s /c "call build_boost.cmd"', 'build_boost', {
         generator = 'true',
         rspfile = 'build_boost.cmd',
         rspfile_content = [[@echo off & $
cd %BOOST_HOME% & $
(if not exist b2.exe call bootstrap.bat) & $
((.\b2.exe "--stagedir=%~dp0$ext_lib_dir" "--build-dir=%~dp0$build_dir" --build-type=complete -d1 -j4 $
--with-system --with-locale --with-type_erasure $
define=BOOST_NO_RTTI define=BOOST_NO_TYPEID $
link=static threading=multi runtime-link=shared address-model=64 $
stage > "%~dp0$build_dir\.boost_log" 2>&1 ) && $
(move /Y %~dp0$ext_lib_dir\lib\*.lib %~dp0$ext_lib_dir && rd /Q /S %~dp0$ext_lib_dir\lib ) >nul )]]
      })
      build_boost_rule = true;
   end
   return job {
      outputs = { target },
      rule = rule,
      inputs = { source_path },
      implicit_inputs = { '$build_dir' }
   }
end

function configure_init ()
   local init_targets = { }
   local function add_init_target (target_or_job)
      if type(target_or_job) == 'table' then
         append_sequence(target_or_job.outputs, init_targets)
      else
         init_targets[#init_targets+1] = target_or_job
      end
   end

   add_init_target(make_mkdir_job('$build_dir'))
   add_init_target(make_mkdir_job('$out_dir'))
   add_init_target(make_mkdir_job('$include_dir'))
   add_init_target(make_mkdir_job('$stage_dir'))
   add_init_target(make_mkdir_job('$bin_dir'))
   add_init_target(make_mkdir_job('$deps_dir'))
   add_init_target(make_mkdir_job('$ext_src_dir'))
   add_init_target(make_mkdir_job('$ext_include_dir'))
   add_init_target(make_mkdir_job('$ext_lib_dir'))
   add_init_target(make_mkdir_job('$include_dir\\be', { '$include_dir' }))

   local group_include_dirs = { }
   for i = 1, #ordered_groups do
      local group = ordered_groups[i]

      local found_lib = false
      for i = 1, #group.projects do
         local project = group.projects[i]
         if project.is_lib then
            found_lib = true
         end
      end

      if found_lib then
         local source_path = fs.compose_path(parse_source_path(group, '.'), 'include')
         if fs.exists(source_path) then
            local link_path = fs.compose_path('$include_dir', 'be', group.name)
            make_dir_link_job(link_path, source_path, { '$include_dir\\be' })
            group_include_dirs[#group_include_dirs+1] = link_path
         end
      end
   end
   add_init_target(make_phony_job('init_include_links!', group_include_dirs))

   if external_deps.ext_headers then
      local ancestor_jobs = { }
      for i = 1, #external_deps.ext_headers do
         local entry = external_deps.ext_headers[i]
         
         local link_path = fs.compose_path('$ext_include_dir', entry.dest)
         local source_path = fs.compose_path('dep_modules', entry.source)

         local parent = fs.parent_path(link_path)
         local ancestor = parent
         while ancestor and ancestor ~= '' and ancestor ~= '$ext_include_dir' do
            if not ancestor_jobs[ancestor] then
               ancestor_jobs[ancestor] = make_mkdir_job(ancestor)
            end
            ancestor = fs.parent_path(ancestor)
         end

         if fs.is_directory(fs.compose_path(external_deps.path, entry.source)) then
            add_init_target(make_dir_link_job(link_path, source_path, { parent }))
         else
            add_init_target(make_file_link_job(link_path, source_path, { parent }))
         end
      end
   end

   if external_deps.ext_sources then
      local ancestor_jobs = { }
      for i = 1, #external_deps.ext_sources do
         local entry = external_deps.ext_sources[i]
         
         local link_path = fs.compose_path('$ext_src_dir', entry.dest)
         local source_path = fs.compose_path('dep_modules', entry.source)

         local parent = fs.parent_path(link_path)
         local ancestor = parent
         while ancestor and ancestor ~= '' and ancestor ~= '$ext_src_dir' do
            if not ancestor_jobs[ancestor] then
               ancestor_jobs[ancestor] = make_mkdir_job(ancestor)
            end
            ancestor = fs.parent_path(ancestor)
         end

         if fs.is_directory(fs.compose_path(external_deps.path, entry.source)) then
            add_init_target(make_dir_link_job(link_path, source_path, { parent }))
         else
            add_init_target(make_file_link_job(link_path, source_path, { parent }))
         end
      end
   end

   make_build_boost_job('$build_dir\\.boost_log')
   make_phony_job('%BOOST_HOME%\\boost', { '$build_dir\\.boost_log' })
   add_init_target(make_dir_link_job('$ext_include_dir\\boost', '%BOOST_HOME%\\boost', { '$ext_include_dir' }))

   make_touch_job('init!!', '$build_dir\\.i9d', init_targets)
   make_ninja_job('$build_dir\\.i9d', 'init!!', true)
   make_phony_job('init!', { '$build_dir\\.i9d' })
end

function configure_clean ()
   local deinit_targets = { }
   local function add_deinit_target (target_or_job)
      if type(target_or_job) == 'table' then
         append_sequence(target_or_job.outputs, deinit_targets)
      else
         deinit_targets[#deinit_targets+1] = target_or_job
      end
   end

   make_ninjatool_job('clean-ninja!', 'clean')
   make_rm_files_job('clean-rm-out_dir!', '$out_dir\\*.*', { 'clean-ninja!' })
   make_rm_files_job('clean-rm-pch!', '$build_dir\\*.pch')
   make_rm_files_job('clean-rm-pdb!', '$build_dir\\*.pdb')

   make_phony_job('clean!', { 'clean-ninja!', 'clean-rm-out_dir!', 'clean-rm-pch!', 'clean-rm-pdb!' })
   
   local clean_targets = { 'clean!' }
   local function add_rm_dir_job (named_path)
      add_deinit_target(make_rm_dir_job('rm_' .. named_path .. '!', '$' .. named_path, clean_targets))
   end

   add_rm_dir_job('build_dir')
   add_rm_dir_job('out_dir')
   add_rm_dir_job('include_dir')
   
   add_rm_dir_job('ext_src_dir')
   add_rm_dir_job('ext_include_dir')
   add_rm_dir_job('ext_lib_dir')

   add_deinit_target(make_rm_dir_job('rm_msvc_build_dir!', '$msvc_build_dir'))
   add_deinit_target(make_rm_dir_job('rm_msvc_out_dir!', '$msvc_out_dir'))
   add_deinit_target(make_rm_dir_job('rm_msvc_ipch_dir!', '$msvc_ipch_dir'))
   add_deinit_target(make_rm_dir_job('rm_msvc_debug_dir!', '$msvc_debug_dir'))
   add_deinit_target(make_rm_file_job('rm_msvc_db!', 'msvc.VC.db'))
   add_deinit_target(make_rm_file_job('rm_vscode_db!', '.vscode\\.browse.VC.db'))

   make_phony_job('deinit!', deinit_targets)
end
