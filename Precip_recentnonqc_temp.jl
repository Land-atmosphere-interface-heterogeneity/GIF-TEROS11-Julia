# Grab Precip data from 
#function loadmet(path::AbstractString)
	download("http://www.atmos.anl.gov/ANLMET/anltower.not_qc","met.data") # joinpath("Input\\MET TOWER\\", "met.data")) 
	col_name = [:JDA,:T_LST,:TaC_60m,:spd_60m,:spdV60m,:dirV60m,:sdir60m,:e__10m,:rh_10m,:Tdp_10m,:TaC_10m,:spd_10m,:spdV10m,:dirV10m,:sdir10m,:baroKPa,:radW_m2,:netW_m2,:Ta_diff,:asp_60m,:asp_10m,:battVDC,:precpmm,:T_LST2,:JDA2]
	#metdata = CSV.read(joinpath(path, i*"19met.data"), delim=' ', header=col_name, ignorerepeated=true, datarow=1, footerskip=2)
	metdata = CSV.read("met.data", delim = ' ', header = col_name, ignorerepeated = true, datarow = 3, footerskip = 1)
	return metdata
#end;

# julia> Data.Dtime[1]
# 2019-11-23T00:00:00
#
# julia> Dates.dayofyear(Data.Dtime[1])
# 327
#
# julia> findfirst(x -> x == 327, metdata.JDA)
# 21819

metdata = metdata[21819:end, :];
using Dates
Dtime_met = collect(Dates.DateTime(DateTime(2019, 11, 23, 00, 00, 00)):Dates.Minute(15):now());

nmet = size(metdata)[1];
Dtime_met = Array{DateTime}(undef, nmet);
first2020 = findfirst(x -> x == 1, metdata.JDA);
Dtime_met[1:first2020 - 1] = [DateTime(firstdayofyear(Date(2019)) + Day(metdata.JDA[i] - 1), metdata.T_LST[i]) for i = 1:first2020 - 1]; 
Dtime_met[first2020:nmet] = [DateTime(firstdayofyear(Date(2020)) + Day(metdata.JDA[i] - 1), metdata.T_LST[i]) for i = first2020:nmet];

Dtime_met_c = collect(Dates.DateTime(DateTime(2019, 11, 23, 00, 00, 00)):Dates.Minute(15):Dtime_met[nmet]);

# TO DO: merge metdata to the continuous timestamp Dtime_met_c ... 

# Then, implement that in Load_Data.jl to replace the previous metdata






























