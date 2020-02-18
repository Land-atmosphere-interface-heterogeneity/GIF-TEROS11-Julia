include("Load_Data.jl"); # Currently, @time ~20 sec first run, ~4 sec next runs. Could be improved!
include("DAMM.jl");
include("DAMM_param.jl");

using Makie, MakieLayout, Dates, GLMakie, GeometryTypes, SparseArrays
using PlotUtils: optimize_ticks

# Until I figure how to deal with missing data 
SWC_daily = replace(SWC_daily, missing=>0.0); SWC_daily_mean = replace(SWC_daily_mean, missing=>0.0); SWC_daily_std = replace(SWC_daily_std, missing=>0.0);
Tsoil_daily = replace(Tsoil_daily, missing=>0.0); Tsoil_daily_mean = replace(Tsoil_daily_mean, missing=>0.0); Tsoil_daily_std = replace(Tsoil_daily_std, missing=>0.0);

n_all = size(SWC_daily, 1); # Below are random data, for now
PD = 3.1; porosity = 1-BD/PD; # Avoid complexe number problem DAMM
Rsoil_daily = [DAMM.(Tsoil_daily[i,:], SWC_daily[i,:]) for i = 1:n_all];
Rsoil_daily = reduce(vcat, adjoint.(Rsoil_daily));
Rsoil_daily_mean = [mean(Rsoil_daily[i,:]) for i = 1:n_all];
Rsoil_daily_std = [std(Rsoil_daily[i,:]) for i = 1:n_all];
#Rsoil_daily = rand(n_all, 64);
#Rsoil_daily_mean = rand(n_all, 1); Rsoil_daily_std = rand(n_all, 1);
Wtable_daily = rand(n_all,1);
elev = rand(8,8).+1;
Dtime_all_rata = datetime2rata.(Dtime_all);
dateticks = optimize_ticks(Dtime_all[1],Dtime_all[end])[1];
x = [0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,6,7,7,7,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,6,7,7,7] .+ 1;
y = [0,1,2,2,1,0,0,1,2,2,1,0,0,1,2,2,1,0,0,1,2,2,1,0,3,4,4,3,4,3,3,4,4,3,3,4,4,3,4,3,5,6,7,7,6,5,5,6,7,7,6,5,5,6,7,7,6,5,5,6,7,7,6,5] .+ 1;

# Create Scene and 2D axis
scene, layout = layoutscene(10, 24, 10, resolution = (1500, 900))
ax = Array{LAxis}(undef,4)
sl = layout[10, 1:23] = LSlider(scene, range=1:n_all)

Text_date = layout[1,1:23] = LText(scene, text= lift(X->Dates.format(Dtime_all[X], "e, dd u yyyy"), sl.value), textsize=40)
# SWC + Precip time-series (bottom)
ax[3] = layout[8:9, 1:23] = LAxis(scene, ylabel = "Precip", yaxisposition = :right, xticklabelsvisible = false, xticksvisible = false, ylabelpadding = -10, xgridvisible = false, ygridvisible = false, yticklabelalign = (:left, :center))
precipbar = barplot!(ax[3], Dtime_all_rata[1:end], Precip_daily[1:end], color = :blue)
scatter!(ax[3], lift(X-> [Point2f0(Dtime_all_rata[X], 0)], sl.value), marker = :vline, markersize = Vec2f0(0.5, 50), color = :black)
xlims!(ax[3], (Dtime_all_rata[1], Dtime_all_rata[end])); ylims!(ax[3], (0, 24))

ax[1] = layout[8:9, 1:23] = LAxis(scene, ylabel="SWC", xlabel="Date", ylabelpadding = -25)
lines!(ax[1], Dtime_all_rata[1:end], SWC_daily_mean[1:end], color = :blue, linewidth = 2)
band!(ax[1], Dtime_all_rata[1:end], SWC_daily_mean[1:end] + SWC_daily_std[1:end], SWC_daily_mean[1:end] - SWC_daily_std[1:end], color = color = RGBAf0(0,0,1,0.3))
xlims!(ax[1], (Dtime_all_rata[1], Dtime_all_rata[end])); ylims!(ax[1], (0.36, 0.46))
ax[1].xticks[] = ManualTicks(datetime2rata.(dateticks) , Dates.format.(dateticks, "yyyy-mm-dd"))


# Tsoil + Rsoil time-series (bottom)
ax[2] = layout[6:7, 1:23] = LAxis(scene, ylabel="Ts", ylabelpadding = -25, xticklabelsvisible = false, xticksvisible = false)
lines!(ax[2], Dtime_all_rata[1:end], Tsoil_daily_mean[1:end], color = :red, linewidth = 2)
band!(ax[2], Dtime_all_rata[1:end], Tsoil_daily_mean[1:end] + Tsoil_daily_std[1:end], Tsoil_daily_mean[1:end] - Tsoil_daily_std[1:end], color = RGBAf0(1,0,0,0.3))
scatter!(ax[2], lift(X-> [Point2f0(Dtime_all_rata[X], 0)], sl.value), marker = :vline, markersize = Vec2f0(0.5,50), color = :black)
xlims!(ax[2], (Dtime_all_rata[1], Dtime_all_rata[end]));
ax[2].xticks[] = ManualTicks(datetime2rata.(dateticks) , Dates.format.(dateticks, "yyyy-mm-dd"))

ax[4] = layout[6:7, 1:23] = LAxis(scene, ylabel = "Rs", xticklabelsvisible = false, xticksvisible = false, xgridvisible = false, ygridvisible = false, yaxisposition = :right, ylabelpadding = -10, yticklabelalign = (:left, :center))
lines!(ax[4], Dtime_all_rata[1:end], Rsoil_daily_mean[1:end], color = :black)
xlims!(ax[4], (Dtime_all_rata[1], Dtime_all_rata[end]));

ax3D = Array{LRect}(undef,3)
cbar = Array{LColorbar}(undef,3)

ax3D[1] = layout[1:7, 1:8] = LRect(scene, visible = false);
scene3D_1 = Scene(scene, lift(IRect2D, ax3D[1].layoutnodes.computedbbox), camera = cam3d!, raw = false, show_axis = true);
surface!(scene3D_1, 0:7, 0:7, elev, color = lift(X-> GLMakie.vec2color(Matrix(sparse(x, y, SWC_daily[X,:])), Reverse(:kdc), (0.35, 0.48)), sl.value), shading = false, limits = Rect(0, 0, 0, 7, 7, 1.5));
x_or = [0,0,0]; Ylen = 7; Zlen = 1; Xlen = 7;
mesh!(scene3D_1, lift(X-> HyperRectangle(Vec3f0(x_or), Vec3f0(Xlen, Ylen, Wtable_daily[X])), sl.value) , color = RGBAf0(0,0,1,0.2));
cbar[1] = layout[2, 2:7] = LColorbar(scene, height = 20, limits = (0.35, 0.48), label = "SWC", colormap = Reverse(:kdc), vertical = false, labelpadding = -5);

ax3D[2] = layout[1:7, 9:16] = LRect(scene, visible = false);
scene3D_2 = Scene(scene, lift(IRect2D, ax3D[2].layoutnodes.computedbbox), camera = cam3d!, raw = false, show_axis = true);
surface!(scene3D_2, 0:7, 0:7, elev, color = lift(X-> GLMakie.vec2color(Matrix(sparse(x, y, Tsoil_daily[X,:])), :coolwarm, (1, 7)), sl.value), shading = false, limits = Rect(0, 0, 0, 7, 7, 1.5));
x_or = [0,0,0]; Ylen = 7; Zlen = 1; Xlen = 7;
mesh!(scene3D_2, lift(X-> HyperRectangle(Vec3f0(x_or), Vec3f0(Xlen, Ylen, Wtable_daily[X])), sl.value) , color = RGBAf0(0,0,1,0.2));	
cbar[2] = layout[2, 10:15] = LColorbar(scene, height = 20, limits = (1, 7), label = "Tsoil", colormap = :coolwarm, vertical = false, labelpadding = -5);

ax3D[3] = layout[1:7, 17:24] = LRect(scene, visible = false);
scene3D_3 = Scene(scene, lift(IRect2D, ax3D[3].layoutnodes.computedbbox), camera = cam3d!, raw = false, show_axis = true);
surface!(scene3D_3, 0:7, 0:7, elev, color = lift(X-> GLMakie.vec2color(Matrix(sparse(x, y, Rsoil_daily[X,:])), :viridis, (0.25,0.5)), sl.value), shading = false, limits = Rect(0, 0, 0, 7, 7, 1.5));
x_or = [0,0,0]; Ylen = 7; Zlen = 1; Xlen = 7;
mesh!(scene3D_3, lift(X-> HyperRectangle(Vec3f0(x_or), Vec3f0(Xlen, Ylen, Wtable_daily[X])), sl.value) , color = RGBAf0(0,0,1,0.2));	  
cbar[3] = layout[2, 18:23] = LColorbar(scene, height = 20, limits = (0.25, 0.5), label = "Rsoil", colormap = :viridis, vertical = false, labelpadding = -5);

axis1 = scene3D_1[Axis]
axis1.names.axisnames = ("Coordinate x (m)","Coordinate y (m)","z")
axis1[:names][:textsize] = (20.0,20.0,20.0) # same as axis.names.textsize
axis1[:ticks][:textsize] = (20.0,20.0,20.0)
axis1[:ticks][:ranges_labels] = (([1.0,3.0,5.0,7.0], [1.0,3.0,5.0,7.0], [1.0, 1.25, 1.5, 1.75, 2.0]), (["75","50","25","0"], ["75","50","25","0"], ["1.00", "1.25", "1.50", "1.75", "2.00"]))

axis2 = scene3D_2[Axis]
axis2.names.axisnames = ("Coordinate x (m)","Coordinate y (m)","z")
axis2[:names][:textsize] = (20.0,20.0,20.0) # same as axis.names.textsize
axis2[:ticks][:textsize] = (20.0,20.0,20.0)
axis2[:ticks][:ranges_labels] = (([1.0,3.0,5.0,7.0], [1.0,3.0,5.0,7.0], [1.0, 1.25, 1.5, 1.75, 2.0]), (["75","50","25","0"], ["75","50","25","0"], ["1.00", "1.25", "1.50", "1.75", "2.00"]))

axis3 = scene3D_3[Axis]
axis3.names.axisnames = ("Coordinate x (m)","Coordinate y (m)","z")
axis3[:names][:textsize] = (20.0,20.0,20.0) # same as axis.names.textsize
axis3[:ticks][:textsize] = (20.0,20.0,20.0)
axis3[:ticks][:ranges_labels] = (([1.0,3.0,5.0,7.0], [1.0,3.0,5.0,7.0], [1.0, 1.25, 1.5, 1.75, 2.0]), (["75","50","25","0"], ["75","50","25","0"], ["1.00", "1.25", "1.50", "1.75", "2.00"]))

scene

# to record some interaction
record(scene, "images\\Interaction.gif") do io
      for i = 1:200
          sleep(0.05)     
          recordframe!(io) # record a new frame
      end
  end

