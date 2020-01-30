using JSServe, WGLMakie, AbstractPlotting, JSServe.DOM
function test_handler(session, req)
    scene = scatter([1, 2, 3, 4], resolution=(500,500), color=:red)
    return DOM.div(scene)
end
app = JSServe.Application(test_handler, "0.0.0.0", 8083)
# then open URL http://MYIP:8083/ in my browser
# then the same http://MYIP:8083/ in someone else browser in same network 
# # To get my IP, type ipconfig in command prompt and look for IPv4
