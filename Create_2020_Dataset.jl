using DataFrames, CSV, Dates

include("Load_Data.jl");
function loaddata()
	data = loadteros(joinpath("Input","TEROS", ""))
	metdata = loadmet(joinpath("Input","MET TOWER", ""))
	Dtime = collect(Dates.DateTime(DateTime(2019, 11, 23, 00, 00, 00)):Dates.Minute(30):now())
	SWC = loadSWC(data, Dtime)
	Tsoil = loadTsoil(data, Dtime)
	Dtime_met = loadDtimemet(metdata)
	Precip_d, Dtime_met_d = PrecipD(metdata, Dtime_met)
	Dtime_all = collect(Date(2019, 11, 23):Day(1):today()) # Need same datetime (daily) for SWC data and met data
	Tsoil_daily, Tsoil_daily_mean, Tsoil_daily_std = dailyval(Tsoil, Dtime_all)
	SWC_daily, SWC_daily_mean, SWC_daily_std = dailyval(SWC, Dtime_all)
	Precip_daily = Precipdaily(Precip_d, Dtime_all, Dtime_met_d)
	dataRSM, RSMmean, RSMstd = loadmanuals(joinpath("Input","SFP output","Manual"))
	dataRSA, RSAmean, RSAstd, Date_Auto = loadauto(joinpath("Input","SFP output","Auto"))	

	return (
		data = data, metdata = metdata, Dtime = Dtime, SWC = SWC, Tsoil = Tsoil,
		Dtime_met = Dtime_met, Precip_d = Precip_d, Dtime_met_d = Dtime_met_d, Dtime_all = Dtime_all,
		Tsoil_daily = Tsoil_daily, Tsoil_daily_mean = Tsoil_daily_mean, Tsoil_daily_std = Tsoil_daily_std,
		SWC_daily = SWC_daily, SWC_daily_mean = SWC_daily_mean, SWC_daily_std = SWC_daily_std,
		Precip_daily = Precip_daily, 
		dataRSM = dataRSM, RSMmean = RSMmean, RSMstd = RSMstd,
		dataRSA = dataRSA, RSAmean = RSAmean, RSAstd = RSAstd, Date_Auto = Date_Auto #Dtime_rata = Dtime_rata
		)
end;
Data = loaddata();

x = [0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,6,7,7,7,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,6,7,7,7] 
y = [0,1,2,2,1,0,0,1,2,2,1,0,0,1,2,2,1,0,0,1,2,2,1,0,3,4,4,3,4,3,3,4,4,3,3,4,4,3,4,3,5,6,7,7,6,5,5,6,7,7,6,5,5,6,7,7,6,5,5,6,7,7,6,5] 

# naming SWC columns by x y locations
SWC_names = []
Tsoil_names = []
[push!(SWC_names, string("SWC_", string(x[i]), string(y[i]))) for i = 1:64]
[push!(Tsoil_names, string("Tsoil_", string(x[i]), string(y[i]))) for i = 1:64]

# Put data in DataFrame
df_SWC = DataFrame(Data.SWC, :auto)
df_Tsoil = DataFrame(Data.Tsoil, :auto)
rename!(df_SWC, Symbol.(SWC_names))
rename!(df_Tsoil, Symbol.(Tsoil_names))
insertcols!(df_SWC, 1, :datetime => Data.Dtime)
insertcols!(df_Tsoil, 1, :datetime => Data.Dtime)

# DateTime for 2020
datetime = collect(DateTime(2020, 01, 01, 00, 30, 00): Minute(30): DateTime(2021, 01, 01, 00, 00, 00)); 
df_datetime = DataFrame(datetime = datetime)

# Merge corresponding data to datetime 
df = leftjoin(df_datetime, df_SWC, on = :datetime)
df = leftjoin(df, df_Tsoil, on = :datetime)

# Add met data (all of them)
# Note met data are hourly, so every other column is missing
df_met = Data.metdata
insertcols!(df_met, 1, :datetime => Data.Dtime_met)

df = leftjoin(df, df_met, on = :datetime)
sort!(df, :datetime)

# Add Automated Rsoil 
# create one dataframe per port#
df_RSA1 = filter(:"Port#" => x -> x == 1, Data.dataRSA)
df_RSA2 = filter(:"Port#" => x -> x == 2, Data.dataRSA)
df_RSA3 = filter(:"Port#" => x -> x == 3, Data.dataRSA)
df_RSA4 = filter(:"Port#" => x -> x == 4, Data.dataRSA)

dt_RSA1 = floor.(df_RSA1.Date_IV, Dates.Minute(30))
dt_RSA2 = floor.(df_RSA2.Date_IV, Dates.Minute(30))
dt_RSA3 = floor.(df_RSA3.Date_IV, Dates.Minute(30))
dt_RSA4 = floor.(df_RSA4.Date_IV, Dates.Minute(30))

rename!(df_RSA1, string.("RSA_", names(df_RSA1), "_1"))
rename!(df_RSA2, string.("RSA_", names(df_RSA2), "_2"))
rename!(df_RSA3, string.("RSA_", names(df_RSA3), "_3"))
rename!(df_RSA4, string.("RSA_", names(df_RSA4), "_4"))

insertcols!(df_RSA1, 1, :datetime => dt_RSA1)
insertcols!(df_RSA2, 1, :datetime => dt_RSA2)
insertcols!(df_RSA3, 1, :datetime => dt_RSA3)
insertcols!(df_RSA4, 1, :datetime => dt_RSA4)

# delete duplicate times
unique!(df_RSA1, :datetime)
unique!(df_RSA2, :datetime)
unique!(df_RSA3, :datetime)
unique!(df_RSA4, :datetime)

# now leftjoin
df = leftjoin(df, df_RSA1, on = :datetime)
df = leftjoin(df, df_RSA2, on = :datetime)
df = leftjoin(df, df_RSA3, on = :datetime)
df = leftjoin(df, df_RSA4, on = :datetime)
sort!(df, :datetime)

# last but not least, add manual Rsoil data (lots of missing half-hours!) 
[rename!(Data.dataRSM[i], string.("RSM_", names(Data.dataRSM[i]))) for i = 1:13]

dt_RSM = Dict(1:13 .=> [[] for i = 1:13])
[push!(dt_RSM[i], floor.(Data.dataRSM[i].RSM_Date_IV, Dates.Minute(30))) for i = 1:13]

df_RSM = Dict(1:13 .=> [[] for i = 1:13])
[push!(df_RSM[i], insertcols!(Data.dataRSM[i], 1, :datetime => dt_RSM[i][1])) for i = 1:13]

coord = DataFrame(CSV.File(joinpath("Input", "surveyorder.txt")))

RSM_Coords = [] 

[push!(RSM_Coords, Symbol.(string("RSM_", string(coord.x[i]), string(coord.y[i])))) for i = 1:64]

RSM_df = Dict(RSM_Coords .=> [[] for i = 1:64])

[push!(RSM_df[RSM_Coords[j]], Data.dataRSM[i][j, 1:5]) for j = 1:64, i = 1:13]  

# need to convert from DataFrameRow to DataFrame
RSM_vec = [DataFrame(RSM_df[i]) for i in RSM_Coords]
RSM_df = Dict(RSM_Coords .=> [[] for i = 1:64])
[push!(RSM_df[RSM_Coords[j]], RSM_vec[j]) for j in 1:64]

# now, need to append _coord to each column name except datetime
i = 1
for D in RSM_Coords
	rename!(RSM_df[D][1], string.(names(RSM_df[D][1]), "_", string(coord.x[i]), string(coord.y[i])))
	i += 1
	rename!(RSM_df[D][1], names(RSM_df[D][1])[1] => :datetime)
end

# leftjoin for each of the 64 RSM_df
for D in RSM_Coords
	df = leftjoin(df, RSM_df[D][1], on = :datetime) 
end
sort!(df, :datetime)


CSV.write(joinpath("Output","2020_v1.csv"), df)



