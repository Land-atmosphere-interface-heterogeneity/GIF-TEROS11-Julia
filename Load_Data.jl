# Load Packages
using CSV, DataFrames, Dates, Statistics

# Set working directory
cd("C:\\Users\\arenchon\\Documents\\GitHub\\GIF-TEROS11-Julia")

# Load data from TEROS input files
Input_FN = readdir("Input\\TEROS\\")
permute!(Input_FN,[3,4,5,6,7,8,9,10,11,1,2]) # need to reorder from 1 to 11
n = length(Input_FN) # this is the number of input files, useful later
data = DataFrame[]
[push!(data, CSV.read("Input\\TEROS\\"*Input_FN[i], dateformat="yyyy-mm-dd HH:MM:SS+00:00")) for i in 1:n]

# Download met data
[download("http://www.atmos.anl.gov/ANLMET/numeric/2019/"*i*"19met.data", "Input\\MET TOWER\\"*i*"19met.data") for i in ["nov", "dec"]]

# Load that met data
col_name = [:DOM,:Month,:Year,:Time,:PSC,:WD60,:WS60,:WD_STD60,:T60,:WD10,:WS10,:WD_STD10,:T10,:DPT,:RH,:TD100,:Precip,:RS,:RN,:Pressure,:WatVapPress,:TS10,:TS100,:TS10F]
metdata = DataFrame[]
[push!(metdata, CSV.read("Input\\MET TOWER\\"*i*"19met.data", delim=' ', header=col_name, ignorerepeated=true, datarow=1, footerskip=2)) for i in ["nov", "dec"]]
metdata = vcat(metdata...)
met_n = size(metdata,1)

# Rearrange those data in 1 dataframe
Dtime = collect(Dates.DateTime(DateTime(2019, 11, 23, 00, 00, 00)):Dates.Minute(30):now())
m = length(Dtime)
SWC = Array{Union{Float64,Missing}}(missing, m, 66)
nextit = collect(0:5:5*n-1)
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

Tsoil = Array{Union{Float64,Missing}}(missing, m, 66)
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

# Load metadata (position of TEROS sensors)
MD = CSV.read("Input\\Metadata.csv")
x = MD.x*12.5
y = MD.y*12.5

# Create a DateTime vector from metdata Month, Year and Time
# First, need 4-digits Array for Time
metdata_time_str = Array{String}(undef,met_n)
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
Dtime_met = Array{DateTime}(undef,met_n)
for i = 1:met_n
    Dtime_met[i] = DateTime(metdata.Year[i]+2000,metdata.Month[i],metdata.DOM[i],parse(Int64,metdata_time_str[i][1:2]),parse(Int64,metdata_time_str[i][3:4]))
end

# Integrate daily Precip
# I need to redo this... this is not clean. Maybe fixing latest rain on ANLMET website should be done first. 
Precip_d = Array{Float64}(undef,61)
Dtime_met_d = Array{DateTime}(undef,61)
for i = 1:30
    use = findall(x -> Dates.day(x) == i && Dates.month(x) == 11,Dtime_met)
    Precip_d[i] = sum(metdata.Precip[use])
    Dtime_met_d[i] = Date(DateTime(2019,11,i))
end
for i = 1:31
    use = findall(x -> Dates.day(x) == i && Dates.month(x) == 12,Dtime_met)
    Precip_d[30 + i] = sum(metdata.Precip[use])
    Dtime_met_d[30 + i] = Date(DateTime(2019,12,i))
end

# Need same datetime (daily) for SWC data and met data
Dtime_all = collect(Date(2019, 11, 23):Day(1):today())
n_all = length(Dtime_all)
SWC_daily_mean = Tsoil_daily_mean = SWC_daily_std = Tsoil_daily_std = Array{Float64}(undef, n_all)
SWC_daily = Tsoil_daily = Array{Union{Float64,Missing}}(missing, n_all,66)
Precip_daily = Array{Float64}(undef, n_all)
for i = collect(1:n_all-1) # up to day before today, in case it's before noon
    SWC_daily[i,:], Tsoil_daily[i, :] = SWC[25+(i-1)*48,:], Tsoil[25+(i-1)*48, :]
    SWC_daily_mean[i], Tsoil_daily_mean[i] = mean(skipmissing(SWC_daily[i, :])), mean(skipmissing(Tsoil_daily[i, :]))
    SWC_daily_std[i], Tsoil_daily_std[i] = std(skipmissing(SWC_daily[i, :])), std(skipmissing(Tsoil_daily[i, :]))
    t = findfirst(x -> x == Dtime_all[i], Dtime_met_d)
    if isnothing(t) == false
        Precip_daily[i] = Precip_d[t]
    end
end

# Delete Precip outliers, daily rain > 50 mm which may be calibration day... this should be fixed by Evan in the qc data!!
Precip_daily[Precip_daily.>=50] .= 0

