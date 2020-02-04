using Makie, MakieLayout, Dates, GLMakie, GeometryTypes, SparseArrays
using PlotUtils: optimize_ticks


# Dummy data
n_all = 100
SWC_daily = rand(n_all, 64); SWC_daily_mean = rand(n_all, 1); SWC_daily_std = rand(n_all, 1)
Tsoil_daily = rand(n_all, 64); Tsoil_daily_mean = rand(n_all, 1); Tsoil_daily_std = rand(n_all, 1)
Rsoil_daily = rand(n_all, 64); Rsoil_daily_mean = rand(n_all, 1); Rsoil_daily_std = rand(n_all, 1)
Precip_daily = rand(n_all, 1);
Wtable_daily = rand(n_all,1);
Dtime_all = collect(Date(2019, 01, 01):Day(1):Date(2019, 01, 01)+Day(n_all-1))
elev = rand(8,8).+.4
x = [0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,6,7,7,7,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,6,7,7,7] .+ 1
y = [0,1,2,2,1,0,0,1,2,2,1,0,0,1,2,2,1,0,0,1,2,2,1,0,3,4,4,3,4,3,3,4,4,3,3,4,4,3,4,3,5,6,7,7,6,5,5,6,7,7,6,5,5,6,7,7,6,5,5,6,7,7,6,5] .+ 1
Dtime_all_rata = datetime2rata.(Dtime_all)
dateticks = optimize_ticks(Dtime_all[1],Dtime_all[end])[1]


# Create Scene and 2D axis
scene, layout = layoutscene(10, 24, 10, resolution = (1500, 900))
ax = Array{LAxis}(undef,4)
sl = layout[10, 1:23] = LSlider(scene, range=1:n_all)

Text_date = layout[1,1:23] = LText(scene, text= lift(X->Dates.format(Dtime_all[X], "e, dd u yyyy"), sl.value), textsize=40)
# SWC + Precip time-series (bottom)
ax[3] = layout[8:9, 1:23] = LAxis(scene, ylabel = "Precip", yaxisposition = :right, xticklabelsvisible = false, xticksvisible = false, ylabelpadding = -10, xgridvisible = false, ygridvisible = false, yticklabelalign = (:left, :center))
barplot!(ax[3], Dtime_all_rata[1:end], Precip_daily[1:end], color = :blue)
scatter!(ax[3], lift(X-> [Point2f0(Dtime_all_rata[X], 0)], sl.value), marker = :vline, markersize = Vec2f0(0.5,5), color = :black)
xlims!(ax[3], (Dtime_all_rata[1], Dtime_all_rata[end])); ylims!(ax[3], (0, 2))

ax[1] = layout[8:9, 1:23] = LAxis(scene, ylabel="SWC", xlabel="Date", ylabelpadding = -25)
lines!(ax[1], Dtime_all_rata[1:end], SWC_daily_mean[1:end], color = :blue, linewidth = 2)
band!(ax[1], Dtime_all_rata[1:end], SWC_daily_mean[1:end] + SWC_daily_std[1:end], SWC_daily_mean[1:end] - SWC_daily_std[1:end], color = color = RGBAf0(0,0,1,0.3))
xlims!(ax[1], (Dtime_all_rata[1], Dtime_all_rata[end]));
ax[1].xticks[] = ManualTicks(datetime2rata.(dateticks) , Dates.format.(dateticks, "yyyy-mm-dd"))


# Tsoil + Rsoil time-series (bottom)
ax[2] = layout[6:7, 1:23] = LAxis(scene, ylabel="Ts", ylabelpadding = -25, xticklabelsvisible = false, xticksvisible = false)
lines!(ax[2], Dtime_all_rata[1:end], Tsoil_daily_mean[1:end], color = :red, linewidth = 2)
band!(ax[2], Dtime_all_rata[1:end], Tsoil_daily_mean[1:end] + Tsoil_daily_std[1:end], Tsoil_daily_mean[1:end] - Tsoil_daily_std[1:end], color = RGBAf0(1,0,0,0.3))
scatter!(ax[2], lift(X-> [Point2f0(Dtime_all_rata[X], 0)], sl.value), marker = :vline, markersize = Vec2f0(0.5,5), color = :black)
xlims!(ax[2], (Dtime_all_rata[1], Dtime_all_rata[end]));
ax[2].xticks[] = ManualTicks(datetime2rata.(dateticks) , Dates.format.(dateticks, "yyyy-mm-dd"))

ax[4] = layout[6:7, 1:23] = LAxis(scene, ylabel = "Rs", xticklabelsvisible = false, xticksvisible = false, xgridvisible = false, ygridvisible = false, yaxisposition = :right, ylabelpadding = -10, yticklabelalign = (:left, :center))
lines!(ax[4], Dtime_all_rata[1:end], Rsoil_daily_mean[1:end], color = :black)
xlims!(ax[4], (Dtime_all_rata[1], Dtime_all_rata[end]));

ax3D = Array{LRect}(undef,3)
cbar = Array{LColorbar}(undef,3)

ax3D[1] = layout[1:7, 1:8] = LRect(scene, visible = false);
scene3D_1 = Scene(scene, lift(IRect2D, ax3D[1].layoutnodes.computedbbox), camera = cam3d!, raw = false, show_axis = true);
surface!(scene3D_1, 0:7, 0:7, elev, color = lift(X-> GLMakie.vec2color(Matrix(sparse(x, y, SWC_daily[X,:])), Reverse(:lighttest), (0,1)), sl.value), shading = false, limits = Rect(0, 0, 0, 7, 7, 1.5));
x_or = [0,0,0]; Ylen = 7; Zlen = 1; Xlen = 7;
mesh!(scene3D_1, lift(X-> HyperRectangle(Vec3f0(x_or), Vec3f0(Xlen, Ylen, Wtable_daily[X])), sl.value) , color = RGBAf0(0,0,1,0.2));
cbar[1] = layout[2, 2:7] = LColorbar(scene, height = 20, limits = (0, 1), label = "SWC", colormap = :lighttest, vertical = false, labelpadding = -5);

ax3D[2] = layout[1:7, 9:16] = LRect(scene, visible = false);
scene3D_2 = Scene(scene, lift(IRect2D, ax3D[2].layoutnodes.computedbbox), camera = cam3d!, raw = false, show_axis = true);
surface!(scene3D_2, 0:7, 0:7, elev, color = lift(X-> GLMakie.vec2color(Matrix(sparse(x, y, Tsoil_daily[X,:])), Reverse(:lighttest), (0,1)), sl.value), shading = false, limits = Rect(0, 0, 0, 7, 7, 1.5));
x_or = [0,0,0]; Ylen = 7; Zlen = 1; Xlen = 7;
mesh!(scene3D_2, lift(X-> HyperRectangle(Vec3f0(x_or), Vec3f0(Xlen, Ylen, Wtable_daily[X])), sl.value) , color = RGBAf0(0,0,1,0.2));	
cbar[2] = layout[2, 10:15] = LColorbar(scene, height = 20, limits = (0, 1), label = "Tsoil", colormap = :lighttest, vertical = false, labelpadding = -5);

ax3D[3] = layout[1:7, 17:24] = LRect(scene, visible = false);
scene3D_3 = Scene(scene, lift(IRect2D, ax3D[3].layoutnodes.computedbbox), camera = cam3d!, raw = false, show_axis = true);
surface!(scene3D_3, 0:7, 0:7, elev, color = lift(X-> GLMakie.vec2color(Matrix(sparse(x, y, Rsoil_daily[X,:])), Reverse(:lighttest), (0,1)), sl.value), shading = false, limits = Rect(0, 0, 0, 7, 7, 1.5));
x_or = [0,0,0]; Ylen = 7; Zlen = 1; Xlen = 7;
mesh!(scene3D_3, lift(X-> HyperRectangle(Vec3f0(x_or), Vec3f0(Xlen, Ylen, Wtable_daily[X])), sl.value) , color = RGBAf0(0,0,1,0.2));	  
cbar[3] = layout[2, 18:23] = LColorbar(scene, height = 20, limits = (0, 1), label = "Rsoil", colormap = :lighttest, vertical = false, labelpadding = -5);


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


#ax[1] = layout[1:2, 1] = LAxis(scene, ylabel="y direction (m)", ylabelpadding = -25, xticklabelsvisible = false, xgridvisible = false, ygridvisible = false)
#ax[2] = layout[3:4, 1] = LAxis(scene, xlabel="x direction (m)", ylabel="y direction (m)", ylabelpadding = -25)
#ax[3] = layout[1, 2] = LAxis(scene, ylabel="SWC (m3 m-3)", ylabelpadding = -25, xticklabelsvisible = false)
#ax[4] = layout[2, 2] = LAxis(scene, ylabel="Tsoil (°C)", xlabel="Date", ylabelpadding = -25)
#sl = layout[5, 1:2] = LSlider(scene, range=1:n_all)


# Add plots inside 2D axis

## Axis top-left, scatter
# Makie.scatter!(ax[1], x, y, color = lift(X->SWC_daily[X,:], sl.value), colormap = Reverse(:lighttest), markersize = 20 * AbstractPlotting.px)

## Axis bottom-left, heatmap
# Makie.heatmap!(ax[2], x, y, lift(X-> Matrix(sparse(x, y, SWC_daily[X,:])), sl.value), interpolate = true, colormap = Reverse(:lighttest), show_axis = false)
# ylims!(ax[2], (1,8)); xlims!(ax[2], (1,8))

## Axis top-right 1
# Makie.lines!(ax[3], Dtime_all_rata[1:n_all-1], SWC_daily_mean[1:n_all-1], color = :black)
# Makie.band!(ax[3], Dtime_all_rata[1:n_all-1], SWC_daily_mean[1:n_all-1] + SWC_daily_std[1:n_all-1], SWC_daily_mean[1:n_all-1] - SWC_daily_std[1:n_all-1], color = :blue)
# ax[3].xticks[] = ManualTicks(datetime2rata.(dateticks) , Dates.format.(dateticks, "yyyy-mm-dd"))

## Axis top-right 2
# Makie.lines!(ax[4], Dtime_all_rata[1:n_all-1], Tsoil_daily_mean[1:n_all-1], color = :black)
# Makie.band!(ax[4], Dtime_all_rata[1:n_all-1], Tsoil_daily_mean[1:n_all-1] + Tsoil_daily_std[1:n_all-1], Tsoil_daily_mean[1:n_all-1] - Tsoil_daily_std[1:n_all-1], color = :green)
# ax[4].xticks[] = ManualTicks(datetime2rata.(dateticks) , Dates.format.(dateticks, "yyyy-mm-dd"))


## Create 3D axis in bottom-right
# dummyrect = layout[3:4, 2] = LRect(scene, visible = false)
# scene3d = Scene(scene, lift(IRect2D, dummyrect.layoutnodes.computedbbox), camera = cam3d!, raw = false)

## Add surface plot to that bottom-right 3D axis
# Makie.surface!(scene3d, 0:7, 0:7, elev, color = lift(X-> GLMakie.vec2color(Matrix(sparse(x, y, SWC_daily[X,:])), Reverse(:lighttest), (0,1)), sl.value), shading = false, limits = Rect(0, 0, 0, 7, 7, 2))

## Add rectangle plot to that bottom-right 3D axis
# x_or = [0,0,0]; Ylen = 7; Zlen = 1; Xlen = 7;
# rectangle = Node(HyperRectangle(Vec3f0(x_or), Vec3f0(Xlen, Ylen, Zlen)))
# mesh!(scene3d, rectangle, color = RGBAf0(0,0,1,0.5))

## Show scene
# scene







