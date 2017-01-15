include 'build/perf'
perf_begin 'configure.lua'

perf_begin 'general includes'
include 'build/build_scripts'
include 'build/util'
local groups = include 'build/groups'
local projects = include 'build/projects'
include 'build/properties'
include 'build/filters'

include 'build/globals'
include 'build/ninja_version'
include 'build/directories'
include 'build/rules'
include 'build/targets'
include 'build/phony_targets'
include 'build/shell_targets'
include 'build/limp_targets'
include 'build/custom_targets'
perf_end 'general includes'

local tc, configs = ...
configs = configs or { 'debug', 'release' }
if type(configs) ~= 'table' then
   configs = { configs }
end

perf_begin 'toolchain include'
local toolchain_hooks = include('build/' .. tc .. '/configure') or { }
perf_end 'toolchain include'

perf_begin 'build script search'
include 'build_scripts'
perf_end 'build script search'

-- Initialization
if toolchain_hooks.init then
   perf_begin 'toolchain init'
   toolchain_hooks.init(configs)
   perf_end 'toolchain init'
end

perf_begin 'build script execution'
build_scripts.execute()
perf_end 'build script execution'

-- Configure groups & projects
perf_begin 'configure'
perf_begin 'configure groups'
for g = 1, #groups do
   local group = groups[g]
   for c = 1, #configs do
      local config = configs[c]
      configure_group(group, tc, config)
   end
end
perf_end 'configure groups'

perf_begin 'configure projects'
for p = 1, #projects do
   local project = projects[p]
   for c = 1, #configs do
      local config = configs[c]
      local configured_group = project.group.configurations[config]
      local configured = configure_project(project, tc, config, configured_group)
   end
end
perf_end 'configure projects'

perf_begin 'configure finalize projects'
for p = 1, #projects do
   local project = projects[p]
   for c = 1, #configs do
      local config = configs[c]
      local configured_project = project.configurations[config]
      finalize_project_configuration(configured_project, groups, projects)
   end
end
perf_end 'configure finalize projects'
perf_end 'configure'

-- Preprocessing
perf_begin 'preprocess'
if toolchain_hooks.preprocess_begin then
   perf_begin 'toolchain preprocess_begin'
   toolchain_hooks.preprocess_begin(groups, projects, configs)
   perf_end 'toolchain preprocess_begin'
end

if toolchain_hooks.preprocess_group then
   perf_begin 'toolchain preprocess_group'
   for g = 1, #groups do
      local group = groups[g]
      for c = 1, #configs do
         local config = configs[c]
         local configured_group = group.configurations[config]
         toolchain_hooks.preprocess_group(configured_group)
      end
   end
   perf_end 'toolchain preprocess_group'
end

if toolchain_hooks.preprocess then
   perf_begin 'toolchain preprocess'
   toolchain_hooks.preprocess(groups, projects, configs)
   perf_end 'toolchain preprocess'
end

if toolchain_hooks.preprocess_project then
   perf_begin 'toolchain preprocess_project'
   for p = 1, #projects do
      local project = projects[p]
      for c = 1, #configs do
         local config = configs[c]
         local configured_project = project.configurations[config]
         toolchain_hooks.preprocess_project(configured_project)
      end
   end
   perf_end 'toolchain preprocess_project'
end

if toolchain_hooks.preprocess_end then
   perf_begin 'toolchain preprocess_end'
   toolchain_hooks.preprocess_end(groups, projects, configs)
   perf_end 'toolchain preprocess_end'
end
perf_end 'preprocess'

-- Processing
perf_begin 'process'

local external_targets = { }
local all_targets = { }
local all_config_targets = { }

for c = 1, #configs do
   all_config_targets[configs[c]] = { }
end

for g = 1, #groups do
   local group = groups[g]

   local perf_name = 'process group ' .. group.name
   perf_begin(perf_name)

   if toolchain_hooks.group_begin then
      toolchain_hooks.group_begin(group, configs)
   end

   local group_targets = { }
   local group_config_targets = { }

   for c = 1, #configs do
      local configured_group = group.configurations[configs[c]]
      if toolchain_hooks.configured_group_begin then
         toolchain_hooks.configured_group_begin(configured_group, configs)
      end

      group_config_targets[configs[c]] = { }
   end

   for p = 1, #group.projects do
      local project = group.projects[p]

      if toolchain_hooks.project_begin then
         toolchain_hooks.project_begin(project, configs)
      end

      local project_targets = { }

      for c = 1, #configs do
         local configured_project = project.configurations[configs[c]]
         local target
         if configured_project and toolchain_hooks.process then
            target = toolchain_hooks.process(configured_project, configs)
            if target and configured_project.is_ext then
               external_targets[#external_targets+1] = target
            end
         end

         local phony_target = 'project-' .. configured_project.name .. '-' .. configs[c] .. '!'
         project_targets[#project_targets+1] = phony_target
         group_config_targets[configs[c]][#group_config_targets[configs[c]]+1] = phony_target
         make_phony_target(phony_target) {
            inputs = { target }
         }
      end

      local phony_target = 'project-' .. project.name .. '!'
      group_targets[#group_targets+1] = phony_target
      make_phony_target(phony_target) {
         inputs = project_targets
      }

      if toolchain_hooks.project_end then
         toolchain_hooks.project_end(project, configs)
      end
   end

   for c = 1, #configs do
      local configured_group = group.configurations[configs[c]]
      local targets = group_config_targets[configs[c]]
      local phony_target = 'group-' .. configured_group.name .. '-' .. configs[c] .. '!'
      all_config_targets[configs[c]][#all_config_targets[configs[c]]+1] = phony_target
      make_phony_target(phony_target) {
         inputs = targets
      }
   end

   local phony_target = 'group-' .. group.name .. '!'
   all_targets[#all_targets+1] = phony_target
   make_phony_target(phony_target) {
      inputs = group_targets
   }

   if toolchain_hooks.configured_group_end then
      for c = 1, #configs do
         local configured_group = group.configurations[configs[c]]
         toolchain_hooks.configured_group_end(configured_group, configs)
      end
   end

   if toolchain_hooks.group_end then
      toolchain_hooks.group_end(group, configs)
   end

   perf_end(perf_name)
end

for c = 1, #configs do
   local targets = all_config_targets[configs[c]]
   local phony_target = 'all-' .. configs[c] .. '!'
   make_phony_target(phony_target) {
      inputs = targets
   }
end

make_phony_target 'all!' {
   inputs = all_targets,
   default = true
}

make_phony_target 'externals!' {
   inputs = external_targets
}

make_meta_limp_target()

perf_end 'process'

-- Postprocessing
if toolchain_hooks.postprocess_begin then
   perf_begin 'toolchain postprocess_begin'
   toolchain_hooks.postprocess_begin(groups, projects, configs)
   perf_end 'toolchain postprocess_begin'
end

if toolchain_hooks.postprocess_project then
   perf_begin 'toolchain postprocess_project'
   for p = 1, #projects do
      local project = projects[p]
      for c = 1, #configs do
         local config = configs[c]
         local configured_project = project.configurations[config]
         toolchain_hooks.postprocess_project(configured_project)
      end
   end
   perf_end 'toolchain postprocess_project'
end

if toolchain_hooks.postprocess then
   perf_begin 'toolchain postprocess'
   toolchain_hooks.postprocess(groups, projects, configs)
   perf_end 'toolchain postprocess'
end

if toolchain_hooks.postprocess_group then
   perf_begin 'toolchain postprocess_group'
   for g = 1, #groups do
      local group = groups[g]
      for c = 1, #configs do
         local config = configs[c]
         local configured_group = group.configurations[config]
         toolchain_hooks.postprocess_group(configured_group)
      end
   end
   perf_end 'toolchain postprocess_group'
end

if toolchain_hooks.postprocess_end then
   perf_begin 'toolchain postprocess_end'
   toolchain_hooks.postprocess_end(groups, projects, configs)
   perf_end 'toolchain postprocess_end'
end

-- build.ninja serialization
perf_begin 'template serialization'
write_globals()
write_rules()
write_targets()
perf_end 'template serialization'

-- Cleanup
if toolchain_hooks.cleanup then
   perf_begin 'toolchain cleanup'
   toolchain_hooks.cleanup()
   perf_end 'toolchain cleanup'
end

perf_end 'configure.lua'
