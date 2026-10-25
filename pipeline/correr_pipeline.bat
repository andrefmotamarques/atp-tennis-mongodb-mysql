@echo off
REM =====================================================================
REM  Pipeline do trabalho ATP (Gestao de Big Data)
REM  Corre tudo no Docker das aulas e gera o atpdb.sql (dump) na pasta Entrega.
REM  Passos: mongoimport -> atpscript.json -> mongoexport -> import MySQL -> dump
REM          -> teste do atpscript.sql sobre o dump
REM  Requisitos: Docker Desktop aberto. Duplo clique neste ficheiro.
REM =====================================================================
setlocal
set "PIPE=%~dp0"
set "TRAB=%~dp0.."
set "DOCKER=%~dp0..\..\docker\dbdata"
set "ENTREGA=%~dp0..\Entrega"
set "LOG=%~dp0pipeline_log.txt"
set "MONGO_URI=mongodb://root:root@localhost:27017/atp?authSource=admin"
set "FIELDS=PlayerId,PlayerName,Born,Height,Hand,Tournament,Location,Date,Ground,Prize,Round,OpponentRank,Opponent,WL,Score"

echo Inicio: %date% %time% > "%LOG%"
cd /d "%DOCKER%" || goto :erro

echo [1/9] A arrancar MongoDB e MySQL...
docker compose up -d mongodb mysql >> "%LOG%" 2>&1 || goto :erro

echo [2/9] A esperar que o MySQL esteja pronto...
:espera
docker compose exec -T mysql mysqladmin -uroot -proot ping >nul 2>&1
if errorlevel 1 ( timeout /t 3 /nobreak >nul & goto :espera )

echo [3/9] A copiar ficheiros para as pastas partilhadas do Docker...
copy /Y "%TRAB%\bdjsonatpp\atpplayers.json" "%DOCKER%\mongo_files\atpplayers.json" >nul || goto :erro
copy /Y "%ENTREGA%\atpscript.json" "%DOCKER%\mongo_files\atpscript.json" >nul || goto :erro
copy /Y "%PIPE%import_mysql.sql" "%DOCKER%\mysql_files\import_mysql.sql" >nul || goto :erro
copy /Y "%ENTREGA%\atpscript.sql" "%DOCKER%\mysql_files\atpscript.sql" >nul || goto :erro

echo [4/9] mongoimport do atpplayers.json (1-3 min)...
echo ===== mongoimport ===== >> "%LOG%"
docker compose exec -T mongodb mongoimport --uri "%MONGO_URI%" --collection atpplayers --drop --file /tmp/import/atpplayers.json >> "%LOG%" 2>&1 || goto :erro

echo [5/9] Limpeza no MongoDB com o atpscript.json (pode demorar alguns minutos)...
echo ===== atpscript.json ===== >> "%LOG%"
docker compose exec -T mongodb mongosh "%MONGO_URI%" --quiet --file /tmp/import/atpscript.json >> "%LOG%" 2>&1 || goto :erro

echo [6/9] mongoexport para CSV...
echo ===== mongoexport ===== >> "%LOG%"
docker compose exec -T mongodb mongoexport --uri "%MONGO_URI%" --collection atpplayers --type csv --fields %FIELDS% --out /tmp/import/atpplayers.csv >> "%LOG%" 2>&1 || goto :erro
copy /Y "%DOCKER%\mongo_files\atpplayers.csv" "%DOCKER%\mysql_files\atpplayers.csv" >nul || goto :erro

echo [7/9] Import do CSV para o MySQL (bd atp)...
echo ===== import MySQL ===== >> "%LOG%"
docker compose exec -T mysql sh -c "mysql -uroot -proot < /var/lib/mysql-files/import_mysql.sql" >> "%LOG%" 2>&1 || goto :erro

echo [8/9] Dump da bd atp para atpdb.sql...
docker compose exec -T mysql sh -c "mysqldump -uroot -proot --databases atp --single-transaction --no-tablespaces --set-gtid-purged=OFF > /var/lib/mysql-files/atpdb.sql" >> "%LOG%" 2>&1 || goto :erro
copy /Y "%DOCKER%\mysql_files\atpdb.sql" "%ENTREGA%\atpdb.sql" >nul || goto :erro

echo [9/9] Teste: correr o atpscript.sql sobre a bd criada pelo dump...
echo ===== versao MySQL ===== >> "%LOG%"
docker compose exec -T mysql mysql -uroot -proot -e "SELECT VERSION();" >> "%LOG%" 2>&1
docker compose exec -T mysql sh -c "mysql -uroot -proot -e 'DROP DATABASE IF EXISTS atp; CREATE DATABASE atp;' && mysql -uroot -proot < /var/lib/mysql-files/atpdb.sql && mysql -uroot -proot --table < /var/lib/mysql-files/atpscript.sql > /var/lib/mysql-files/atpscript_output.txt 2>&1" >> "%LOG%" 2>&1 || goto :erro
copy /Y "%DOCKER%\mysql_files\atpscript_output.txt" "%PIPE%atpscript_output.txt" >nul

echo Fim: %date% %time% >> "%LOG%"
echo.
echo CONCLUIDO. Resultados em:
echo   %ENTREGA%\atpdb.sql
echo   %PIPE%pipeline_log.txt
echo   %PIPE%atpscript_output.txt
pause
exit /b 0

:erro
echo.
echo ERRO num dos passos. Ve o ficheiro %LOG%
pause
exit /b 1
