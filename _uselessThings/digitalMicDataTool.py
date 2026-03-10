import os
import csv
import sys
import pandas as pd

# ----------read---------- #
folder_path = os.path.dirname(os.path.realpath(__file__))
files = os.listdir(folder_path)
flag = False
for file in files:
    if file.endswith("rawData.csv"):
        flag = True
        print(file)
        rawData = pd.read_csv(folder_path + "/" + file)
    if file.endswith("Headers.csv"):
        headers = pd.read_csv(folder_path + "/" + file)
if not flag:
    sys.exit("脚本已停止")

# ----------locate---------- #
head = headers["Headers"]
for i in range(head.shape[0]):
    newSeries = pd.DataFrame({'0': []})
    for column, series in rawData.items():
        if head[i] in series[0]:
            tempSeries = series[6: series.shape[0]].reset_index(drop=True)
            if newSeries.shape[0] == 0:
                # newSeries["0"] = tempSeries
            else:
                # newSeries.join(tempSeries)
                # newSeries = allSeries




