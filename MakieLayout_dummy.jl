using Makie, MakieLayout, Dates, GLMakie, GeometryTypes, SparseArrays
using PlotUtils: optimize_ticks


# Dummy data
n_all = 100
SWC_daily = rand(n_all, 64); SWC_daily_mean = rand(n_all, 1); SWC_daily_std = rand(n_all, 1)
Tsoil_daily = rand(n_all, 64); Tsoil_daily_mean = rand(n_all, 1); Tsoil_daily_std = rand(n_all, 1)
Dtime_all = collect(Date(2019, 01, 01):Day(1):Date(2019, 01, 01)+Day(n_all-1))
elev = rand(8,8).+1
x = [0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,6,7,7,7,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,6,7,7,7] .+ 1
y = [0,1,2,2,1,0,0,1,2,2,1,0,0,1,2,2,1,0,0,1,2,2,1,0,3,4,4,3,4,3,3,4,4,3,3,4,4,3,4,3,5,6,7,7,6,5,5,6,7,7,6,5,5,6,7,7,6,5,5,6,7,7,6,5] .+ 1
Dtime_all_rata = datetime2rata.(Dtime_all)

# Create Scene and 2D axis
scene, layout = layoutscene(5, 2, 10, resolution = (1100, 900))
ax = Array{LAxis}(undef,4)
ax[1] = layout[1:2, 1] = LAxis(scene, ylabel="y direction (m)", ylabelpadding = -25, xticklabelsvisible = false, xgridvisible = false, ygridvisible = false)
ax[2] = layout[3:4, 1] = LAxis(scene, xlabel="x direction (m)", ylabel="y direction (m)", ylabelpadding = -25)
ax[3] = layout[1, 2] = LAxis(scene, ylabel="SWC (m3 m-3)", ylabelpadding = -25, xticklabelsvisible = false)
ax[4] = layout[2, 2] = LAxis(scene, ylabel="Tsoil (°C)", xlabel="Date", ylabelpadding = -25)
sl = layout[5, 1:2] = LSlider(scene, range=1:n_all)
dateticks = optimize_ticks(Dtime_all[1],Dtime_all[end])[1]

# Add plots inside 2D axis

# Axis top-left, scatter
Makie.scatter!(ax[1], x, y, color = lift(X->SWC_daily[X,:], sl.value), colormap = Reverse(:lighttest), markersize = 20 * AbstractPlotting.px)

# Axis bottom-left, heatmap
Makie.heatmap!(ax[2], x, y, lift(X-> Matrix(sparse(x, y, SWC_daily[X,:])), sl.value), interpolate = true, colormap = Reverse(:lighttest), show_axis = false)
ylims!(ax[2], (1,8)); xlims!(ax[2], (1,8))

# Axis top-right 1
Makie.lines!(ax[3], Dtime_all_rata[1:n_all-1], SWC_daily_mean[1:n_all-1], color = :black)
Makie.band!(ax[3], Dtime_all_rata[1:n_all-1], SWC_daily_mean[1:n_all-1] + SWC_daily_std[1:n_all-1], SWC_daily_mean[1:n_all-1] - SWC_daily_std[1:n_all-1], color = :blue)
ax[3].xticks[] = ManualTicks(datetime2rata.(dateticks) , Dates.format.(dateticks, "yyyy-mm-dd"))

# Axis top-right 2
Makie.lines!(ax[4], Dtime_all_rata[1:n_all-1], Tsoil_daily_mean[1:n_all-1], color = :black)
Makie.band!(ax[4], Dtime_all_rata[1:n_all-1], Tsoil_daily_mean[1:n_all-1] + Tsoil_daily_std[1:n_all-1], Tsoil_daily_mean[1:n_all-1] - Tsoil_daily_std[1:n_all-1], color = :green)
ax[4].xticks[] = ManualTicks(datetime2rata.(dateticks) , Dates.format.(dateticks, "yyyy-mm-dd"))


# Create 3D axis in bottom-right
dummyrect = layout[3:4, 2] = LRect(scene, visible = false)
scene3d = Scene(scene, lift(IRect2D, dummyrect.layoutnodes.computedbbox), camera = cam3d!, raw = false)

# Add surface plot to that bottom-right 3D axis
Makie.surface!(scene3d, 0:7, 0:7, elev, color = lift(X-> GLMakie.vec2color(Matrix(sparse(x, y, SWC_daily[X,:])), Reverse(:lighttest), (0,1)), sl.value), shading = false, limits = Rect(0, 0, 0, 7, 7, 2))

# Add rectangle plot to that bottom-right 3D axis
x_or = [0,0,0]; Ylen = 7; Zlen = 1; Xlen = 7;
rectangle = Node(HyperRectangle(Vec3f0(x_or), Vec3f0(Xlen, Ylen, Zlen)))
mesh!(scene3d, rectangle, color = RGBAf0(0,0,1,0.5))

# Show scene
scene
















