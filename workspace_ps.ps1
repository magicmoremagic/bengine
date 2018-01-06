Push-Location $PSScriptRoot

#Install-Module VSSetup -Scope CurrentUser
$_vs2017 = $(try { Get-VSSetupInstance -All | Select-VSSetupInstance -Require 'Microsoft.VisualStudio.Workload.NativeDesktop' } catch { $null })
if ($_vs2017) {
   $_vcvarsall = $_vs2017.InstallationPath + '\VC\Auxiliary\Build\vcvarsall.bat'
}

if (-not ($_vcvarsall -and (Test-Path $_vcvarsall))) {
   if ($env:VSINSTALLDIR) {
      $_vcvarsall = $env:VSINSTALLDIR + 'VC\vcvarsall.bat'
   } else {
      $_vcvarsall = 'C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat'
   }

   if (-not ($_vcvarsall -and (Test-Path $_vcvarsall))) {
      $_vcvarsall = 'C:\Program Files (x86)\Microsoft Visual C++ Build Tools\vcbuildtools.bat'
      if (-not ($_vcvarsall -and (Test-Path $_vcvarsall))) {
         Write-Host 'Failed to locate vcvarsall.bat'
         pause
         exit 1
      }
   }
}

$_oldpath = $ENV:Path

cmd /s /c "`"$($_vcvarsall)`" x86_x64 & set" | ForEach-Object {
   if ($_ -match "=") {
      $v = $_.Split("=")
      Set-Item -force -path "ENV:\$($v[0])" -value "$($v[1])"
   }
}

$ENV:Path = "$($PSScriptRoot)\stage;$($PSScriptRoot)\bin;$($ENV:Path)"

#Clear-Host
powershell -nologo

$ENV:Path = $_oldpath
Pop-Location
