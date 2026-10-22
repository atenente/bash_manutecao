@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Guia de Manutencao 2.0
color 0A

set "DATA_DIR=%LOCALAPPDATA%\GuiaManutencao2"
set "LOG_DIR=%DATA_DIR%\Logs"
set "BACKUP_DIR=%DATA_DIR%\Backups"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" >nul 2>&1
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "RUN_ID=%%i"
if not defined RUN_ID set "RUN_ID=%RANDOM%_%RANDOM%"
set "APP_LOG=%LOG_DIR%\Manutencao_%RUN_ID%.log"
set "TASK_LOG=%LOG_DIR%\UltimaTarefa_%RUN_ID%.log"
set "REPORT_FILE=%LOG_DIR%\Relatorio_%RUN_ID%.txt"

call :register_tasks
if /i "%~1"=="--admin-task" (
    set "ADMIN_TASK=%~2"
    goto elevated_task
)

call :log "Inicio do Guia de Manutencao 2.0"
goto main_menu

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
echo 0 - Sair
echo.
set "OPTION="
set /p "OPTION=Escolha: "
if "!OPTION!"=="0" goto exit_program
call :dispatch
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
for /f "usebackq tokens=1-9 delims=~" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$os=Get-CimInstance Win32_OperatingSystem; $disk=Get-CimInstance Win32_LogicalDisk -Filter ('DeviceID=''{0}''' -f $env:SystemDrive); $allIps=Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue; $ips=@(); foreach($item in $allIps){if($item.IPAddress -notlike '169.254*' -and $ips.Count -lt 2){$ips+= $item.IPAddress}}; $ip1=if($ips.Count -gt 0){$ips[0]}else{'Nao identificado'}; $ip2=if($ips.Count -gt 1){$ips[1]}else{'Nao identificado'}; '{0}~{1}~{2}~{3}~{4}~{5}~{6}~{7}~{8}' -f ($os.Caption -replace '[~]',' '),$os.Version,[math]::Round($os.FreePhysicalMemory/1MB,1),[math]::Round($os.TotalVisibleMemorySize/1MB,1),[math]::Floor($disk.FreeSpace/1GB),[math]::Floor($disk.Size/1GB),[math]::Floor($disk.FreeSpace*100/$disk.Size),$ip1,$ip2"`) do (
    set "OS_NAME=%%A"
    set "OS_VERSION=%%B"
    set "RAM_FREE=%%C"
    set "RAM_TOTAL=%%D"
    set "DISK_FREE=%%E"
    set "DISK_TOTAL=%%F"
    set "DISK_FREE_PCT=%%G"
    set "IP_ONE=%%H"
    set "IP_TWO=%%I"
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
echo Disco %SystemDrive%        : !DISK_FREE! GB livres de !DISK_TOTAL! GB ^(!DISK_STATUS!^)
echo Endereco IPv4    : !IP_ONE!  !IP_TWO!
echo Data e hora      : %DATE% %TIME:~0,5%
echo Logs             : !LOG_DIR!
echo Backups          : !BACKUP_DIR!
echo ================================================================
exit /b

:list_tasks
for /l %%i in (1,1,%task_count%) do echo %%i - [!task_role[%%i]!] !task_alias[%%i]!
exit /b

:dispatch
set "TASK_INDEX="
for /l %%i in (1,1,%task_count%) do if "!OPTION!"=="%%i" set "TASK_INDEX=%%i"
if not defined TASK_INDEX (
    echo Opcao invalida.
    call :log "Opcao invalida informada"
    exit /b 1
)
set "TASK_ID=!task_func[%TASK_INDEX%]!"
set "TASK_ROLE=!task_role[%TASK_INDEX%]!"
if /i "!TASK_ROLE!"=="ADMIN" (
    call :is_admin
    if "!ADMIN_RESULT!"=="0" (
        echo Solicitando permissao de administrador...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $p=Start-Process -FilePath $env:ComSpec -ArgumentList '/c', '""%~f0" --admin-task !TASK_ID!"' -Verb RunAs -PassThru -Wait; exit $p.ExitCode } catch { Write-Error $_; exit 1 }"
        set "ELEVATION_RESULT=!errorlevel!"
        if not "!ELEVATION_RESULT!"=="0" echo Elevacao cancelada ou indisponivel.
        exit /b !ELEVATION_RESULT!
    )
)
call :!TASK_ID!
set "TASK_RESULT=!errorlevel!"
call :log "Tarefa !TASK_ID! finalizada com codigo !TASK_RESULT!"
exit /b !TASK_RESULT!

:elevated_task
call :is_admin
if "!ADMIN_RESULT!"=="0" (
    echo Nao foi possivel obter permissao de administrador.
    call :log "Falha: tarefa administrativa sem elevacao"
    pause
    exit /b 1
)
set "TASK_INDEX="
for /l %%i in (1,1,%task_count%) do if /i "!task_func[%%i]!"=="%ADMIN_TASK%" set "TASK_INDEX=%%i"
if not defined TASK_INDEX (
    echo Tarefa administrativa invalida.
    call :log "Falha: identificador de tarefa elevado invalido"
    pause
    exit /b 1
)
set "TASK_ID=%ADMIN_TASK%"
call :log "Inicio da tarefa administrativa !TASK_ID!"
call :!TASK_ID!
set "TASK_RESULT=!errorlevel!"
call :log "Tarefa administrativa !TASK_ID! finalizada com codigo !TASK_RESULT!"
echo.
pause
exit /b !TASK_RESULT!

:is_admin
fltmc >nul 2>&1
if errorlevel 1 (set "ADMIN_RESULT=0") else set "ADMIN_RESULT=1"
exit /b

:confirm
set "CONFIRMATION="
set /p "CONFIRMATION=%~1 (S/N): "
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
set "RUN_OUTPUT=%TEMP%\GuiaManutencao2_!RUN_ID!_!RANDOM!.tmp"
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

:dashboard
call :show_dashboard
call :log "Painel de diagnostico atualizado"
exit /b 0

:save_report
call :log "Gerando relatorio detalhado"
(
    echo Relatorio do Guia de Manutencao 2.0
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
call :confirm "Criar backup de %%TEMP%% e limpar seus arquivos"
if errorlevel 1 exit /b 1
call :backup_folder "%TEMP%" "TEMP_USUARIO"
if errorlevel 1 exit /b 1
call :delete_contents "%TEMP%"
exit /b !errorlevel!

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
