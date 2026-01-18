@echo off
REM 在 Windows 构建前修复 CMake 配置
REM 移除 flutter_sound 插件引用

set CMAKE_FILE=%~dp0flutter\generated_plugins.cmake

if exist "%CMAKE_FILE%" (
    powershell -Command "(Get-Content '%CMAKE_FILE%') -replace 'flutter_sound\s*,\s*', '' | Set-Content '%CMAKE_FILE%'"
    echo Fixed CMake plugins file
)
