# Create a 3D gif of SWC moisture in space, over time

# Define current working directory
cd("C:\\Users\\arenchon\\Documents\\GitHub\\GIF-TEROS11-Julia")

# Used Packages
using DataFrames; using CSV; using Dates; using Plots;

# First part of this code is similar to Plot_input.jl
Input_FN = readdir("Input\\TEROS\\")
permute!(Input_FN,[3,4,5,6,7,8,9,10,11,1,2]) # need to reorder from 1 to 11
n = length(Input_FN) # this is the number of input files, useful later
data = DataFrame[]

for i = 1:n
    df = CSV.read(string("Input\\TEROS\\",Input_FN[i]),dateformat="yyyy-mm-dd HH:MM:SS+00:00")
    push!(data, df) # push "Insert one or more items at the end of collection"
end

# Create a continuous half-hourly DateTime vector
Dtime = collect(Dates.DateTime(DateTime(2019,11,23,00,00,00)):Dates.Minute(30):now())
m = length(Dtime)
# Initialize SWC matrice with 66 columns, m rows
SWC = Array{Union{Float64,Missing}}(missing,m,66)
nextit = collect(0:5:5*n-1)
for j = 1:11
    for i = 1:m
        k = nextit[j]
        t = findfirst(x -> x == Dtime[i],data[j].datetime)
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
MD = CSV.read("Input\\Metadata.csv")
x = MD.x*12.5
y = MD.y*12.5
# Replace missing by NaN, for plotting
x = replace(x, missing=>NaN)
y = replace(y, missing=>NaN)
SWC = replace(SWC, missing=>NaN)
SWC = replace(SWC, 0.0=>NaN)
# could find something more elegant to do the loop below...
for j = 1:66
    for i = 1:m
        if SWC[i,j] < 0.35 || SWC[i,j] > 0.5
            SWC[i,j] = NaN
        end
    end
end

# Download met data
url = "http://www.atmos.anl.gov/ANLMET/numeric/2019/nov19met.data"
met_path = "Input\\MET TOWER\\nov19met.data"
download(url,met_path)

# Read met data
col_name = [:DOM,:Month,:Year,:Time,:PSC,:WD60,:WS60,:WD_STD60,:T60,:WD10,:WS10,:WD_STD10,:T10,:DPT,:RH,:TD100,:Precip,:RS,:RN,:Pressure,:WatVapPress,:TS10,:TS100,:TS10F]
metdata = CSV.read(met_path, delim=' ',header=col_name,ignorerepeated=true,datarow=1,footerskip=2)
met_n = size(metdata,1)

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
Precip_d = Array{Float64}(undef,30)
Dtime_met_d = Array{DateTime}(undef,30)
for i = 1:30
    use = findall(x -> Dates.day(x) == i && Dates.month(x) == 11,Dtime_met)
    Precip_d[i] = sum(metdata.Precip[use])
    Dtime_met_d[i] = Date(DateTime(2019,11,i))
end

# TO DO: add a subplot with timeseries of SWC (mean + std) + Precip bar on right axis

# TO DO: Make the script run automatically daily (or weekly).

# Need same datetime (daily) for SWC data and met data
n_all = floor(Int64, length(Dtime)/48)
Dtime_all = Array{DateTime}(undef,n_all)
SWC_daily_mean = Array{Float64}(undef,n_all)
SWC_daily = Array{Union{Float64,Missing}}(missing,n_all,66)
Precip_daily = Array{Float64}(undef,n_all)
Dtime_all = collect(Date(2019, 11, 23):Day(1):today())
for i = collect(1:n_all)
    SWC_daily[i,:] = SWC[25+(i-1)*48,:]
    t = findfirst(x -> x == Dtime_all[i],Dtime_met_d)
    if isnothing(t) == false
        Precip_daily[i] = Precip_d[t]
    end
end

anim = @animate for i = collect(1:1:n_all)
    z = SWC_daily[i,:]
    use = findall(!isnan,z) # all non NaN values in z
    p1 = scatter(x[use],y[use],color=:redsblues,markersize=10,zcolor=z[use],
    xlabel="x (m)",ylabel="y (m)",title=Dates.format(Dtime_all[i], "e, dd u yyyy"),
    xticks = 0:12.5:87.5,yticks = 0:12.5:87.5,colorbar_title = "Soil Moisture",
    clim=(0.35,0.48),size=(500,500));
    p2 = bar(Dtime_all[1:i],Precip_daily[1:i],
    xlims=(Dates.value(Dtime_all[1]),Dates.value(Dtime_all[n_all])),
    ylims=(0,maximum(Precip_daily)),ylabel="Precip (mm)");
    l = @layout [a{0.8h}; b]
    plot(p1, p2, layout=l,size=(500,700))
    #plot!(legend = nothing)
end
gif(anim,"Output\\anim_5days_v3.gif",fps=5)

