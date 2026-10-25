-- Rive 3D Lighting & Soft Shadow Script (Cozy Low-Poly Farm Setup)
-- Warm Sun Key Light + Pastel Fill Light + Directional Soft Ground Shadows

local LightingController = {
  lightAngle = 38.0,
  lightHeight = 58.0,

  -- Warm Sun Key Light (#FFE082)
  keyLightColor = { r = 1.0, g = 0.88, b = 0.51 },
  keyLightIntensity = 1.25,
  keyLightDirection = { x = 0.42, y = -0.82, z = 0.38 },

  -- Cozy Pasture Fill & Ambient Light (#D8F3DC)
  fillLightColor = { r = 0.85, g = 0.95, b = 0.86 },
  fillLightIntensity = 0.55,
  ambientColor = { r = 0.96, g = 0.93, b = 0.82 },
  ambientIntensity = 0.48,

  -- Soft Shadows
  shadowDarkness = 0.34,
  shadowSoftness = 6.0,
}

function LightingController:applyToScene(scene)
  if not scene then return end
  scene.keyLight.color = self.keyLightColor
  scene.keyLight.intensity = self.keyLightIntensity
  scene.keyLight.direction = self.keyLightDirection
  scene.shadows.enabled = true
  scene.shadows.darkness = self.shadowDarkness
  scene.shadows.softness = self.shadowSoftness
end

return LightingController
