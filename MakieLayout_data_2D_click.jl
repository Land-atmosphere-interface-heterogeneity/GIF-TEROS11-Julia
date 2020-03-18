using Makie, MakieLayout, Dates, GLMakie, GeometryTypes, SparseArrays, UnicodeFun
using PlotUtils: optimize_ticks

function MakieLayout.legendelements(plot::BarPlot)
    MakieLayout.LegendElement[PolyElement(color = plot.color, strokecolor = plot.strokecolor)]
end
# this is for Precip legend, won't be needed in futur version of MakieLayout

include("Load_Data.jl");
include("DAMM.jl");
include("DAMM_param.jl");
function loaddata()
	# Load raw data, functions below can be found in Load_Data.jl
	data = loadteros("Input\\TEROS\\")
	metdata = loadmet("Input\\MET TOWER\\")
	x, y = loadmeta("Input\\Metadata.csv")
	Dtime = collect(Dates.DateTime(DateTime(2019, 11, 23, 00, 00, 00)):Dates.Minute(30):now())
	SWC = loadSWC(data, Dtime)
	Tsoil = loadTsoil(data, Dtime)
	Dtime_met = loadDtimemet(metdata)
	Precip_d, Dtime_met_d = PrecipD(metdata, Dtime_met)
	Dtime_all = collect(Date(2019, 11, 23):Day(1):today()) # Need same datetime (daily) for SWC data and met data
	Tsoil_daily, Tsoil_daily_mean, Tsoil_daily_std = dailyval(Tsoil, Dtime_all)
	SWC_daily, SWC_daily_mean, SWC_daily_std = dailyval(SWC, Dtime_all)
	Precip_daily = Precipdaily(Precip_d, Dtime_all, Dtime_met_d)

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
		#Dtime_rata = Dtime_rata
		)
end;
Data = loaddata();

# Modeled Rsoil
n_all = size(Data.SWC_daily, 1); # Below are random data, for now
PD = 3.1; porosity = 1-BD/PD # Avoid complexe number problem DAMM
Rsoil_daily = [DAMM.(Data.Tsoil_daily[i,:], Data.SWC_daily[i,:]) for i = 1:n_all];
Rsoil_daily = reduce(vcat, adjoint.(Rsoil_daily));
Rsoil_daily_mean = [mean(filter(x -> x > 0, Rsoil_daily[i,:])) for i = 1:n_all];
Rsoil_daily_std = [std(filter(x -> x > 0, Rsoil_daily[i,:])) for i = 1:n_all];

# Half-hourly
SWC  = replace(Data.SWC , missing=>0.0); 
Tsoil  = replace(Data.Tsoil , missing=>0.0); 
n = size(Data.Dtime, 1);
Rsoil_HH = [DAMM.(Tsoil[i,:], SWC[i,:]) for i = 1:n];
Rsoil_HH = reduce(vcat, adjoint.(Rsoil_HH));
Rsoil_HH_mean = [mean(filter(x -> x > 0, Rsoil_HH[i,:])) for i = 1:n];
Rsoil_HH_std = [std(filter(x -> x > 0, Rsoil_HH[i,:])) for i = 1:n];

# Could put this in Load_Data.jl
SWC_mean = [mean(skipmissing(Data.SWC[i,:])) for i = 1:size(Data.SWC,1)];
SWC_std = [std(skipmissing(Data.SWC[i,:])) for i = 1:size(Data.SWC,1)];
Tsoil_mean = [mean(skipmissing(Data.Tsoil[i,:])) for i = 1:size(Data.Tsoil,1)];
Tsoil_std = [std(skipmissing(Data.Tsoil[i,:])) for i = 1:size(Data.Tsoil,1)];
#Rsoil_mean = [mean(skipmissing(Data.SWC[i,:])) for i = 1:size(Data.SWC,1)]

# Create Scene and 2D axis
scene = Scene(resolution = (900, 900), camera=campixel!);
layout = GridLayout(
		    scene, 5, 3, 
		    colsizes = [Auto(), Auto(), Auto()],
		    rowsizes = [Fixed(50), Auto(), Auto(), Auto(), Auto()],
		    alignmode = Outside(10, 10, 10, 10)
		    )

#layout = layoutscene(6, 3, 10, resolution = (900, 900));
ax = Array{LAxis}(undef, 12);

ax[12] = layout[4:5, 1:2] = LAxis(scene,
xticksvisible = false,
yticksvisible = false,
xgridvisible = false,
ygridvisible = false,
yticklabelsvisible = false,
xticklabelsvisible = false,
leftspinevisible = false,
rightspinevisible = false
);

scatter!(ax[12], collect(1:n_all), collect(1:n_all), visible = false);
xlims!(ax[12], (1, 100));

xpos = Node(1)

#on(ax[12].scene.events.mousebuttons) do buttons
#   if ispressed(ax[12].scene, Mouse.left)
#	   xpos[] = round(Int64, mouseposition(ax[12].scene)[1])
#   end
#   return
#end

mousestate = MakieLayout.addmousestate!(ax[12].scene)
onmouseleftdrag(mousestate) do state
	xpos[] = round(state.pos[1])
end


#sl = layout[6, 1:2] = LSlider(scene, range=1:n_all);
Text_date = layout[1,1:3] = LText(scene, text= lift(X->Dates.format(Data.Dtime_all[X], "e, dd u yyyy"), xpos), textsize=40);

ax[1] = layout[5, 1:2] = LAxis(scene, yaxisposition = :right, xticklabelsvisible = false, xticksvisible = false, ylabelpadding = 15, xgridvisible = false, ygridvisible = false, yticklabelalign = (:left, :center), yticklabelsvisible = false, yticksvisible = false);
precipbar = barplot!(ax[1], Data.Dtime_all_rata[1:end], Data.Precip_daily[1:end], color = :blue, strokewidth = 2, strokecolor = :black);
scatter!(ax[1], lift(X-> [Point2f0(Data.Dtime_all_rata[X], 0)], xpos), marker = :vline, markersize = Vec2f0(0.5, 200), color = :black);
xlims!(ax[1], (Data.Dtime_all_rata[1], Data.Dtime_all_rata[end])); ylims!(ax[1], (0, 60));

ax[2] = layout[5, 1:2] = LAxis(scene, ylabel = to_latex("\\theta (m^3 m^{-3})"), xlabel="Date", ylabelpadding = 15, ygridvisible = false, xgridvisible = false);
lSWC = lines!(ax[2], Data.Dtime_all_rata[1:end], Data.SWC_daily_mean[1:end], color = :blue, linewidth = 2);
bSWC = band!(ax[2], Data.Dtime_all_rata[1:end], Data.SWC_daily_mean[1:end] + Data.SWC_daily_std[1:end], Data.SWC_daily_mean[1:end] - Data.SWC_daily_std[1:end], color = color = RGBAf0(0,0,1,0.3));
xlims!(ax[2], (Data.Dtime_all_rata[1], Data.Dtime_all_rata[end])); ylims!(ax[2], (0.36, 0.52));
ax[2].xticks[] = ManualTicks(datetime2rata.(Data.dateticks) , Dates.format.(Data.dateticks, "yyyy-mm-dd"));

ax[3] = layout[4, 1:2] = LAxis(scene, ylabel= to_latex("T_{soil} (°C)"), ylabelpadding = 15, xticklabelsvisible = false, xticksvisible = false, ygridvisible = false, xgridvisible = false);
lTs = lines!(ax[3], Data.Dtime_all_rata[1:end], Data.Tsoil_daily_mean[1:end], color = :red, linewidth = 2);
bTs = band!(ax[3], Data.Dtime_all_rata[1:end], Data.Tsoil_daily_mean[1:end] + Data.Tsoil_daily_std[1:end], Data.Tsoil_daily_mean[1:end] - Data.Tsoil_daily_std[1:end], color = RGBAf0(1,0,0,0.3));
scatter!(ax[3], lift(X-> [Point2f0(Data.Dtime_all_rata[X], 0)], xpos), marker = :vline, markersize = Vec2f0(0.5,50), color = :black);
xlims!(ax[3], (Data.Dtime_all_rata[1], Data.Dtime_all_rata[end])); ylims!(ax[3], (0, 7));
ax[3].xticks[] = ManualTicks(datetime2rata.(Data.dateticks) , Dates.format.(Data.dateticks, "yyyy-mm-dd"));

ax[4] = layout[4, 1:2] = LAxis(scene, xticklabelsvisible = false, xticksvisible = false, xgridvisible = false, ygridvisible = false, yaxisposition = :right, ylabelpadding = 15, yticklabelalign = (:left, :center), yticklabelsvisible = false, yticksvisible = false);
lRs = lines!(ax[4], Data.Dtime_all_rata[1:end], Rsoil_daily_mean[1:end], color = :green);
bRs = band!(ax[4], Data.Dtime_all_rata[1:end], Rsoil_daily_mean[1:end] + Rsoil_daily_std[1:end], Rsoil_daily_mean[1:end] - Rsoil_daily_std[1:end], color = RGBAf0(0,1,0,0.3));
xlims!(ax[4], (Data.Dtime_all_rata[1], Data.Dtime_all_rata[end])); ylims!(ax[4], (0.25, 0.6));

leg = layout[4, 1:2] = LLegend(scene; halign = :right, valign = :top, orientation = :horizontal, framevisible = false);
push!(leg, to_latex("T_{soil} (°C)"), bTs, lTs);
push!(leg, to_latex("R_{soil} (\\mumol m^{-2} s^{-1})"), bRs, lRs);

leg2 = layout[5, 1:2] = LLegend(scene; halign = :right, valign = :top, orientation = :horizontal, framevisible = false);
push!(leg2, to_latex("\\theta (m^3 m^{-3})"), bSWC, lSWC);
push!(leg2, "Precip (mm)", precipbar);

ax[8] = layout[5, 3] = LAxis(scene, xlabel = "Half-hour", yticklabelsvisible = false, yticksvisible = false, xgridvisible = false, ygridvisible = false);
lines!(ax[8], 1:48, lift(X-> SWC_mean[1+(X-1)*48:X*48], xpos), color = :blue);
band!(ax[8], 1:48, lift(X-> SWC_mean[1+(X-1)*48:X*48] + SWC_std[1+(X-1)*48:X*48], xpos), lift(X->SWC_mean[1+(X-1)*48:X*48] - SWC_std[1+(X-1)*48:X*48], xpos), color = RGBAf0(0,0,1,0.3));
ylims!(ax[8], (0.36, 0.52)); xlims!(ax[8], (1, 48));

ax[10] = layout[5, 3] = LAxis(scene, ylabel = "Precip (mm)", xticklabelsvisible = false, xticksvisible = false, yticklabelsvisible = true, yticksvisible = true, yaxisposition = :right, ylabelpadding = 15, yticklabelalign = (:left, :center), xgridvisible = false, ygridvisible = false);
barplot!(ax[10], 1:25, lift(X-> Data.metdata.Precip[550+(X-1)*25:549 + X*25], xpos), color = :blue, strokewidth = 2, strokecolor = :black);
ylims!(ax[10], (0, 60)); xlims!(ax[8], (1, 48));

ax[9] = layout[4, 3] = LAxis(scene, xticklabelsvisible = false, xticksvisible = false, yticklabelsvisible = false, yticksvisible = false, xgridvisible = false, ygridvisible = false);
lines!(ax[9], 1:48, lift(X-> Tsoil_mean[1+(X-1)*48:X*48], xpos), color = :red);
band!(ax[9], 1:48, lift(X-> Tsoil_mean[1+(X-1)*48:X*48] + Tsoil_std[1+(X-1)*48:X*48], xpos), lift(X->Tsoil_mean[1+(X-1)*48:X*48] - Tsoil_std[1+(X-1)*48:X*48], xpos), color = RGBAf0(1,0,0,0.3));
ylims!(ax[9], (0, 7)); xlims!(ax[9], (1, 48));

ax[11] = layout[4, 3] = LAxis(scene, ylabel = to_latex("R_{soil} (\\mumol m^{-2} s^{-1})"), xticklabelsvisible = false, xticksvisible = false, yticklabelsvisible = true, yticksvisible = true, yaxisposition = :right, ylabelpadding = 15, yticklabelalign = (:left, :center), xgridvisible = false, ygridvisible = false); 
lines!(ax[11], 1:48, lift(X-> Rsoil_HH_mean[1+(X-1)*48:X*48], xpos), color = :green);
band!(ax[11], 1:48, lift(X-> Rsoil_HH_mean[1+(X-1)*48:X*48] + Rsoil_HH_std[1+(X-1)*48:X*48], xpos), lift(X-> Rsoil_HH_mean[1+(X-1)*48:X*48] - Rsoil_HH_std[1+(X-1)*48:X*48], xpos), color = RGBAf0(0,1,0,0.3));
ylims!(ax[11], (0.25, 0.6)); xlims!(ax[11], (1, 48));

cbar = Array{LColorbar}(undef,3);

ax[5] = layout[3, 1] = LAxis(scene, ylabel = "1 Hectar", ylabelpadding = 10, xticklabelsvisible = false, xticksvisible = false, yticklabelsvisible = false, yticksvisible = false);
heatmap!(ax[5], Data.x, Data.y, lift(X-> Matrix(sparse(Data.x, Data.y, Data.SWC_daily[X,:])), xpos), colormap = :kdc, colorrange = (0.35, 0.48), interpolate = true, show_axis = false);
xlims!(ax[5], (1,8)); ylims!(ax[5], (1,8));
cbar[1] = layout[2, 1] = LColorbar(scene, height = 20, limits = (0.35, 0.48), label = to_latex("\\theta (m^3 m^{-3})"), colormap = :kdc, vertical = false, labelpadding = -5, ticklabelalign = (:center, :center), ticklabelpad = 15);

ax[6] = layout[3, 2] = LAxis(scene, yticksvisible = false, yticklabelsvisible = false, xticklabelsvisible = false, xticksvisible = false);
heatmap!(ax[6], Data.x, Data.y, lift(X-> Matrix(sparse(Data.x, Data.y, Data.Tsoil_daily[X,:])), xpos), colormap = :fire, colorrange = (1, 7), show_axis = false, interpolate = true);
xlims!(ax[6], (1,8)); ylims!(ax[6], (1,8));
cbar[2] = layout[2, 2] = LColorbar(scene, height = 20, limits = (1, 7), label = to_latex("T_{soil} (°C)"), colormap = :fire, vertical = false, labelpadding = -5, ticklabelalign = (:center, :center), ticklabelpad = 15);

ax[7] = layout[3, 3] = LAxis(scene, yticksvisible = false,  yticklabelsvisible = false, xticklabelsvisible = false, xticksvisible = false);
heatmap!(ax[7], Data.x, Data.y, lift(X-> Matrix(sparse(Data.x, Data.y, Rsoil_daily[X,:])), xpos), colormap = :kgy, colorrange = (0.25, 0.6), show_axis = false, interpolate = true);
xlims!(ax[7], (1,8)); ylims!(ax[7], (1,8));
cbar[3] = layout[2, 3] = LColorbar(scene, height = 20, limits = (0.25, 0.6), label = to_latex("R_{soil} (\\mumol m^{-2} s^{-1})"), colormap = :kgy, vertical = false, labelpadding = -5, ticklabelalign = (:center, :center), ticklabelpad = 15);

scene

xlims!(ax[1], (Data.Dtime_all_rata[1], Data.Dtime_all_rata[end])); ylims!(ax[1], (0, 60));
xlims!(ax[2], (Data.Dtime_all_rata[1], Data.Dtime_all_rata[end])); ylims!(ax[2], (0.36, 0.52));
xlims!(ax[3], (Data.Dtime_all_rata[1], Data.Dtime_all_rata[end])); ylims!(ax[3], (0, 7));
xlims!(ax[4], (Data.Dtime_all_rata[1], Data.Dtime_all_rata[end])); ylims!(ax[4], (0.25, 0.6));
xlims!(ax[5], (1,8)); ylims!(ax[5], (1,8));
xlims!(ax[6], (1,8)); ylims!(ax[6], (1,8));
xlims!(ax[7], (1,8)); ylims!(ax[7], (1,8));
ylims!(ax[8], (0.36, 0.52)); xlims!(ax[8], (1, 48));
ylims!(ax[9], (0, 7)); xlims!(ax[9], (1, 48));
ylims!(ax[10], (0, 60)); xlims!(ax[8], (1, 48));
ylims!(ax[11], (0.25, 0.6)); xlims!(ax[11], (1, 48));
xlims!(ax[12], (1, 100));


# to record some interaction
# record(scene, "images\\Interaction2D.gif") do io
#      for i = 1:200
#          sleep(0.1)     
#          recordframe!(io) # record a new frame
#      end
#  end


# Note: interactive figure crash in February because no precip data in february. Easy fix. 

# TO DO
# 1. use recent met data to have recent precip. Missing precip data makes the plot buggy. 
# 2. Make heatmap and colorbar discrete (5 or 6 levels?)
# 3. Possibly, add black like contour around these 5 or 6 levels
# 4. Make hovering colorbar highlight the heatmap, as in https://ourworldindata.org/coronavirus
#
# 5. Eventually, allow selection of an area by dragging mouse. Heatmap and diurnals will be average of that selection. 
