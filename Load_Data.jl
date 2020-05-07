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
        [download("http://www.atmos.anl.gov/ANLMET/numeric/2019/"*i*"19met.data", joinpath(path, i*"19met.data")) for i in ["nov", "dec"]];
        [download("http://www.atmos.anl.gov/ANLMET/numeric/2020/"*i*"20met.data", joinpath(path, i*"20met.data")) for i in ["jan", "feb","mar"]];
	col_name = [:DOM,:Month,:Year,:Time,:PSC,:WD60,:WS60,:WD_STD60,:T60,:WD10,:WS10,:WD_STD10,:T10,:DPT,:RH,:TD100,:Precip,:RS,:RN,:Pressure,:WatVapPress,:TS10,:TS100,:TS10F]
	metdata = DataFrame[]
	[push!(metdata, CSV.read(joinpath(path, i*"19met.data"), delim=' ', header=col_name, ignorerepeated=true, datarow=1, footerskip=2)) for i in ["nov", "dec"]]
	[push!(metdata, CSV.read(joinpath(path, i*"20met.data"), delim=' ', header=col_name, ignorerepeated=true, datarow=1, footerskip=2)) for i in ["jan", "feb","mar"]]
	metdata = reduce(vcat, metdata)
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
# Create a DateTime vector from metdata Month, Year and Time
# First, need 4-digits Array for Time
function loadDtimemet(metdata::DataFrame)
	met_n = size(metdata, 1) 
	metdata_time_str = Array{String}(undef, met_n)
	for i = 1:met_n
	    if length(string(metdata.Time[i])) == 2 # if only 2 numbers
		metdata_time_str[i] = "00$(metdata.Time[i])"
	    elseif length(string(metdata.Time[i])) == 3 # if only 3 numbers
		metdata_time_str[i] = "0$(metdata.Time[i])"
	    elseif length(string(metdata.Time[i])) == 4 # 4 numbers
		metdata_time_str[i] = string(metdata.Time[i])
	    end
	end
	# Then, we can use day of month, month, year and time
	Dtime_met = Array{DateTime}(undef, met_n)
	for i = 1:met_n
	    Dtime_met[i] = DateTime(metdata.Year[i]+2000,metdata.Month[i],metdata.DOM[i],parse(Int64,metdata_time_str[i][1:2]),parse(Int64,metdata_time_str[i][3:4]))
	end
	return Dtime_met
end;
# Integrate daily Precip
# I need to redo this... this is not clean. Maybe fixing latest rain on ANLMET website should be done first. 
function PrecipD(metdata::DataFrame, Dtime_met::Array{DateTime,1})
	Precip_d = Array{Float64}(undef, 152)
	Dtime_met_d = Array{DateTime}(undef, 152)
	for i = 1:30
	    use = findall(x -> Dates.year(x) == 2019 && Dates.day(x) == i && Dates.month(x) == 11, Dtime_met)
	    Precip_d[i] = sum(metdata.Precip[use])
	    Dtime_met_d[i] = Date(DateTime(2019,11,i))
	end
	for i = 1:31
	    use = findall(x -> Dates.year(x) == 2019 && Dates.day(x) == i && Dates.month(x) == 12, Dtime_met)
	    Precip_d[30 + i] = sum(metdata.Precip[use])
	    Dtime_met_d[30 + i] = Date(DateTime(2019,12, i))
	end
	for i = 1:31
	    use = findall(x -> Dates.year(x) == 2020 && Dates.day(x) == i && Dates.month(x) == 1, Dtime_met)
	    Precip_d[61 + i] = sum(metdata.Precip[use])
	    Dtime_met_d[61 + i] = Date(DateTime(2020, 1, i))
	end
	for i = 1:29
	    use = findall(x -> Dates.year(x) == 2020 && Dates.day(x) == i && Dates.month(x) == 2, Dtime_met)
	    Precip_d[92 + i] = sum(metdata.Precip[use])
	    Dtime_met_d[92 + i] = Date(DateTime(2020, 2, i)) 	
	end
	for i = 1:31
	    use = findall(x -> Dates.year(x) == 2020 && Dates.day(x) == i && Dates.month(x) == 3, Dtime_met)
	    Precip_d[121 + i] = sum(metdata.Precip[use])
	    Dtime_met_d[121 + i] = Date(DateTime(2020, 3, i)) 	
	end
	return Precip_d, Dtime_met_d
end;
function dailyval(X::Array{Union{Missing, Float64},2}, Dtime_all::Array{Date,1})
	n_all = length(Dtime_all)
	X_daily = [X[15+(i-1)*48, :] for i in 1:n_all]
	X_daily = reduce(vcat, adjoint.(X_daily))		   
	X_daily_mean = [mean(skipmissing(X_daily[i,:])) for i = 1:n_all]
	X_daily_std = [std(skipmissing(X_daily[i,:])) for i = 1:n_all]	   
	return X_daily, X_daily_mean, X_daily_std
end;
function Precipdaily(Precip_d::Array{Float64,1}, Dtime_all::Array{Date,1}, Dtime_met_d::Array{DateTime,1})
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
