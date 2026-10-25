-- Rive 3D Camera Control Script (9:16 Vertical Mobile Isometric View)
-- Configured per visual specification:
--   Pitch: -55.0 degrees (3rd-person isometric angle showing wagon walls & vertical stack depth)
--   FOV: 45.0 degrees
--   Yaw: 0.0 degrees

local CameraController = {
  pitch = -55.0,       -- Range: -50.0 to -60.0 degrees
  yaw = 0.0,           -- Aligned with dirt road (+Z)
  fov = 45.0,          -- Perspective field of view
  nearClip = 0.1,
  farClip = 100.0,
  cameraPosition = { x = 0.0, y = 9.2, z = -9.0 },
  targetOffset = { x = 0.0, y = 0.6, z = -1.5 },
}

function CameraController:init(artboard)
  self.pitchInput = artboard:input("CameraPitch") or -55.0
  self.fovInput = artboard:input("CameraFOV") or 45.0
end

function CameraController:update(dt, cameraNode)
  local degToRad = math.pi / 180.0
  local pitchRad = self.pitch * degToRad
  local yawRad = self.yaw * degToRad

  if cameraNode then
    cameraNode.rotationX = pitchRad
    cameraNode.rotationY = yawRad
    cameraNode.fov = self.fov
    cameraNode.position = self.cameraPosition
  end
end

return CameraController
