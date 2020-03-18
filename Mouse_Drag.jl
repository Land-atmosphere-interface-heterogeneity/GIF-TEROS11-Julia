# Julius Krumbiegel  
# Minimal example for dragging in a scene:

scene, layout = layoutscene()
ax = layout[1, 1] = LAxis(scene)
x = Node(1.0)
lines!(ax, @lift(Point2f0[($x, 0), ($x, 1)]))
xlims!(ax, 0, 10)
ylims!(ax, 0, 1)
mousestate = MakieLayout.addmousestate!(ax.scene)
onmouseleftdrag(mousestate) do state
    x[] = state.pos[1]
end
scene