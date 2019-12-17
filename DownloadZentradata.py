from zentra.api import *
from os import getenv

token = ZentraToken(username=getenv("zentra_un"),password=getenv("zentra_pw"))

token.token

# Get the readings for a device
readings = ZentraReadings(sn="z6-04628",token=token,start_time=int(datetime.datetime(year=2019,month=11,day=27).timestamp()))

# Report the readings from the first ZentraTimeseriesRecord
readings.timeseries[0].values
