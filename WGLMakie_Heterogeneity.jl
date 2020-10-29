using Dates, SparseArrays, UnicodeFun, Printf, AbstractPlotting, WGLMakie, JSServe
using AbstractPlotting.MakieLayout
using PlotUtils: optimize_ticks
using JSServe.DOM

include("Load_Data.jl");

# Dual-Arrhenius and Michaelis-Menten model, Davidson et al., 2012
# Mechanistic model of heterotrophic soil respiration as a function of soil temperature (Tsoil, Â°C)  and soil moisture (Msoil, m3 m-3)
# For description and dimension of parameters, see DAMM_param.jl
function DAMM(Tsoil::Float64, Msoil::Float64; kMSx::Float64=1e-8, AlphaSx::Float64=1e8, kMO2::Float64=1e-3, EaSx::Float64=62.0, Sxtot::Float64=0.0125)::Float64 
	Sx = Sxtot * psx * Dliq * Msoil^3
	O2 = Dgas * O2airfrac * ((porosity - Msoil)^(4/3))
	MMSx = Sx / (kMSx + Sx)
	MMO2 = O2 / (kMO2 + O2)
	VmaxSx = (AlphaSx * exp(-EaSx/(R * (273.15 + Tsoil))))
	Resp = VmaxSx * MMSx * MMO2 # in mgC g-1 hr-1
	areaCflux = 10000 * Soildepth * Resp # in mgC m-2 hr-1
	Rsoil = areaCflux / 1000 / 12 * 1e6 / 60 / 60 # in umol CO2 m-2 s-1
end
# Fixed parameters, values as in John Drake et al., 2018
R = 8.314472e-3 # Universal gas constant, kJ K-1 mol-1
O2airfrac = 0.209 # volume of O2 in the air, L L-1
BD = 1.5396 # Soil bulk density, g cm-3  
PD = 2.52 # Soil particle density, g cm-3
porosity = 1-BD/PD # total porosity 
psx = 2.4e-2 # Fraction of soil C that is considered soluble
Dliq = 3.17 # Diffusion coeff of substrate in liquid phase, dimensionless
Dgas = 1.67 # Diffusion coefficient of oxygen in air, dimensionless
Soildepth = 10 # effective soil depth, cm

function MakieLayout.legendelements(plot::BarPlot)
    MakieLayout.LegendElement[PolyElement(color = plot.color, strokecolor = plot.strokecolor)]
end

function loaddata()
	# Load raw data, functions below can be found in Load_Data.jl
	data = loadteros("Input/TEROS/")
	metdata = loadmet("Input/MET TOWER/")
	x, y = loadmeta("Input/Metadata.csv")
	Dtime = collect(Dates.DateTime(DateTime(2019, 11, 23, 00, 00, 00)):Dates.Minute(30):now())
	SWC = loadSWC(data, Dtime)
	Tsoil = loadTsoil(data, Dtime)
	Dtime_met = loadDtimemet(metdata)
	Precip_d, Dtime_met_d = PrecipD(metdata, Dtime_met)
	Dtime_all = collect(Date(2019, 11, 23):Day(1):today()) # Need same datetime (daily) for SWC data and met data
	Tsoil_daily, Tsoil_daily_mean, Tsoil_daily_std = dailyval(Tsoil, Dtime_all)
	SWC_daily, SWC_daily_mean, SWC_daily_std = dailyval(SWC, Dtime_all)
	Precip_daily = Precipdaily(Precip_d, Dtime_all, Dtime_met_d)
	dataRSM, RSMmean, RSMstd = loadmanuals("Input/SFP output/Manual")
	dataRSA, RSAmean, RSAstd, Date_Auto = loadauto("Input/SFP output/Auto")

	# Until I figure how to deal with missing data (in Makie.jl)
	SWC_daily = replace(SWC_daily, missing=>0.0); SWC_daily_mean = replace(SWC_daily_mean, missing=>0.0); SWC_daily_std = replace(SWC_daily_std, missing=>0.0)
	Tsoil_daily = replace(Tsoil_daily, missing=>0.0); Tsoil_daily_mean = replace(Tsoil_daily_mean, missing=>0.0); Tsoil_daily_std = replace(Tsoil_daily_std, missing=>0.0)

	# Trick until Makie.jl can work with datetime values
	Dtime_all_rata = datetime2rata.(Dtime_all)
	#Dtime_rata = datetime2rata.(Dtime)
	dateticks = optimize_ticks(Dtime_all[1],Dtime_all[end])[1]
	x = [0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,6,7,7,7,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,6,7,7,7] .+ 1
	y = [0,1,2,2,1,0,0,1,2,2,1,0,0,1,2,2,1,0,0,1,2,2,1,0,3,4,4,3,4,3,3,4,4,3,3,4,4,3,4,3,5,6,7,7,6,5,5,6,7,7,6,5,5,6,7,7,6,5,5,6,7,7,6,5] .+ 1

	return (
		data = data, metdata = metdata, x = x, y = y, Dtime = Dtime, SWC = SWC, Tsoil = Tsoil,
		Dtime_met = Dtime_met, Precip_d = Precip_d, Dtime_met_d = Dtime_met_d, Dtime_all = Dtime_all,
		Tsoil_daily = Tsoil_daily, Tsoil_daily_mean = Tsoil_daily_mean, Tsoil_daily_std = Tsoil_daily_std,
		SWC_daily = SWC_daily, SWC_daily_mean = SWC_daily_mean, SWC_daily_std = SWC_daily_std,
		Precip_daily = Precip_daily, Dtime_all_rata = Dtime_all_rata, dateticks = dateticks,
		dataRSM = dataRSM, RSMmean = RSMmean, RSMstd = RSMstd,
		dataRSA = dataRSA, RSAmean = RSAmean, RSAstd = RSAstd, Date_Auto = Date_Auto #Dtime_rata = Dtime_rata
		)
end;
Data = loaddata();

# Modeled Rsoil
n_all = size(Data.SWC_daily, 1); # Below are random data, for now
PD = 3.1; porosity = 1-BD/PD # Avoid complexe number problem DAMM
Rsoil_daily = [DAMM.(Data.Tsoil_daily[i,:], Data.SWC_daily[i,:], EaSx = 58.00) for i = 1:n_all];
Rsoil_daily = reduce(vcat, adjoint.(Rsoil_daily));
Rsoil_daily_mean = [mean(filter(x -> x > 0, Rsoil_daily[i,:])) for i = 1:n_all];
Rsoil_daily_std = [std(filter(x -> x > 0, Rsoil_daily[i,:])) for i = 1:n_all];

# Half-hourly
SWC  = replace(Data.SWC , missing=>0.0); 
Tsoil  = replace(Data.Tsoil , missing=>0.0); 
n = size(Data.Dtime, 1);
Rsoil_HH = [DAMM.(Tsoil[i,:], SWC[i,:], EaSx = 58.00) for i = 1:n];
Rsoil_HH = reduce(vcat, adjoint.(Rsoil_HH));
Rsoil_HH_mean = [mean(filter(x -> x > 0, Rsoil_HH[i,:])) for i = 1:n];
Rsoil_HH_std = [std(filter(x -> x > 0, Rsoil_HH[i,:])) for i = 1:n];

# Could put this in Load_Data.jl
SWC_mean = [mean(skipmissing(Data.SWC[i,:])) for i = 1:size(Data.SWC,1)];
SWC_std = [std(skipmissing(Data.SWC[i,:])) for i = 1:size(Data.SWC,1)];
Tsoil_mean = [mean(skipmissing(Data.Tsoil[i,:])) for i = 1:size(Data.Tsoil,1)];
Tsoil_std = [std(skipmissing(Data.Tsoil[i,:])) for i = 1:size(Data.Tsoil,1)];
#Rsoil_mean = [mean(skipmissing(Data.SWC[i,:])) for i = 1:size(Data.SWC,1)]

# Replace missing data (in space, e.g. faulty sensor) by spatial average for each day  
# this is to avoid weird spot in vizualisation when some data is missing
SWC_daily_fill = replace(Data.SWC_daily, 0.0=>missing);
Tsoil_daily_fill = replace(Data.Tsoil_daily, 0.0=>missing);
Rsoil_daily_fill = replace(Rsoil_daily, 0.0=>missing);
SWC_daily_fill = [replace(SWC_daily_fill[i,:], missing=>mean(skipmissing(SWC_daily_fill[i,:]))) for i = 1:size(Data.SWC_daily,1)]
Tsoil_daily_fill = [replace(Tsoil_daily_fill[i,:], missing=>mean(skipmissing(Tsoil_daily_fill[i,:]))) for i = 1:size(Data.Tsoil_daily,1)]
Rsoil_daily_fill = [replace(Rsoil_daily_fill[i,:], missing=>mean(skipmissing(Rsoil_daily_fill[i,:]))) for i = 1:size(Rsoil_daily,1)]


function create_plot(sl)
	scene = Scene(resolution = (860, 950), camera=campixel!);
	layout = GridLayout(
			    scene, 5, 3, 
			    colsizes = [Auto(), Auto(), Auto()],
			    rowsizes = [Auto(), Auto(), Auto(), Auto(), Auto()],
			    alignmode = Outside(10, 10, 10, 10)
			    )

	#function formatter(xs)
	#    map(xs) do x
	#        str = @sprintf("%.2f", x)
	#        startswith(str, "0") ? str[2:end] : str
	#    end
	#end;
	#ticks_SWC = CustomTicks((mi, ma, px) -> MakieLayout.locateticks(0.35, 0.48, 5), formatter);
	#ticks_Rs  = CustomTicks((mi, ma, px) -> MakieLayout.locateticks(0.25, 1, 5), formatter);
	labelpad = 5;

	#layout = layoutscene(6, 3, 10, resolution = (900, 900));
	ax = Array{LAxis}(undef, 11);
	Text_date = layout[1,1:3] = LText(scene, text= lift(X->Dates.format(Data.Dtime_all[X], "e, dd u yyyy"), sl.value), textsize=40);

	ax[1] = layout[5, 1:2] = LAxis(scene, yaxisposition = :right, xticklabelsvisible = false, xticksvisible = false, ylabelpadding = labelpad, xgridvisible = false, ygridvisible = false, yticklabelalign = (:left, :center), yticklabelsvisible = false, yticksvisible = false);
	precipbar = barplot!(ax[1], Data.Dtime_all_rata[1:end], Data.Precip_daily[1:end], color = :blue, strokewidth = 2, strokecolor = :black);
	#scatter!(ax[1], lift(X-> [Point2f0(Data.Dtime_all_rata[X], 0)], sl.value), marker = :vline, markersize = Vec2f0(0.5, 200), color = :black);

	lines!(ax[1], lift(X-> Point2f0[(Data.Dtime_all_rata[X], 0), (Data.Dtime_all_rata[X], 60)], sl.value));

	xlims!(ax[1], (Data.Dtime_all_rata[1], Data.Dtime_all_rata[end])); ylims!(ax[1], (0, 60));

	ax[2] = layout[5, 1:2] = LAxis(scene, ylabel = to_latex("\\theta (m^3 m^{-3})"), xlabel="Date", ylabelpadding = labelpad, ygridvisible = false, xgridvisible = false);
	lSWC = lines!(ax[2], Data.Dtime_all_rata[1:end], Data.SWC_daily_mean[1:end], color = :blue, linewidth = 2);
	bSWC = band!(ax[2], Data.Dtime_all_rata[1:end], Data.SWC_daily_mean[1:end] + Data.SWC_daily_std[1:end], Data.SWC_daily_mean[1:end] - Data.SWC_daily_std[1:end], color = color = RGBAf0(0,0,1,0.3));
	xlims!(ax[2], (Data.Dtime_all_rata[1], Data.Dtime_all_rata[end])); ylims!(ax[2], (0.36, 0.52));
	ax[2].xticks[] = (datetime2rata.(Data.dateticks) , Dates.format.(Data.dateticks, "mm"));

	ax[3] = layout[4, 1:2] = LAxis(scene, ylabel= to_latex("T_{soil} (°C)"), ylabelpadding = labelpad, xticklabelsvisible = false, xticksvisible = false, ygridvisible = false, xgridvisible = false);
	lTs = lines!(ax[3], Data.Dtime_all_rata[1:end], Data.Tsoil_daily_mean[1:end], color = :red, linewidth = 2);
	bTs = band!(ax[3], Data.Dtime_all_rata[1:end], Data.Tsoil_daily_mean[1:end] + Data.Tsoil_daily_std[1:end], Data.Tsoil_daily_mean[1:end] - Data.Tsoil_daily_std[1:end], color = RGBAf0(1,0,0,0.3));
	#scatter!(ax[3], lift(X-> [Point2f0(Data.Dtime_all_rata[X], 0)], sl.value), marker = :vline, markersize = Vec2f0(0.5,50), color = :black);

	lines!(ax[3], lift(X-> Point2f0[(Data.Dtime_all_rata[X], 0), (Data.Dtime_all_rata[X], 25)], sl.value));

	xlims!(ax[3], (Data.Dtime_all_rata[1], Data.Dtime_all_rata[end])); ylims!(ax[3], (0, 25));
	ax[3].xticks[] = (datetime2rata.(Data.dateticks) , Dates.format.(Data.dateticks, "mm"));

	ax[4] = layout[4, 1:2] = LAxis(scene, xticklabelsvisible = false, xticksvisible = false, xgridvisible = false, ygridvisible = false, yaxisposition = :right, ylabelpadding = 5, yticklabelalign = (:left, :center), yticklabelsvisible = false, yticksvisible = false);
	lRs = lines!(ax[4], Data.Dtime_all_rata[1:end], Rsoil_daily_mean[1:end], color = :green);
	bRs = band!(ax[4], Data.Dtime_all_rata[1:end], Rsoil_daily_mean[1:end] + Rsoil_daily_std[1:end], Rsoil_daily_mean[1:end] - Rsoil_daily_std[1:end], color = RGBAf0(0,1,0,0.3));
	xlims!(ax[4], (Data.Dtime_all_rata[1], Data.Dtime_all_rata[end])); ylims!(ax[4], (0.25, 3));
	yearm = [2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020, 2020]; monthm = [04, 05, 05, 06, 06, 06, 07, 07, 08, 08, 09, 09, 10]; daym = [20, 06, 18, 01, 08, 23, 08, 23, 11, 26, 10, 22, 13];
	dates_manual = datetime2rata.(Date.(yearm, monthm, daym));
	dates_auto = datetime2rata.(Data.Date_Auto);
	sRm = scatter!(ax[4], dates_manual, Data.RSMmean, marker = :circle, markersize = 10 * AbstractPlotting.px, color = :black);

	#[lines!(ax[4], Point2f0[(dates_manual[i], Data.RSMmean[i] + Data.RSMstd[i]), (dates_manual[i], Data.RSMmean[i] - Data.RSMstd[i])], color = :black) for i in 1:6];

	bottoms = Point2f0.(dates_manual, Data.RSMmean .- Data.RSMstd);
	tops = Point2f0.(dates_manual, Data.RSMmean .+ Data.RSMstd);
	pointpairs = collect(zip(bottoms, tops));
	ssRm = linesegments!(ax[4], pointpairs);


	lRa = lines!(ax[4], dates_auto, Data.RSAmean, color = RGBAf0(1,0,1));
	lRb = band!(ax[4], dates_auto, Data.RSAmean + Data.RSAstd, Data.RSAmean - Data.RSAstd, color = RGBAf0(1,0,1,0.3));

	leg = layout[4, 1:2] = LLegend(scene, [[bTs, lTs], [bRs, lRs], [sRm, ssRm], [lRa, lRb]], [to_latex("T_{soil}"), to_latex("R_{soilmo}"), to_latex("R_{soilmanual}"), to_latex("R_{soilauto}")], halign = :left, valign = :top, orientation = :horizontal, framevisible = false, nbanks = 2);
	#LLegend(scene; halign = :right, valign = :top, orientation = :horizontal, framevisible = false);
	#push!(leg, to_latex("T_{soil} (°C)"), bTs, lTs);
	#push!(leg, to_latex("R_{soil} (\\mumol m^{-2} s^{-1})"), bRs, lRs);

	leg2 = layout[5, 1:2] =  LLegend(scene, [[bSWC, lSWC], precipbar], [to_latex("\\theta"), "Precip"], halign = :left, valign = :top, orientation = :horizontal, framevisible = false);
	#LLegend(scene; halign = :right, valign = :top, orientation = :horizontal, framevisible = false);
	#push!(leg2, to_latex("\\theta (m^3 m^{-3})"), bSWC, lSWC);
	#push!(leg2, "Precip (mm)", precipbar);

	ax[8] = layout[5, 3] = LAxis(scene, xlabel = "Half-hour", yticklabelsvisible = false, yticksvisible = false, xgridvisible = false, ygridvisible = false);
	lines!(ax[8], 1:48, lift(X-> SWC_mean[1+(X-1)*48:X*48], sl.value), color = :blue);
	band!(ax[8], 1:48, lift(X-> SWC_mean[1+(X-1)*48:X*48] + SWC_std[1+(X-1)*48:X*48], sl.value), lift(X->SWC_mean[1+(X-1)*48:X*48] - SWC_std[1+(X-1)*48:X*48], sl.value), color = RGBAf0(0,0,1,0.3));
	ylims!(ax[8], (0.36, 0.52)); xlims!(ax[8], (1, 48));

	ax[10] = layout[5, 3] = LAxis(scene, ylabel = "Precip (mm)", xticklabelsvisible = false, xticksvisible = false, yticklabelsvisible = true, yticksvisible = true, yaxisposition = :right, ylabelpadding = labelpad, yticklabelalign = (:left, :center), xgridvisible = false, ygridvisible = false);
	barplot!(ax[10], 1:25, lift(X-> Data.metdata.Precip[550+(X-1)*25:549 + X*25], sl.value), color = :blue, strokewidth = 2, strokecolor = :black);
	ylims!(ax[10], (0, 60)); xlims!(ax[10], (1, 24));

	ax[9] = layout[4, 3] = LAxis(scene, xticklabelsvisible = false, xticksvisible = false, yticklabelsvisible = false, yticksvisible = false, xgridvisible = false, ygridvisible = false);
	lines!(ax[9], 1:48, lift(X-> Tsoil_mean[1+(X-1)*48:X*48], sl.value), color = :red);
	band!(ax[9], 1:48, lift(X-> Tsoil_mean[1+(X-1)*48:X*48] + Tsoil_std[1+(X-1)*48:X*48], sl.value), lift(X->Tsoil_mean[1+(X-1)*48:X*48] - Tsoil_std[1+(X-1)*48:X*48], sl.value), color = RGBAf0(1,0,0,0.3));
	ylims!(ax[9], (0, 7)); xlims!(ax[9], (1, 48));

	ax[11] = layout[4, 3] = LAxis(scene, ylabel = to_latex("R_{soil} (\\mumol m^{-2} s^{-1})"), xticklabelsvisible = false, xticksvisible = false, yticklabelsvisible = true, yticksvisible = true, yaxisposition = :right, ylabelpadding = labelpad, yticklabelalign = (:left, :center), xgridvisible = false, ygridvisible = false); 
	lines!(ax[11], 1:48, lift(X-> Rsoil_HH_mean[1+(X-1)*48:X*48], sl.value), color = :green);
	band!(ax[11], 1:48, lift(X-> Rsoil_HH_mean[1+(X-1)*48:X*48] + Rsoil_HH_std[1+(X-1)*48:X*48], sl.value), lift(X-> Rsoil_HH_mean[1+(X-1)*48:X*48] - Rsoil_HH_std[1+(X-1)*48:X*48], sl.value), color = RGBAf0(0,1,0,0.3));
	ylims!(ax[11], (0.25, 0.6)); xlims!(ax[11], (1, 48));

	cbar = Array{LColorbar}(undef,3);

	ax[5] = layout[3, 1] = LAxis(scene, ylabel = "1 Hectar", ylabelpadding = 10, xticklabelsvisible = false, xticksvisible = false, yticklabelsvisible = false, yticksvisible = false);
	hmap1 = heatmap!(ax[5], Data.x, Data.y, lift(X-> Matrix(sparse(Data.x, Data.y, reduce(vcat, SWC_daily_fill[X,:]))), sl.value), colormap = cgrad(:RdYlBu; categorical = true), colorrange = (0.35, 0.48), interpolate = true, show_axis = false);
	xlims!(ax[5], (1,8)); ylims!(ax[5], (1,8));
	cbar[1] = layout[2, 1] = LColorbar(scene, height = 20, limits = (0.35, 0.48), label = to_latex("\\theta (m^3 m^{-3})"), colormap = cgrad(:RdYlBu; categorical = true), vertical = false, labelpadding = -5, ticklabelalign = (:center, :center), ticklabelpad = 15);
	scatter!(ax[5], Data.x, Data.y, color = :black, markersize = 2);

	ax[6] = layout[3, 2] = LAxis(scene, yticksvisible = false, yticklabelsvisible = false, xticklabelsvisible = false, xticksvisible = false);
	hmap2 = heatmap!(ax[6], Data.x, Data.y, lift(X-> Matrix(sparse(Data.x, Data.y, reduce(vcat,Tsoil_daily_fill[X,:]))), sl.value), colormap = reverse(cgrad(:RdYlBu; categorical = true)), colorrange = (0, 25), show_axis = false, interpolate = true);
	xlims!(ax[6], (1,8)); ylims!(ax[6], (1,8));
	cbar[2] = layout[2, 2] = LColorbar(scene, height = 20, limits = (0, 25), label = to_latex("T_{soil} (°C)"), colormap = reverse(cgrad(:RdYlBu; categorical = true)), vertical = false, labelpadding = -5, ticklabelalign = (:center, :center), ticklabelpad = 15);
	scatter!(ax[6], Data.x, Data.y, color = :black, markersize = 2);

	ax[7] = layout[3, 3] = LAxis(scene, yticksvisible = false,  yticklabelsvisible = false, xticklabelsvisible = false, xticksvisible = false);
	hmap3 = heatmap!(ax[7], Data.x, Data.y, lift(X-> Matrix(sparse(Data.x, Data.y, reduce(vcat, Rsoil_daily_fill[X,:]))), sl.value), colormap = reverse(cgrad(:RdYlBu; categorical = true)), colorrange = (0, 10), show_axis = false, interpolate = true);
	xlims!(ax[7], (1,8)); ylims!(ax[7], (1,8));
	cbar[3] = layout[2, 3] = LColorbar(scene, height = 20, limits = (0, 10), label = to_latex("R_{soil} (\\mumol m^{-2} s^{-1})"), colormap = reverse(cgrad(:RdYlBu; categorical = true)), vertical = false, labelpadding = -5, ticklabelalign = (:center, :center), ticklabelpad = 15);
	scatter!(ax[7], Data.x, Data.y, color = :black, markersize = 2);


	scene

	# Limits
	SWCmin, SWCmax = 0.1, 0.55; Tmin, Tmax = 0, 25; Rmin, Rmax = 0, 20; Pmin, Pmax = 0, 60;

	xlims!(ax[1], (Data.Dtime_all_rata[1], Data.Dtime_all_rata[end])); ylims!(ax[1], (Pmin, Pmax));
	xlims!(ax[2], (Data.Dtime_all_rata[1], Data.Dtime_all_rata[end])); ylims!(ax[2], (SWCmin, SWCmax));
	xlims!(ax[3], (Data.Dtime_all_rata[1], Data.Dtime_all_rata[end])); ylims!(ax[3], (Tmin, Tmax));
	xlims!(ax[4], (Data.Dtime_all_rata[1], Data.Dtime_all_rata[end])); ylims!(ax[4], (Rmin, Rmax));
	xlims!(ax[5], (1,8)); ylims!(ax[5], (1,8));
	xlims!(ax[6], (1,8)); ylims!(ax[6], (1,8));
	xlims!(ax[7], (1,8)); ylims!(ax[7], (1,8));
	ylims!(ax[8], (SWCmin, SWCmax)); xlims!(ax[8], (1, 48));
	ylims!(ax[9], (Tmin, Tmax)); xlims!(ax[9], (1, 48));
	ylims!(ax[10], (Pmin, Pmax)); xlims!(ax[10], (1, 24));
	ylims!(ax[11], (Rmin, Rmax)); xlims!(ax[11], (1, 48));
	cbar[1].limits = (SWCmin, SWCmax);
	cbar[2].limits = (Tmin, Tmax);
	cbar[3].limits = (Rmin, Rmax);
	hmap1.colorrange = (SWCmin, SWCmax); 
	hmap2.colorrange = (Tmin, Tmax);
	hmap3.colorrange = (Rmin, Rmax);
	return scene
end

function handler(s, r)
    sl = JSServe.Slider(1:280)
    scene = create_plot(sl)
    sldisp = DOM.div(sl, style="width: $(size(scene)[2] -250)px")
    return DOM.div(JSServe.Asset(JSServe.dependency_path("styled.css")), sldisp, scene, style = """
    display: flex;
    fle: flex;
    flex-direction: column;
    align-items: center;
    """)
end

#JSServe.with_session() do s, r
#  return JSServe.record_state_map(s, handler)
#end

# lines below from BasicWGLMakie.jl
AppInteraktive(s, r) = JSServe.record_state_map(s, handler(s, r)).dom
s = JSServe.Session()
states = AppInteraktive(s, nothing)
#sizeof(MsgPack.pack(x)) / 10^6
mkdir("simple")
JSServe.export_standalone(AppInteraktive, "simple")

