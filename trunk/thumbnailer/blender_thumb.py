import Blender
from Blender import *
from Blender.Scene import *

print "Hello World: ", Blender

scn = Scene.GetCurrent()

# Remove all lamps
for obj in scn.getChildren():
    if obj.getType() == 'Lamp':
        scn.unlink(obj)

c = Camera.New('ortho')     # create new ortho camera data
c.lens = 35.0               # set lens value
c.setType("persp")
ob = Object.New('Camera')   # make camera object
ob.link(c)                  # link camera data with this object
ob.setLocation(10, -10, 14)
ob.setEuler([3.1415927/4.0, 0, 3.1415927/4.0])
scn.link(ob)                # link object into scene
scn.setCurrentCamera(ob)

l = Lamp.New('Lamp')            # create new 'Spot' lamp data
l.setEnergy(2.0)
#  l.setMode('square', 'shadow')   # set these two lamp mode flags
ob = Object.New('Lamp')         # create new lamp object
ob.link(l)
ob.setEuler([3.1415927/4.0, 0, 3.1415927/4.0])
ob.setLocation(10, -10, 14)
scn.link(ob)

# Rendering parameters
context = scn.getRenderingContext()
context.enableRGBAColor()
context.setImageType(Render.PNG)
context.setRenderWinSize(100)
context.imageSizeX(512)
context.imageSizeY(512)
context.enableOversampling(1)
context.setOversamplingLevel(8)
context.setRenderPath("/tmp/out/")
context.startFrame(1)
context.endFrame(1)

Blender.Save("/tmp/out/tmp.blend", 1)

# context.renderAnim()
# Blender.Quit()

# EOF #
