# bengine
bengine is a C++ framework for creating 2D, 2.5D, and simple 3D games.  Anyone
who finds it useful is welcome to use all or part of it for their own purposes,
however currently it is primarily a sandbox in which I can experiment with
various game-related systems and a platform on which I can build my own games.
So keep in mind that *all* code is subject to change or removal at any time.
Any branches other than `master` may be subject to destructive rebasing and
force-pushes.


## Design Priorities
<dl>
   <dt>Modular</dt>
      <dd>Systems should rely on as few other systems as possible.  Systems are
          packaged as static libraries in most cases, and individual
          applications link against whichever modules they need to use.</dd>
   <dt>Cross-Platform</dt>
      <dd>Platform-specific code should be abstracted or wrapped and separated
          from the rest of the codebase in order to make supporting new
          platforms easier.  Currently only Windows x64 is supported, but it
          should be possible to support any x64 platform in the future.</dd>
   <dt>Flexible</dt>
      <dd>It should be easy to use and extend systems for new purposes.  Generic
          programming is embraced.  When considering a tradeoff between
          simplicity of usage and simplicity of implementation, prefer the
          former.  When considering a tradeoff between flexibility or
          performance, lean towards the former unless it is a known
          bottleneck.</dd>
   <dt>Portable</dt>
      <dd>The end-user runtime requirements should be minimal.  Ideally any
          system with the compiler runtime and an OpenGL 3+ video card/driver
          should be able to run programs without needing to run an installer
          first.  Configuration and other persistent data are stored in files,
          not the Windows registry.  Assets are packaged together for faster
          and easier file transfers.</dd>
</dl>


## Modules
 - [belua](https://github.com/magicmoremagic/bengine-belua)
 - [blt](https://github.com/magicmoremagic/bengine-blt)
 - [cli](https://github.com/magicmoremagic/bengine-cli)
 - [core](https://github.com/magicmoremagic/bengine-core)
 - [ctable](https://github.com/magicmoremagic/bengine-ctable)
 - [gfx](https://github.com/magicmoremagic/bengine-gfx)
 - [perf](https://github.com/magicmoremagic/bengine-perf)
 - [platform](https://github.com/magicmoremagic/bengine-platform)
 - [sqlite](https://github.com/magicmoremagic/bengine-sqlite)
 - [testing](https://github.com/magicmoremagic/bengine-testing)
 - [util](https://github.com/magicmoremagic/bengine-util)
 

## Tools
 - [`bltc`](https://github.com/magicmoremagic/bengine-bltc)
 - [`bstyle`](https://github.com/magicmoremagic/bengine-bstyle)
 - [`ccolor`](https://github.com/magicmoremagic/bengine-ccolor)
 - [`concur`](https://github.com/magicmoremagic/bengine-concur)
 - [`idgen`](https://github.com/magicmoremagic/bengine-idgen)
 - [`limp`](https://github.com/magicmoremagic/bengine-limp)
 - [`sizeof`](https://github.com/magicmoremagic/bengine-sizeof)
 - [`sysinfo`](https://github.com/magicmoremagic/bengine-sysinfo)
 - [`wedo`](https://github.com/magicmoremagic/bengine-wedo)


## Demos
 - [`consolecolors`](https://github.com/magicmoremagic/consolecolors)


## Libraries 
 - [Boost](http://www.boost.org/) (External; 1.63 or newer recommended)
 - [Lua 5.3](https://github.com/magicmoremagic/lua) (Fork; 5.3.3+)
 - [GLFW](https://github.com/magicmoremagic/glfw) (Fork; 3.1.2+)
 - [GLM](https://github.com/magicmoremagic/glm) (Fork; 0.9.8.3+)
 - [GLI](https://github.com/g-truc/gli)
 - [GSL](https://github.com/Microsoft/GSL)
 - [STB](https://github.com/nothings/stb)
 - [glbinding 2.1.1](https://github.com/cginternals/glbinding)
 - [Catch 1.6.1](https://github.com/philsquared/Catch)
 - [pugixml 1.9](https://github.com/zeux/pugixml)
 - [zlib 1.2.11](https://github.com/madler/zlib)
 - [SQLite 3.16.2](http://sqlite.org/) (Internal)

Boost must be downloaded and extracted separately.  Set the `BOOST_HOME`
environment variable to point to the path where the archive was extracted.
The SQLite source amalgamation is distributed within this repository.  All
all other libraries are referenced as git submodules.


## Building
bengine uses the Ninja build system.  The Ninja build script is generated by a
custom Lua frontend.  Most development is done in Visual Studio, so `.vcxproj`
files are also provided, however they may use slightly different settings
compared to Ninja builds.

Some files are partially or fully generated.  This includes Ragel lexers and
Lua scripts embedded in source files as comments, which are subsequently
executed by the `limp` tool (included as part of bengine).

### Build Requirements
 - [Ninja](https://ninja-build.org/)
 - [Visual Studio 2015](https://www.visualstudio.com/) or [Visual C++ Build Tools](http://landinghub.visualstudio.com/visual-cpp-build-tools) (Windows)
 - [Visual Leak Detector](https://vld.codeplex.com/) (Windows; optional)
 - [Ragel](http://www.colm.net/open-source/ragel/) (optional; code generation)
 - [Limp](https://github.com/magicmoremagic/bengine-limp) (included; code generation)

### Building on Windows
```
:: Ensure BOOST_HOME environment variable is set:
> SET BOOST_HOME=C:\path\to\boost

:: Clone submodule repositories and build external libraries:
> setup

:: Open a VS command prompt for development and testing:
> workspace

:: Regenerate build.ninja:
> ninja configure!
:: Or alternatively:
> limp -f build.ninja

:: Build all modules, tools, and demos:
> ninja

:: List all top-level targets:
> ninja -t targets

:: Run all limp rules: (changes are not always detected normally by Ninja)
> ninja limp!

:: Clean up intermediate ninja build files and libraries:
> ninja clean!

:: Clean up all build files (Ninja and VS; useful before copying/moving repo to another location)
> ninja deinit!
```


## Name
bengine is a portmanteau of *Ben* and *engine*.  Thus it is pronounced
*been-gin*, not *bee-engine*.  When written, *bengine* should never be
capitalized, even when it starts a sentence.


## License
Excepting the libraries listed above, bengine is provided under the [MIT License](./license.md).

---

Copyright &copy; 2011-2017 Benjamin M. Crist
