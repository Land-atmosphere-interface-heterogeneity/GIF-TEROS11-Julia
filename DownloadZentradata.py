from zentra.api import *; import os; import pandas as pd; import time
os.chdir('Input\\TEROS')
token = ZentraToken(username=os.getenv("zentra_un"),password=os.getenv("zentra_pw"))
Device_SN = ["z6-04628","z6-04625","z6-04619","z6-04629","z6-04641","z6-04638","z6-04624","z6-04627","z6-04620","z6-04621","z6-04618"]
i = 0
while i <= 10:
    try:
        readings = ZentraReadings(sn=Device_SN[i],token=token,start_time=int(datetime.datetime(year=2019,month=11,day=23).timestamp()))
        data = readings.timeseries[0].values
        data.to_csv(path_or_buf=str(i+1)+"_"+Device_SN[i]+".csv")
        i += 1
    except:
        time.sleep(30) # The loop will crash if we don't wait a bit. METER configuration. 
        pass
