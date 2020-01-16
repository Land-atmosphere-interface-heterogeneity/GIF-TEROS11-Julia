using Images, Makie, Colors

# Heatmap on an image
cd("C:\\Users\\arenchon\\Documents\\GitHub\\GIF-TEROS11-Julia")
img = load("Input\\484site.PNG")
scene = Scene(resolution = (600,400))
heatmap!(scene, rand(1000,1000))
p = image!(scene,RGBAf0.(color.(img), 0.7))

# 3D surface, with user defined colors (need to set it to SWC), and colorlegend
# + a volume representing the water table
## on a black background

s = surface(collect(1:8),collect(1:8),rand(8,8).*1.5,color = RGBAf0.(color.(img), 0.7)) #, backgroundcolor = :black)
#s[Axis].names.textcolor = :gray
#ls = colorlegend(s[end], raw = true, camera = campixel!) #, backgroundcolor = :black)
#scene_final = vbox(s, ls)


# plot heatmap on surface
test = rand(8,8)
C(g::ColorGradient) = RGB[g[z] for z=test]
g = :lighttest
color_test = cgrad(g) |> C;
s = surface(collect(1:8),collect(1:8),rand(8,8), color = color_test)

# Other (better, simpler) code for the same thing: 
using GLMakie
color_test2 = GLMakie.vec2color(rand(8,8), :lighttest, (0.3,0.5))
s = surface(collect(1:8),collect(1:8),rand(8,8), color = color_test)

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
