@echo off
cd /d "%~dp0"
start "" "%~dp0..\Fiji\fiji-windows-x64.exe" --run "%~dp0TTC_Polygon_Guided.ijm"
