from zentra.api import *
from os import getenv

token = ZentraToken(username=getenv("zentra_un"),
                    password=getenv("zentra_pw"))

# Get the settings for a device
settings = ZentraSettings(sn="06-00187",
                          token=token)
# Report the measurement settings
settings.measurement_settings

# Get the status messages for a device
status = ZentraStatus(sn="06-00187",
                      token=token)
# Report the cellular statuses
status.cellular_statuses

# Get the readings for a device
readings = ZentraReadings(sn="06-00761",
                          token=token,
                          start_time=int(datetime.datetime(year=2019,
                                                           month=7,
                                                           day=4).timestamp()))
# Report the readings from the first ZentraTimeseriesRecord
readings.timeseries[0].values
