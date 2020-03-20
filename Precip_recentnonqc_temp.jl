using CSV, Dates, DataFrames
# Grab Precip data from 
#function loadmet(path::AbstractString)
	download("http://www.atmos.anl.gov/ANLMET/anltower.not_qc","Input\\met.data") # joinpath("Input\\MET TOWER\\", "met.data")) 
	col_name = [:JDA,:T_LST,:TaC_60m,:spd_60m,:spdV60m,:dirV60m,:sdir60m,:e__10m,:rh_10m,:Tdp_10m,:TaC_10m,:spd_10m,:spdV10m,:dirV10m,:sdir10m,:baroKPa,:radW_m2,:netW_m2,:Ta_diff,:asp_60m,:asp_10m,:battVDC,:precpmm,:T_LST2,:JDA2]
	#metdata = CSV.read(joinpath(path, i*"19met.data"), delim=' ', header=col_name, ignorerepeated=true, datarow=1, footerskip=2)
	metdata = CSV.read("Input\\met.data", delim = ' ', header = col_name, ignorerepeated = true, datarow = 3, footerskip = 1)
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

nmet = size(metdata)[1];
Dtime_met = Array{DateTime}(undef, nmet);
first2020 = findfirst(x -> x == 1, metdata.JDA);
Dtime_met[1:first2020 - 1] = [DateTime(firstdayofyear(Date(2019)) + Day(metdata.JDA[i] - 1), metdata.T_LST[i]) for i = 1:first2020 - 1]; 
Dtime_met[first2020:nmet] = [DateTime(firstdayofyear(Date(2020)) + Day(metdata.JDA[i] - 1), metdata.T_LST[i]) for i = first2020:nmet];

Dtime_met_c = collect(Dates.DateTime(DateTime(2019, 11, 23, 00, 00, 00)):Dates.Minute(15):Dtime_met[nmet]);

m = length(Dtime_met_c);
Precip_c = Array{Union{Float64,Missing}}(missing, m)
for i = 1:m
	t = findfirst(x -> x == Dtime_met_c[i], Dtime_met)
	if isnothing(t) == false
	    Precip_c[i] = metdata.precpmm[t]
	end
end

n_pd = convert(Int64,trunc(size(Dtime_met_c)[1]/96));
Precip_d = Array{Float64}(undef, n_pd);
Date_d = Array{Date}(undef, n_pd);
[Precip_d[i] = sum(skipmissing(Precip_c[1 + (i-1)*96 : (i-1)*96 + 96])) for i = 1:n_pd];
[Date_d[i] = Date(Dtime_met_c[1 + (i-1)*96]) for i = 1:n_pd];



# Then, implement that in Load_Data.jl to replace the previous metdata


n_pd = convert(Int64,trunc(size(Dtime_met_c)[1]/96));
	Precip_d = Array{Float64}(undef, n_pd);
	Dtime_met_d = Array{DateTime}(undef, n_pd);
	[Precip_d[i] = sum(skipmissing(Precip_c[1 + (i-1)*96 : (i-1)*96 + 96])) for i = 1:n_pd];
	[Dtime_met_d[i] = Date(Dtime_met_c[1 + (i-1)*96]) for i = 1:n_pd];




























