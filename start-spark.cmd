@echo off
Echo Starting spark...

set OLD_HADOOP_HOME=%HADOOP_HOME%

for /f "delims=" %%a in ('hadoop-2.7.1\bin\hadoop classpath') do @set SPARK_DIST_CLASSPATH=%%a
REM echo %SPARK_DIST_CLASSPATH%

for %%a in (hadoop-2.7.1) do @set HADOOP_HOME=%%~dfpa
echo HADOOP_HOME: %HADOOP_HOME%

spark-1.4.1\bin\spark-shell -usejavacp -classpath .\userclasses %*

set HADOOP_HOME=%OLD_HADOOP_HOME%
set OLD_HADOOP_HOME=

