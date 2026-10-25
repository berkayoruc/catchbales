-- Rive 3D Cozy Environment Props Script
-- Manages scrolling Low-Poly Trees, 3D Wooden Fences, and Golden Wheat Fields
-- along both sides of the dirt path in 9:16 isometric perspective.

local EnvironmentProps = {
  scrollSpeed = 3.4,
  loopLengthZ = 16.0,
  fenceOffsetX = 2.22,
  treeOffsetX = 3.05,
  wheatFieldInnerX = 2.55,
  wheatFieldOuterX = 7.50,
}

function EnvironmentProps:update(dt, propNodes, time)
  for i, node in ipairs(propNodes or {}) do
    node.z = node.z - (self.scrollSpeed * dt)
    if node.z < -6.0 then
      node.z = node.z + self.loopLengthZ
    end
  end
end

return EnvironmentProps
