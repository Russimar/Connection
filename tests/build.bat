@echo off
REM Compila a suite de testes da biblioteca Connection.
REM Alvo: Delphi 10.4 (Studio 21.0), Win32, console.
REM
REM Tenta MSBuild primeiro. Em maquinas cujo .dproj herda o search path
REM global do IDE, o MSBuild falha com MSB6003 ("command-line too long"):
REM nesse caso cai para dcc32.exe com o dcc32.cfg enxuto desta pasta, que
REM compila o mesmo projeto com os mesmos caminhos. Ver B-01 em
REM docs/bug-biblioteca-conexao/00-BLOQUEIOS.md.

setlocal
cd /d "%~dp0"

if not exist "%BDS%\bin\rsvars.bat" (
  if exist "C:\Program Files (x86)\Embarcadero\Studio\21.0\bin\rsvars.bat" (
    call "C:\Program Files (x86)\Embarcadero\Studio\21.0\bin\rsvars.bat"
  ) else (
    echo [build] ERRO: Delphi 10.4 nao encontrado. Defina BDS ou instale o Studio 21.0.
    exit /b 1
  )
) else (
  call "%BDS%\bin\rsvars.bat"
)

if exist "Win32\Debug\ConnectionTests.exe" del /q "Win32\Debug\ConnectionTests.exe"

echo [build] Tentando MSBuild...
msbuild ConnectionTests.dproj /t:Build /p:Config=Debug /p:Platform=Win32 /v:minimal >"%TEMP%\connbuild.log" 2>&1
if exist "Win32\Debug\ConnectionTests.exe" goto :ok

echo [build] MSBuild nao produziu o executavel; usando dcc32 direto.
dcc32.exe ConnectionTests.dpr
if errorlevel 1 (
  echo [build] ERRO: falha na compilacao com dcc32.
  exit /b 1
)

:ok
if not exist "Win32\Debug\ConnectionTests.exe" (
  echo [build] ERRO: executavel nao foi gerado.
  exit /b 1
)
echo [build] OK: Win32\Debug\ConnectionTests.exe
exit /b 0
