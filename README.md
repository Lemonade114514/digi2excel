# digi2excel
digi2excel matlab app for ose digital mic project report making. (actually for trying git)

# version
|version|description|
|--|--|
|v1.2|orginal ver. from local|
|v1.2.1(ver.260311)|1. make digitalMicDataTool.m to function script; 2. add more logging|
|v1.2.2(ver260311)|1. add clearLog button; 2. add CM button; 3. add CM info to csv; 4. add more logging|
|v1.2.3(ver260316)|1. refine the UI page; 2. add inapp guide; 3. debug cleanup logText; 4. debug tone item abnormal data|
|v1.2.4(ver260316)|1. add time record on file; 2. add full name match on items(except sens&tone); 3. Optimize the code structure|

# How to use this app
1. "Headers.csv" for all the items (change freely)
2. "rawData.csv" for the rawData need to clean (should be osens digitalMic data)
3. Headers.csv and rawData.csv files should be in same folder
4. launch "digi2excel.app" with "matlab r2022a runtime engine" to make data.csv
