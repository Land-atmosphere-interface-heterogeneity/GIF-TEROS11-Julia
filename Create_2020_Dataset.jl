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
df = sort(df, :datetime)

# Add Automated Rsoil 


