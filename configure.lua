-- To reconfigure and build all projects, run:
-- $ limp -f build.ninja
-- $ ninja

toolchain = 'vc_win'
--toolchain = 'clang_linux'
--toolchain = 'gcc_linux'

include 'build/common'
include('build/' .. toolchain .. '/build')
include 'dep_modules/build'

find_projects('modules')
find_projects('tools')
find_projects('demos')

include 'build/generate'
