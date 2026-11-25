@echo off
title Yg Remastered - Web
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve_web.ps1"
if errorlevel 1 pause
