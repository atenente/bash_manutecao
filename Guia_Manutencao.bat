@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
setlocal enabledelayedexpansion
title Ferramenta de Manutencao
color 0A

:: *********************************************************
:: (dev adiciona uma linha por task)
:: call :task nome_da_funcao "Apelido para o usuario"
:: *********************************************************
set "task_count=0"
call :task clean_temp "Limpar arquivos temporarios"
call :task clean_updates "Limpa arquivos de atualizacoes desnecessarios"
call :task flush_dns "Limpar cache DNS"
call :task :clean_trash "Esvazia lixeira"
call :task :reset_spooler "Restart na fila de impressao"
call :task :repair_system "Corrige arquivos corrompidos"
call :task :optimize_disk "Otimiza o disco (SSD/HD)"
:: *********************************************************

goto header

:: *********************************************************
:: NAO ALTERAR - lista as funções adicionadas em call :task
:: *********************************************************
:task
    set /a task_count+=1
    set "task_func[%task_count%]=%~1"
    set "task_alias[%task_count%]=%~2"
    exit /b

:list_task
    for /l %%i in (1,1,%task_count%) do echo %%i - !task_alias[%%i]!
    exit /b

:run_task
    if not defined task_func[%~1] (
        echo Opcao invalida.
        exit /b
    )
    call :!task_func[%~1]!
    exit /b
:: *********************************************************

:header
    cls
    :: disk c
    :disk_space
    set "DRIVE=%SystemDrive%"
    set "LIVREGB=?"
    set "TOTALGB=?"
    set "LIVREPCT=100"
    set "STATUSDISCO=DESCONHECIDO"

    for /f "usebackq tokens=1-3" %%A in (`powershell -NoProfile -Command "$d = Get-CimInstance Win32_LogicalDisk | Where-Object DeviceID -eq '%DRIVE%'; if ($d.Size) { '{0} {1} {2}' -f [math]::Floor($d.FreeSpace/1GB), [math]::Floor($d.Size/1GB), [math]::Floor($d.FreeSpace*100/$d.Size) }"`) do (
        set "LIVREGB=%%A"
        set "TOTALGB=%%B"
        set "LIVREPCT=%%C"
        set "STATUSDISCO=BOM"
    )

    if "%STATUSDISCO%"=="BOM" (
        if %LIVREPCT% LEQ 20 set "STATUSDISCO=ATENCAO"
        if %LIVREPCT% LEQ 10 set "STATUSDISCO=CRITICO"
    )

    :: network
    set REDE=[x] Desconectada
    powershell -NoProfile -Command "Try { Invoke-WebRequest -Uri 'https://www.google.com' -UseBasicParsing -TimeoutSec 5 | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
    if %errorlevel%==0 set REDE=Conectada

    :: IP
    set IP=Nao identificado
    for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "IPv4"') do (
        set IP=%%i
    )

    echo ==========================================================
    echo admin?         : %ADMIN%
    echo Computador     : %COMPUTERNAME%
    echo Usuario        : %USERNAME%
    echo Rede           : %REDE%
    echo IP             : %IP%
    echo Disco C        : (%LIVREPCT%%%) GB livres  - %STATUSDISCO%
    echo Data/Hora      : %DATE% %TIME:~0,5%
    echo.
    echo Criado por     : Anderson Tenente
    echo ==========================================================
    echo ==========================================================
    echo.
    echo                 MENU TAREFAS
    echo ----------------------------------------------------------
    call :list_task
    echo 0 - Sair
    echo.
    set "opcao="
    set /p opcao=Escolha: 
    if "%opcao%"=="0" exit /b
    call :run_task "%opcao%"
    echo.
    pause
    goto header

:: *********************************************************
:: TASKS (dev escreve as funcoes aqui)
:: Toda task deve terminar com exit /b
:: *********************************************************
:clean_temp
    echo Limpando temporarios...
    del /f /s /q "%TEMP%\*" >nul 2>&1
    for /d %%i in ("%TEMP%\*") do (
        rd /s /q "%%i" >nul 2>&1
    )
    del /f /s /q "C:\Windows\Temp\*" >nul 2>&1
    for /d %%i in ("C:\Windows\Temp\*") do (
        rd /s /q "%%i" >nul 2>&1
    )
    echo Limpeza concluida.
exit /b

:clean_updates
    echo Limpando arquivos...
    net stop wuauserv >nul 2>&1
    del /f /s /q "%systemroot%\SoftwareDistribution\Download\*-*" >nul 2>&1
    net start wuauserv >nul 2>&1
    echo Limpeza concluida.
exit /b

:flush_dns
    echo Limpando cache DNS...
    ipconfig /flushdns
    echo Limpeza concluida.
exit /b

:clean_trash
    echo Esvaziando lixeira...
    rd /s /q C:\$Recycle.Bin >nul 2>&1
    echo Lixeira limpa!
exit /b

:reset_spooler
    echo Reiniciando spooler de impressao...
    net stop spooler
    net start spooler
    echo Processo concluido.
exit /b

:repair_system
    echo Iniciando a verificacao
    sfc /scannow
    echo Verificacao concluido.
exit /b

:optimize_disk
    echo Iniciando a otimizacao
    defrag C: /O
    echo otimizacao concluida.
exit /b
:: *********************************************************
