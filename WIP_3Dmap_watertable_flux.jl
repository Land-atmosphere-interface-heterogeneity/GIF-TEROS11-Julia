using Images, Makie, Colors, GLMakie, GeometryTypes

# 3D heatmap: 
color_test2 = GLMakie.vec2color(rand(8,8), Reverse(:lighttest), (0.3,0.5))
elev = Node(rand(8,8).+1)
s = surface(0:7,0:7,elev, color = color_test2, shading = false,
resolution = (500,500))
# Add blue cube:
x = [0,0,0]; Ylen = 7; Zlen = 1; Xlen = 7;
rectangle = HyperRectangle(Vec3f0(x), Vec3f0(Xlen, Ylen, Zlen))
mesh!(s,rectangle, color = RGBAf0(0,0,1,0.5))
# Add rectangles bar as fluxes of CO2:
meshscatter!(s,
     0:7,0:7,elev,
     marker = Rect3D(Vec3f0(0), Vec3f0(1)),
     markersize = Vec3f0.(0.2, 0.2, 0.3),
	 #raw = true,
	 color = RGBAf0(0,0,0,0.2),
     #colormap = [(:black, 0.0), (:skyblue2, 0.6)],
     #shading = true,
 )
# To fix:
# elevation of rectangles
# markersize of individual rectangle (all the same currently)
# Need more rectangles (linear interpolation?)


# simple code to troubleshoot elevation
coord = collect(0:7).-0.2; coord[1] = 0
elev = rand(8,8).+1
Height = Node(elev)
s = surface(0:7,0:7,Height, shading = false, resolution = (500,500), limits = Rect(0, 0, 0, 7, 7, 2))
meshscatter!(s, coord, coord, Height, marker = Rect3D(Vec3f0(0), Vec3f0(1)),
markersize = Vec3f0.(0.2, 0.2, 0.3), color = RGBAf0(0,0,0,0.2))
axis = s[Axis] # get the axis object from the scene
#axis[:grid][:linecolor] = ((:red, 0.5), (:blue, 0.5))
#axis[:names][:textcolor] = ((:red, 1.0), (:blue, 1.0))
axis[:names][:axisnames] = ("Coordinate x (m)","Coordinate y (m)","Elevation (m)")
axis[:names][:textsize] = (20.0,20.0,20.0)
axis[:ticks][:textsize] = (20.0,20.0,20.0)
axis[:ticks][:ranges_labels] = (([1.0,3.0,5.0,7.0], [1.0,3.0,5.0,7.0], [0.0,1.0, 2.0]), (["75","50","25","0"], ["75","50","25","0"], ["0", "1", "2"]))

# Heatmap on an image
cd("C:\\Users\\arenchon\\Documents\\GitHub\\GIF-TEROS11-Julia")
img = load("Input\\484site.PNG")
scene = Scene(resolution = (600,400))
heatmap!(scene, rand(1000,1000))
p = image!(scene,RGBAf0.(color.(img), 0.7))

# 3D surface, with user defined colors (need to set it to SWC), and colorlegend
# + a volume representing the water table
## on a black background

s = surface(collect(1:8),collect(1:8),rand(8,8).*1.5,color = RGBAf0.(color.(img), 0.7), shading = false) #, backgroundcolor = :black)
#s[Axis].names.textcolor = :gray
#ls = colorlegend(s[end], raw = true, camera = campixel!) #, backgroundcolor = :black)
#scene_final = vbox(s, ls)


# plot heatmap on surface
test = rand(8,8)
C(g::ColorGradient) = RGB[g[z] for z=test]
g = :lighttest
color_test = cgrad(g) |> C;
s = surface(collect(1:8),collect(1:8),rand(8,8), color = color_test)

# cube is: x = 0-8, y = 0-1, z = 0-1
# surface is: x = 1-8, y = 1-8, z = 1-2 

# Plotting a cube volume (for the water table)
using Makie, GeometryTypes
x = Vec3f0(0); baselen = 1f0; dirlen = 1f0
rectangle = HyperRectangle(Vec3f0(x), Vec3f0(dirlen, baselen, baselen))
mesh(rectangle, color = RGBAf0(0,0,1,0.5))

# subscene 

# using Images; using Makie
# img = load("Input\\484site.PNG")
# scene = Scene(resolution = (500,500))
# heatmap!(scene, rand(20,20), show_axis = false)
# subscene = Scene(scene, IRect(100, 100, 300, 300))
# image!(subscene,img, alpha = 0.2, transparency = true)
# scene

# Copy image on a surface
s = surface(1:8,1:8,rand(8,8),color = RGBAf0.(color.(img)))


using Plots
clibrary(:misc)
C(g::ColorGradient) = RGB[g[z] for z=collect(0.37:0.01:0.45)]
g = :lighttest


# USING NODES
scene = Scene(resolution = (500,500))
xyz = Node(rand(8, 8))
surface!(scene, xyz, shading = false)
xyz[] = rand(8, 8) # this updates the node and therefore the buffers on the gpu


#Adjusting scene limits

 x = range(0, stop = 10, length = 40)
 y = x
 # specify the scene limits, note that the arguments for FRect are
 #    x_min, y_min, x_dist, y_dist,
 #    therefore, the maximum x and y limits are then x_min + x_dist and y_min + y_dist
 
 limits = FRect(-5, -10, 20, 30)

 scene = lines(x, y, color = :blue, limits = limits)

# Axis naming
axis = scene[Axis] # get the axis object from the scene
 axis.grid.linecolor = ((:red, 0.5), (:blue, 0.5))
 axis.names.textcolor = ((:red, 1.0), (:blue, 1.0))
 axis.names.axisnames = ("x", "y = cos(x)")
 scene

# Layouting
https://simondanisch.github.io/ReferenceImages/gallery/layouting/index.html
