using JSServe, WGLMakie, AbstractPlotting, JSServe.DOM
function test_handler(session, req)
    scene = scatter([1, 2, 3, 4], resolution=(500,500), color=:red)
    return DOM.div(scene)
end
app = JSServe.Application(test_handler, "127.0.0.1", 8083)
# then open URL http://127.0.0.1:8083/