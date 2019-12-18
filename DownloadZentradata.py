from zentra.api import *
from os import getenv

token = ZentraToken(username=getenv("zentra_un"),password=getenv("zentra_pw"))

Device_SN = ["z6-04628","z6-04625","z6-04619","z6-04629","z6-04641","z6-04638","z6-04624","z6-04627","z6-04620","z6-04621","z6-04618"]

for i in Device_SN
    readings = ZentraReadings(sn=i,token=token,start_time=int(datetime.datetime(year=2019,month=11,day=27).timestamp()))
    data = readings.timeseries[0].values
    import pandas as pd
    data.to_csv(path_or_buf=i+".csv")
