@echo off
Echo Starting hadoop...

set OLD_HADOOP_HOME=%HADOOP_HOME%
set OLD_HADOOP_CLASSPATH=%HADOOP_CLASSPATH%

for %%a in (hadoop-2.7.1) do @set HADOOP_HOME=%%~dfpa
for %%a in (.\hadoop-2.7.1\share\hadoop\tools\lib) do @set HADOOP_CLASSPATH=%%~dfpa
for %%a in (.\userclasses) do @set HADOOP_CLASSPATH=%HADOOP_CLASSPATH%\*;%%~dfpa\*

echo HADOOP_HOME: %HADOOP_HOME%
echo HADOOP_CLASSPATH: %HADOOP_CLASSPATH%

set HADOOP_LOGLEVEL=WARN

hadoop-2.7.1\bin\hadoop %*

set HADOOP_HOME=%OLD_HADOOP_HOME%
set OLD_HADOOP_HOME=
set HADOOP_CLASSPATH=%OLD_HADOOP_CLASSPATH%
set OLD_HADOOP_CLASSPATH=
