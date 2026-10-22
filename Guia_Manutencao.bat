@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Guia de Manutencao
color 0A

set "DATA_DIR=%LOCALAPPDATA%\GuiaManutencao"
set "LOG_DIR=%DATA_DIR%\Logs"
set "BACKUP_DIR=%DATA_DIR%\Backups"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" >nul 2>&1
if not exist "%LOG_DIR%\" (
    echo Nao foi possivel criar a pasta de logs: %LOG_DIR%
    exit /b 1
)
if not exist "%BACKUP_DIR%\" (
    echo Nao foi possivel criar a pasta de backups: %BACKUP_DIR%
    exit /b 1
)
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "RUN_ID=%%i"
if not defined RUN_ID set "RUN_ID=%RANDOM%_%RANDOM%"
set "APP_LOG=%LOG_DIR%\Manutencao_%RUN_ID%.log"
set "TASK_LOG=%LOG_DIR%\Tarefas_%RUN_ID%.log"
set "REPORT_FILE=%LOG_DIR%\Relatorio_%RUN_ID%.txt"

call :register_tasks
call :is_admin
if /i "%~1"=="--elevated" (
    if "!ADMIN_RESULT!"=="0" (
        echo Nao foi possivel iniciar o programa como administrador.
        exit /b 1
    )
    set "START_MODE=ADMIN"
    goto start_program
)

if "!ADMIN_RESULT!"=="0" goto choose_start_mode
set "START_MODE=ADMIN"
goto start_program

:choose_start_mode
echo Deseja executar o Guia como administrador?
echo S - Abrir o programa com permissao de administrador
echo N - Continuar sem permissao de administrador
:ask_start_mode
set "START_ADMIN="
set /p "START_ADMIN=Escolha (S/N, padrao S): "
if not defined START_ADMIN set "START_ADMIN=S"
if /i "!START_ADMIN!"=="S" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath $env:ComSpec -ArgumentList '/c', '""%~f0" --elevated"' -Verb RunAs; exit 0 } catch { Write-Error $_; exit 1 }"
    if errorlevel 1 (
        echo Nao foi possivel abrir o programa como administrador.
        pause
        exit /b 1
    )
    exit /b 0
)
if /i "!START_ADMIN!"=="N" (
    set "START_MODE=USER"
    goto start_program
)
echo Escolha S ou N.
goto ask_start_mode

:start_program
if "!START_MODE!"=="ADMIN" (
    call :log "Inicio do Guia de Manutencao como administrador"
) else (
    call :log "Inicio do Guia de Manutencao sem permissao de administrador"
)
goto main_menu

:: *********************************************************
:: (dev adiciona uma linha por task)
:: call :task nome_da_funcao "Apelido para o usuario" Tipo_de_permissao(USER ou ADMIN)
:: *********************************************************
:register_tasks
set "task_count=0"
call :task dashboard "Atualizar painel de diagnostico" USER
call :task save_report "Salvar relatorio detalhado" USER
call :task flush_dns "Limpar cache DNS" USER
call :task check_disk "Verificar disco (CHKDSK /scan)" ADMIN
call :task check_image "Verificar imagem do Windows (DISM /ScanHealth)" ADMIN
call :task verify_system "Verificar arquivos protegidos (SFC /verifyonly)" ADMIN
call :task clean_temp "Limpar temporarios com backup" ADMIN
call :task clean_updates "Limpar cache do Windows Update com backup" ADMIN
call :task clean_trash "Esvaziar lixeira" ADMIN
call :task reset_spooler "Reiniciar servico de impressao" ADMIN
call :task repair_image "Reparar imagem do Windows (DISM /RestoreHealth)" ADMIN
call :task repair_system "Reparar arquivos do Windows (SFC /scannow)" ADMIN
call :task optimize_disk "Otimizar disco" ADMIN
call :task open_backups "Abrir pasta de backups" USER
call :task open_logs "Abrir pasta de logs" USER
exit /b
:: *********************************************************

:task
set /a task_count+=1
set "task_func[%task_count%]=%~1"
set "task_alias[%task_count%]=%~2"
set "task_role[%task_count%]=%~3"
exit /b

:main_menu
cls
call :show_dashboard
echo.
echo MENU DE TAREFAS
echo ----------------------------------------------------------------
call :list_tasks
if "!VISIBLE_COUNT!"=="0" echo Nenhuma tarefa disponivel neste modo.
echo 0 - Sair
echo.
:menu_prompt
set "OPTION="
set /p "OPTION=Escolha: "
if "!OPTION!"=="0" goto exit_program
set "MENU_INVALID=0"
call :dispatch
if "!MENU_INVALID!"=="1" goto menu_prompt
echo.
pause
goto main_menu

:show_dashboard
set "IS_ADMIN=Nao"
call :is_admin
if "!ADMIN_RESULT!"=="1" set "IS_ADMIN=Sim"
set "OS_NAME=Indisponivel"
set "OS_VERSION=?"
set "RAM_FREE=?"
set "RAM_TOTAL=?"
set "DISK_FREE=?"
set "DISK_TOTAL=?"
set "DISK_FREE_PCT="
set "IP_ONE=Nao identificado"
set "IP_TWO=Nao identificado"
set "NETWORK_STATUS=Indisponivel"
for /f "usebackq tokens=1-10 delims=~" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$os=Get-CimInstance Win32_OperatingSystem; $disk=Get-CimInstance Win32_LogicalDisk -Filter ('DeviceID=''{0}''' -f $env:SystemDrive); $allIps=Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue; $ips=@(); foreach($item in $allIps){if($item.IPAddress -notlike '169.254*' -and $ips.Count -lt 2){$ips+= $item.IPAddress}}; $ip1=if($ips.Count -gt 0){$ips[0]}else{'Nao identificado'}; $ip2=if($ips.Count -gt 1){$ips[1]}else{'Nao identificado'}; $network='Desconectada'; try { Invoke-WebRequest -Uri 'https://www.google.com' -UseBasicParsing -TimeoutSec 5 | Out-Null; $network='Conectada' } catch {}; '{0}~{1}~{2}~{3}~{4}~{5}~{6}~{7}~{8}~{9}' -f ($os.Caption -replace '[~]',' '),$os.Version,[math]::Round($os.FreePhysicalMemory/1MB,1),[math]::Round($os.TotalVisibleMemorySize/1MB,1),[math]::Floor($disk.FreeSpace/1GB),[math]::Floor($disk.Size/1GB),[math]::Floor($disk.FreeSpace*100/$disk.Size),$ip1,$ip2,$network"`) do (
    set "OS_NAME=%%A"
    set "OS_VERSION=%%B"
    set "RAM_FREE=%%C"
    set "RAM_TOTAL=%%D"
    set "DISK_FREE=%%E"
    set "DISK_TOTAL=%%F"
    set "DISK_FREE_PCT=%%G"
    set "IP_ONE=%%H"
    set "IP_TWO=%%I"
    set "NETWORK_STATUS=%%J"
)
set "DISK_STATUS=DESCONHECIDO"
if defined DISK_FREE_PCT (
    set "DISK_STATUS=BOM"
    if !DISK_FREE_PCT! LEQ 20 set "DISK_STATUS=ATENCAO"
    if !DISK_FREE_PCT! LEQ 10 set "DISK_STATUS=CRITICO"
)
echo ================================================================
echo Computador       : %COMPUTERNAME%
echo Usuario          : %USERNAME%
echo Administrador    : !IS_ADMIN!
echo Windows          : !OS_NAME! - !OS_VERSION!
echo Memoria livre    : !RAM_FREE! GB de !RAM_TOTAL! GB
echo Disco %SystemDrive%         : !DISK_FREE! GB livres de !DISK_TOTAL! GB ^(!DISK_STATUS!^)
echo Rede             : !NETWORK_STATUS!
echo Endereco IPv4    : !IP_ONE!  !IP_TWO!
echo Data e hora      : %DATE% %TIME:~0,5%
echo Logs             : !LOG_DIR!
echo Backups          : !BACKUP_DIR!
echo ================================================================
exit /b

:list_tasks
call :build_visible_tasks
for /l %%i in (1,1,!VISIBLE_COUNT!) do call :show_visible_task %%i
exit /b

:build_visible_tasks
call :is_admin
set "VISIBLE_COUNT=0"
for /l %%i in (1,1,%task_count%) do (
    if /i "!task_role[%%i]!"=="USER" (
        set /a VISIBLE_COUNT+=1
        set "VISIBLE_TASK[!VISIBLE_COUNT!]=%%i"
    ) else if "!ADMIN_RESULT!"=="1" (
        set /a VISIBLE_COUNT+=1
        set "VISIBLE_TASK[!VISIBLE_COUNT!]=%%i"
    )
)
exit /b

:show_visible_task
set "TASK_INDEX=!VISIBLE_TASK[%~1]!"
echo %~1 - [!task_role[%TASK_INDEX%]!] !task_alias[%TASK_INDEX%]!
exit /b

:dispatch
call :build_visible_tasks
set "TASK_INDEX="
set "VISIBLE_INDEX="
for /l %%i in (1,1,!VISIBLE_COUNT!) do if "!OPTION!"=="%%i" set "VISIBLE_INDEX=%%i"
if defined VISIBLE_INDEX set "TASK_INDEX=!VISIBLE_TASK[%VISIBLE_INDEX%]!"
if not defined TASK_INDEX (
    echo Opcao invalida.
    set "MENU_INVALID=1"
    call :log "Opcao invalida informada"
    exit /b 1
)
set "TASK_ID=!task_func[%TASK_INDEX%]!"
set "TASK_ROLE=!task_role[%TASK_INDEX%]!"
if /i "!TASK_ROLE!"=="ADMIN" if "!ADMIN_RESULT!"=="0" (
    echo Esta tarefa requer permissao de administrador. Feche e abra o programa novamente como administrador.
    call :log "Tarefa administrativa recusada sem permissao elevada: !TASK_ID!"
    exit /b 1
)
call :!TASK_ID!
set "TASK_RESULT=!errorlevel!"
call :log "Tarefa !TASK_ID! finalizada com codigo !TASK_RESULT!"
exit /b !TASK_RESULT!

:is_admin
fltmc >nul 2>&1
if errorlevel 1 (set "ADMIN_RESULT=0") else set "ADMIN_RESULT=1"
exit /b

:confirm
set "CONFIRMATION="
set /p "CONFIRMATION=%~1 (S/N, padrao S): "
if not defined CONFIRMATION set "CONFIRMATION=S"
if /i "!CONFIRMATION!"=="S" exit /b 0
echo Operacao cancelada.
call :log "Operacao cancelada pelo usuario"
exit /b 1

:log
>>"%APP_LOG%" echo [%DATE% %TIME%] %~1
>>"%TASK_LOG%" echo [%DATE% %TIME%] %~1
exit /b

:run
set "RUN_DESCRIPTION=%~1"
set "RUN_OUTPUT=%TEMP%\GuiaManutencao_!RUN_ID!_!RANDOM!.tmp"
call :log "Executando: !RUN_DESCRIPTION!"
%2 %3 %4 %5 %6 %7 %8 %9 >"!RUN_OUTPUT!" 2>&1
set "RUN_RESULT=!errorlevel!"
if exist "!RUN_OUTPUT!" (
    type "!RUN_OUTPUT!"
    type "!RUN_OUTPUT!" >>"%APP_LOG%"
    type "!RUN_OUTPUT!" >>"%TASK_LOG%"
    del /q "!RUN_OUTPUT!" >nul 2>&1
)
call :log "Codigo de retorno: !RUN_RESULT!"
if not "!RUN_RESULT!"=="0" echo A tarefa terminou com codigo !RUN_RESULT!.
exit /b !RUN_RESULT!

:backup_folder
if not exist "%~1\" (
    echo Pasta de origem nao encontrada: %~1
    call :log "Falha: pasta de backup nao encontrada"
    exit /b 1
)
set "BACKUP_DEST=%BACKUP_DIR%\%RUN_ID%_%~2"
if not exist "!BACKUP_DEST!" mkdir "!BACKUP_DEST!" >nul 2>&1
if not exist "!BACKUP_DEST!\" (
    echo Nao foi possivel criar a pasta de backup: !BACKUP_DEST!
    call :log "Falha ao criar pasta de backup"
    exit /b 1
)
call :run "Backup de %~1" robocopy "%~1" "!BACKUP_DEST!" /E /COPY:DAT /DCOPY:DAT /R:1 /W:1
set "BACKUP_RESULT=!errorlevel!"
if !BACKUP_RESULT! GEQ 8 (
    echo Backup falhou. A limpeza foi interrompida.
    call :log "Backup interrompido: robocopy retornou !BACKUP_RESULT!"
    exit /b 1
)
call :log "Backup criado em !BACKUP_DEST!; codigo robocopy !BACKUP_RESULT!"
exit /b 0

:delete_contents
call :run "Remover conteudo de %~1" powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Get-ChildItem -LiteralPath '%~1' -Force -ErrorAction Stop | Remove-Item -Recurse -Force -ErrorAction Stop; exit 0 } catch { Write-Error $_; exit 1 }"
exit /b !errorlevel!

:: *********************************************************
:: TASKS (dev escrever as funcoes aqui para baixo)
:: Toda task deve terminar com exit /b 0
:: *********************************************************
:dashboard
call :show_dashboard
call :log "Painel de diagnostico atualizado"
exit /b 0

:save_report
call :log "Gerando relatorio detalhado"
(
    echo Relatorio do Guia de Manutencao
    echo Computador: %COMPUTERNAME%
    echo Usuario: %USERNAME%
    echo Data e hora: %DATE% %TIME%
    echo.
    echo ==== SYSTEMINFO ====
    systeminfo
    echo.
    echo ==== IPCONFIG /ALL ====
    ipconfig /all
    echo.
    echo ==== DRIVERQUERY ====
    driverquery
) >"%REPORT_FILE%" 2>&1
set "REPORT_RESULT=!errorlevel!"
if exist "%REPORT_FILE%" (
    echo Relatorio salvo em: %REPORT_FILE%
    call :log "Relatorio salvo em %REPORT_FILE%"
    exit /b !REPORT_RESULT!
)
echo Nao foi possivel salvar o relatorio.
call :log "Falha ao salvar relatorio"
exit /b 1

:flush_dns
call :run "Limpar cache DNS" ipconfig /flushdns
exit /b !errorlevel!

:check_disk
call :run "Verificar disco" chkdsk %SystemDrive% /scan
exit /b !errorlevel!

:check_image
call :run "Verificar imagem do Windows" DISM /Online /Cleanup-Image /ScanHealth
exit /b !errorlevel!

:verify_system
call :run "Verificar arquivos protegidos" sfc /verifyonly
exit /b !errorlevel!

:clean_temp
call :confirm "Criar backups e limpar temporarios do usuario e do Windows"
if errorlevel 1 exit /b 1
call :backup_folder "%TEMP%" "TEMP_USUARIO"
if errorlevel 1 exit /b 1
call :backup_folder "%SystemRoot%\Temp" "TEMP_WINDOWS"
if errorlevel 1 exit /b 1
call :delete_contents "%TEMP%"
set "USER_TEMP_RESULT=!errorlevel!"
call :delete_contents "%SystemRoot%\Temp"
set "WINDOWS_TEMP_RESULT=!errorlevel!"
if not "!USER_TEMP_RESULT!"=="0" exit /b 1
if not "!WINDOWS_TEMP_RESULT!"=="0" exit /b 1
echo Limpeza dos temporarios concluida.
exit /b 0

:clean_updates
call :confirm "Criar backup e limpar o cache do Windows Update"
if errorlevel 1 exit /b 1
call :backup_folder "%SystemRoot%\SoftwareDistribution\Download" "WINDOWS_UPDATE"
if errorlevel 1 exit /b 1
call :run "Parar o servico Windows Update" net stop wuauserv
if errorlevel 1 (
    echo Nao foi possivel parar o servico; limpeza cancelada.
    call :log "Limpeza do Windows Update abortada: falha ao parar wuauserv"
    exit /b 1
)
call :delete_contents "%SystemRoot%\SoftwareDistribution\Download"
set "CLEAN_RESULT=!errorlevel!"
call :run "Reiniciar o servico Windows Update" net start wuauserv
if errorlevel 1 echo Aviso: nao foi possivel reiniciar wuauserv.
exit /b !CLEAN_RESULT!

:clean_trash
call :confirm "Esvaziar permanentemente a lixeira da unidade do Windows"
if errorlevel 1 exit /b 1
call :run "Esvaziar lixeira" powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Clear-RecycleBin -DriveLetter '%SystemDrive:~0,1%' -Force -ErrorAction Stop; exit 0 } catch { Write-Error $_; exit 1 }"
exit /b !errorlevel!

:reset_spooler
call :confirm "Reiniciar o servico de impressao"
if errorlevel 1 exit /b 1
call :run "Parar o Spooler" net stop spooler
if errorlevel 1 exit /b 1
call :run "Iniciar o Spooler" net start spooler
exit /b !errorlevel!

:repair_image
call :confirm "Reparar a imagem do Windows com DISM"
if errorlevel 1 exit /b 1
call :run "Reparar imagem do Windows" DISM /Online /Cleanup-Image /RestoreHealth
exit /b !errorlevel!

:repair_system
call :confirm "Verificar e reparar arquivos protegidos do Windows"
if errorlevel 1 exit /b 1
call :run "Reparar arquivos do Windows" sfc /scannow
exit /b !errorlevel!

:optimize_disk
call :confirm "Otimizar a unidade do Windows"
if errorlevel 1 exit /b 1
call :run "Otimizar disco" defrag %SystemDrive% /O
exit /b !errorlevel!

:open_backups
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" >nul 2>&1
start "" "%BACKUP_DIR%"
call :log "Pasta de backups aberta"
exit /b 0

:open_logs
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1
start "" "%LOG_DIR%"
call :log "Pasta de logs aberta"
exit /b 0

:exit_program
call :log "Encerramento do Guia de Manutencao"
exit /b 0
