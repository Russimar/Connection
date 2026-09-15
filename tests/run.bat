@echo off
REM Executa a suite de testes uma vez por versao de Firebird instalada (D-28, D-29).
REM
REM Um processo carrega um unico fbclient.dll, e cliente 2.5 nao conversa com
REM servidor 5.0 — por isso a matriz e uma execucao por versao, com a versao
REM alvo passada por parametro, e nao as tres no mesmo processo.
REM
REM Versao ausente na maquina e marcada como skipped e NAO reprova a suite (D-30).
REM Retorna ERRORLEVEL 0 somente se todas as execucoes passarem.

setlocal enabledelayedexpansion
cd /d "%~dp0"

set "EXE=Win32\Debug\ConnectionTests.exe"
if not exist "%EXE%" (
  echo [run] Executavel nao encontrado. Rode build.bat primeiro.
  exit /b 1
)

REM %ProgramFiles% num processo 32 bits aponta para "Program Files (x86)",
REM onde o Firebird nao esta instalado. Usa ProgramW6432 quando disponivel.
set "RAIZ=%ProgramFiles%\Firebird"
if defined ProgramW6432 set "RAIZ=%ProgramW6432%\Firebird"
if not exist "%RAIZ%" set "RAIZ=C:\Program Files\Firebird"
set /a TOTAL=0
set /a FALHAS=0
set /a PULADAS=0

for %%V in (2_5 4_0 5_0) do (
  set "ACHOU="
  if exist "%RAIZ%\Firebird_%%V\isql.exe"     set "ACHOU=1"
  if exist "%RAIZ%\Firebird_%%V\bin\isql.exe" set "ACHOU=1"

  if defined ACHOU (
    set /a TOTAL+=1
    echo.
    echo ========================================================
    echo [run] Firebird %%V
    echo ========================================================
    "%EXE%" --firebird=%%V
    if errorlevel 1 (
      set /a FALHAS+=1
      echo [run] Firebird %%V: FALHOU
    ) else (
      echo [run] Firebird %%V: OK
    )
  ) else (
    set /a PULADAS+=1
    echo [run] Firebird %%V: ausente nesta maquina - skipped
  )
)

echo.
echo ========================================================
echo [run] Execucoes: !TOTAL!  Falhas: !FALHAS!  Skipped: !PULADAS!
echo ========================================================

if !TOTAL! EQU 0 (
  echo [run] ERRO: nenhuma versao de Firebird encontrada.
  exit /b 1
)
if !FALHAS! GTR 0 exit /b 1
exit /b 0
