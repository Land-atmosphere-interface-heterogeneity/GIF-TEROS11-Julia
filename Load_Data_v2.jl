# Load Packages
using CSV, DataFrames, Dates, Statistics

# Functions
# Load data from TEROS input files
function loadteros(path::AbstractString)
	Input_FN = readdir(path)
	permute!(Input_FN,[3,4,5,6,7,8,9,10,11,1,2]) # need to reorder from 1 to 11
	n = length(Input_FN) # this is the number of input files, useful later
	data = DataFrame[]
	[push!(data, CSV.read(joinpath(path, Input_FN[i]), dateformat="yyyy-mm-dd HH:MM:SS+00:00")) for i in 1:n]
	return data
end;
# Download and load met data
function loadmet(path::AbstractString)
	download("http://www.atmos.anl.gov/ANLMET/anltower.not_qc", joinpath(path,"met.data"))  
	col_name = [:JDA,:T_LST,:TaC_60m,:spd_60m,:spdV60m,:dirV60m,:sdir60m,:e__10m,:rh_10m,:Tdp_10m,:TaC_10m,:spd_10m,:spdV10m,:dirV10m,:sdir10m,:baroKPa,:radW_m2,:netW_m2,:Ta_diff,:asp_60m,:asp_10m,:battVDC,:precpmm,:T_LST2,:JDA2]
	metdata = CSV.read(joinpath(path,"met.data"), delim = ' ', header = col_name, ignorerepeated = true, datarow = 3, footerskip = 1)
	return metdata
end;
# Load metadata (position of TEROS sensors)
function loadmeta(path::AbstractString)
	MD = CSV.read(path)
	x = MD.x*12.5
	y = MD.y*12.5
	x = x[1:end .!= 35]; x = x[1:end .!= 35]
	y = y[1:end .!= 35]; y = y[1:end .!= 35]
	x = convert(Array{Float64,1}, x)
	y = convert(Array{Float64,1}, y)
	return x, y
end;
# Rearrange SWC and Tsoil
function loadSWC(data::Array{DataFrame,1}, Dtime::Array{DateTime,1})
	m = length(Dtime); n = 11 # 11 files, for 11 ZL6 datalogger
	nextit = 0:5:5*n-1
	SWC = Array{Union{Float64,Missing}}(missing, m, 66)
	for j = 1:11 # For all files
	    for i = 1:m
		k = nextit[j]
		t = findfirst(x -> x == Dtime[i], data[j].datetime)
		if isnothing(t) == false
		    SWC[i,j+k] = data[j].value[t]
		    SWC[i,j+1+k] = data[j].value[t+2]
		    SWC[i,j+2+k] = data[j].value[t+4]
		    SWC[i,j+3+k] = data[j].value[t+6]
		    SWC[i,j+4+k] = data[j].value[t+8]
		    SWC[i,j+5+k] = data[j].value[t+10]
		end
	    end
	end
	SWC = replace(SWC, 0.0=>missing)
	SWC = SWC[:, 1:size(SWC, 2) .!= 35]; SWC = SWC[:, 1:size(SWC, 2) .!= 35] # Need to find how to delete 35 and 36 simultaneously
	return SWC
end;
function loadTsoil(data::Array{DataFrame,1}, Dtime::Array{DateTime,1})
        m = length(Dtime); n = 11
	Tsoil = Array{Union{Float64,Missing}}(missing, m, 66)
        nextit = 0:5:5*n-1
	for j = 1:11 # For all files
	    for i = 1:m
		k = nextit[j]
		t = findfirst(x -> x == Dtime[i], data[j].datetime)
		if isnothing(t) == false
		    Tsoil[i,j+k] = data[j].value[t+1]
		    Tsoil[i,j+1+k] = data[j].value[t+3]
		    Tsoil[i,j+2+k] = data[j].value[t+5]
		    Tsoil[i,j+3+k] = data[j].value[t+7]
		    Tsoil[i,j+4+k] = data[j].value[t+9]
		    Tsoil[i,j+5+k] = data[j].value[t+11]
		end
	    end
	end
	Tsoil = replace(Tsoil, 0.0=>missing)
	Tsoil = Tsoil[:, 1:size(Tsoil, 2) .!= 35]; Tsoil = Tsoil[:, 1:size(Tsoil, 2) .!= 35] # Need to find how to delete 35 and 36 simultaneously
	return Tsoil
end;
function Precips(metdata::DataFrame)
	metdata = metdata[21819:end, :];
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
	Dtime_met_d = Array{Date}(undef, n_pd);
	[Precip_d[i] = sum(skipmissing(Precip_c[1 + (i-1)*96 : (i-1)*96 + 96])) for i = 1:n_pd];
	[Dtime_met_d[i] = Date(Dtime_met_c[1 + (i-1)*96]) for i = 1:n_pd];
	return Dtime_met_c, Precip_c, Precip_d, Dtime_met_d  
end;
function dailyval(X::Array{Union{Missing, Float64},2}, Dtime_all::Array{Date,1})
	n_all = length(Dtime_all)
	X_daily = [X[15+(i-1)*48, :] for i in 1:n_all]
	X_daily = reduce(vcat, adjoint.(X_daily))		   
	X_daily_mean = [mean(skipmissing(X_daily[i,:])) for i = 1:n_all]
	X_daily_std = [std(skipmissing(X_daily[i,:])) for i = 1:n_all]	   
	return X_daily, X_daily_mean, X_daily_std
end;
function Precipdaily(Precip_d::Array{Float64,1}, Dtime_all::Array{Date,1}, Dtime_met_d::Array{Date,1})
	n_all = length(Dtime_all)
	Precip_daily = Array{Float64}(undef, n_all)
	for i = 1:n_all-1 # up to day before today, in case it's before noon
		t = findfirst(x -> x == Dtime_all[i], Dtime_met_d)
	    if isnothing(t) == false
		Precip_daily[i] = Precip_d[t]
	    end
	end
        Precip_daily[Precip_daily.>=50] .= 0 # Delete Precip outliers, daily rain > 50 mm which may be calibration day... this should be fixed by Evan in the qc data!!
	return Precip_daily
end;
# Example of grabbing data in MakieLayout_data_2D.jl
