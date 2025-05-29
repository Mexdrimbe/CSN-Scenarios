system.setScriptName("~h~~t4~CSN ~t6~Scenarios")

-- made by CSN. enjoy!

-- constants
local MALE_SECTION = menu.addSubmenu("self", "~h~~t3~Male", "The male section, scenarios for males.")
local FEMALE_SECTION = menu.addSubmenu("self", "~h~~t5~Female", "The female section, scenarios for females.")
local DEFAULT_TEXT_DUR = (5000) -- it matches the notify dur.
local CAMERA_HASH = natives.misc_getHashKey("DEFAULT_SCRIPTED_CAMERA")
local CAMERA_FADE_MS = (4000)
local MAX_OBJECTS = (50)

local settings = {
   spawnedObjects = {}, 
   object_names = {
      grindStone = {name="p_grindingwheel01x"},
      stumpWood = {name="p_stumpwoodsplit02x"},
      waterpump = {name="p_waterpump01x"},
      toolshed = {name="p_toolshed02x"},
      bench15 = {name="p_bench15x"},
      chairrocking02 = {name="p_chairrocking02x"},
   }, 
   types = {
      strict = "spawned_strict"
   }, 
   active_scenario_object = nil,
   useCustomCam = false, 
   ticks = {
      cameraMoveControls = nil 
   },
   useSafety = (true) 
}

local rootContainers = {
    text=natives.databinding_databindingAddDataContainerFromPath("", "BountyCash"), 
    icon=natives.databinding_databindingAddDataContainerFromPath("", "PassiveIcon")
}

---@param toggle boolean
---@param text string 
---@return nil 
local function toggleText(toggle, text) 
    if not text then 
        text = ""
    end
    if not toggle then 
        natives.databinding_databindingAddDataBool(rootContainers.text, "State", false)
        natives.databinding_databindingAddDataString(rootContainers.text, "Text", "")
        -- remove passive icon 
        natives.databinding_databindingAddDataBool(rootContainers.icon, "isVisible", false)
        return 
    end
    natives.databinding_databindingAddDataBool(rootContainers.text, "State", true)
    natives.databinding_databindingAddDataString(rootContainers.text, "Text", text)
    -- set passive icon 
    natives.databinding_databindingAddDataBool(rootContainers.icon, "isVisible", true)
    natives.databinding_databindingAddDataInt(rootContainers.icon, "setState", 1)
end

local _controls = {
  ["Button W"] = { key = 0x57, pressed = false },
  ["Button A"] = { key = 0x41, pressed = false },
  ["Button S"] = { key = 0x53, pressed = false },
  ["Button D"] = { key = 0x44, pressed = false },
  ["Button V"] = { key = 0x56, pressed = false },
}

---@alias KeyControl { key: integer, pressed: boolean }
---@param callback fun(ctrls: table<string, KeyControl>): nil
---@return nil 
local function handle_key_event(callback)
  if not callback then
    if settings.ticks.cameraMoveControls then
      system.unregisterTick(settings.ticks.cameraMoveControls)
      settings.ticks.cameraMoveControls = nil
    end
    return
  end
  if settings.ticks.cameraMoveControls then
    system.unregisterTick(settings.ticks.cameraMoveControls)
  end
  settings.ticks.cameraMoveControls = system.registerTick(function()
    for name, data in pairs(_controls) do
      data.pressed = utility.isKeyPressed(true, data.key)
    end
    callback(_controls)
  end)
end

local camera
local camX, camY, camZ
local rotX, rotY, rotZ
local FOV 
local zoomDir = -1

-- <number>->float excepted
---@param toggle boolean
---@param x number -- float expected
---@param y number -- float expected
---@param z number -- float expected
---@param rx number -- float expected
---@param ry number -- float expected
---@param rz number -- float expected
---@param fov number -- float expected
---@return nil 
local function toggleCamera(toggle, x, y, z, rx, ry, rz, fov)
  if toggle then
   toggleText(true, "(WASD) To Move, (V) to change FOV")
    camX, camY, camZ = x, y, z
    rotX, rotY, rotZ = rx, ry, rz
    FOV = fov 
    camera = natives.cam_createCameraWithParams(
      CAMERA_HASH, camX, camY, camZ, rotX, rotY, rotZ, fov, false, 1
    )
    natives.cam_setCamActive(camera, true)
    natives.cam_renderScriptCams(true, true, 1000, true, true, 0)
    handle_key_event(function(controls)
      local speed = 0.15  
      if     controls["Button W"].pressed then camY = camY + speed
      elseif controls["Button S"].pressed then camY = camY - speed end
      if     controls["Button A"].pressed then camX = camX - speed
      elseif controls["Button D"].pressed then camX = camX + speed end
      if controls["Button V"].pressed then
         FOV = FOV + zoomDir * 0.5
         if FOV <= 20 then
            FOV = 20
            zoomDir = 1
         elseif FOV >= 110 then
            FOV = 110
            zoomDir = -1
            end
      natives.cam_setCamFov(camera, FOV)
   end
      natives.cam_setCamCoord(camera, camX, camY, camZ)
      natives.cam_setCamRot(camera, rotX, rotY, rotZ)
    end)

    return
  end
  if camera then
    natives.cam_doScreenFadeOut(CAMERA_FADE_MS)
    system.yield(CAMERA_FADE_MS)
    natives.cam_renderScriptCams(false, false, 0, true, true, 0)
    natives.cam_destroyCam(camera, false)
    natives.cam_doScreenFadeIn(CAMERA_FADE_MS)
    camera = nil
    toggleText(false)
  end
  handle_key_event(nil)
end

---@param ped integer 
---@return boolean isMale 
local is_male = function(ped)
   return natives.invoke(0x6D9F5FAA7488BA46, 'bool', ped)
end

---@param obj number | string 
---@return nil 
local function spawnObject(obj)
   if type(obj) == "string" then 
      obj = natives.misc_getHashKey(obj)
   end
   if #settings.spawnedObjects > MAX_OBJECTS then 
      notifications.alertDanger("Limit", "You've reached the limit of spawned objects. Please clear the entity pool, before proceeding")
      return 
   end
   local player_x, player_y, player_z = player.getLocalPedCoords()
   local object = spawner.spawnObject(obj, player_x, player_y, player_z, true) 
   system.yield(90) 
   if object or natives.entity_doesEntityExist(object) then 
      natives.object_placeObjectOnGroundProperly(object, true)
      system.yield(50)
      table.insert(settings.spawnedObjects, object)
      notifications.alertInfo("Spawner", "The object spawned successfully.")
      return 
   end
   notifications.alertDanger("Failed", "Failed to spawn object")
end

---@return nil 
local function delete_objects()
   if #settings.spawnedObjects > 0 then 
      toggleCamera(false)
      natives.task_clearPedTasksImmediately(player.getLocalPed(), true, true)
      for _, obj in ipairs(settings.spawnedObjects) do 
         spawner.deleteObject(obj) 
      end
      settings.spawnedObjects = {}
      return 
   end
   notifications.alertDanger("Spawner", "There is no objects to delete.")
end

---@param type string 
---@return nil 
local function _play_scenario_on_nearest_spawned_object(type) 
   local PlayerPed = player.getLocalPed()
   if type == settings.types.strict then 
      if #settings.spawnedObjects <= 0 then 
         notifications.alertDanger("Failed", "You have no spawned objects.")
         return 
      end
      for _, obj in ipairs(settings.spawnedObjects) do 
         settings.active_scenario_object = obj 
      end
      local object_x, object_y, object_z = natives.entity_getEntityCoords(settings.active_scenario_object, false, true)
      natives.entity_setEntityCoords(PlayerPed, object_x, object_y, object_z, false, false, false, false)
      system.yield(100)
      local player_x, player_y, player_z = player.getLocalPedCoords()
      natives.task_taskUseNearestScenarioToCoordWarp(PlayerPed, player_x, player_y, player_z, 5, -1, true, false, false, false)
      return 
   end
end

---@param gender_block string 
---@return nil 
local function gender_control_message(gender_block)
   if gender_block == "male" then 
      notifications.alertDanger("Gender", "This scenario is for ~t5~Males ~t3~Only.")
      toggleText(true, "You have to be a male in order to play this scenario either pick an male ped or change to female section")
      system.yield(DEFAULT_TEXT_DUR)
      toggleText(false) 
      return 
   end
   notifications.alertDanger("Gender", "This scenario is for ~t5~Females ~t3~Only.")
   toggleText(true, "You have to be a female in order to play this scenario either pick an female ped or change to male section")
   system.yield(DEFAULT_TEXT_DUR)
   toggleText(false)
end

---@param name number | string
---@param type string  
---@return nil 
local apply_scenario = function(name, type) 
   spawnObject(name)
   system.yield(500)
   if settings.useCustomCam then 
      local player_x, player_y, player_z = player.getLocalPedCoords()
      toggleCamera(true, player_x, player_y - 2, player_z, 0.0, 0.0, 0.0, 60)
   end 
   _play_scenario_on_nearest_spawned_object(type) 
end

local female_section_scenarios = {
   ["Use StumpWood"] = {name = (settings.object_names.stumpWood.name), type = (settings.types.strict), control_message = ("female")},
   ["Use Water Pump"] = {name = (settings.object_names.waterpump.name), type = (settings.types.strict), control_message = ("female")},
   ["Use Bench"] = {name = (settings.object_names.bench15.name), type = (settings.types.strict), control_message = ("female")},
   ["Use Chair"] = {name = (settings.object_names.chairrocking02.name), type = (settings.types.strict), control_message = ("female")}
}

local male_section_scenarios = {
   ["Use StumpWood"] = {name = (settings.object_names.stumpWood.name), type = (settings.types.strict), control_message = ("male")},
   ["Use GrindStone"] = {name = (settings.object_names.grindStone.name), type = (settings.types.strict), control_message = ("male")},
   ["Use Water Pump"] = {name = (settings.object_names.waterpump.name), type = (settings.types.strict), control_message = ("male")},
   ["Use ToolShed"] = {name = (settings.object_names.toolshed.name), type = (settings.types.strict), control_message = ("male")},
   ["Use Bench"] = {name = (settings.object_names.bench15.name), type = (settings.types.strict), control_message = ("male")},
   ["Use Chair"] = {name = (settings.object_names.chairrocking02.name), type = (settings.types.strict), control_message = ("male")},
}

-- generate female buttons. 
for name, data in pairs(female_section_scenarios) do 
   local btn_name = (name) 
   local object_name = (data.name)
   local type = (data.type)
   local control_message = (data.control_message)
   local _section_id = (FEMALE_SECTION)
   local playerPed = player.getLocalPed()

   menu.addButton(_section_id, "~t5~"..btn_name, "~t5~play: " .. btn_name .. " Scenario!", function()
      if is_male(playerPed) then 
         gender_control_message(control_message)
         return 
      end
      apply_scenario(object_name, type)
   end)
end

-- generate male buttons.
for name, data in pairs(male_section_scenarios) do 
   local btn_name = (name) 
   local object_name = (data.name)
   local type = (data.type)
   local control_message = (data.control_message)
   local _section_id = (MALE_SECTION)
   local playerPed = player.getLocalPed()

   menu.addButton(_section_id, "~t5~"..btn_name, "~t5~play: " .. btn_name .. " Scenario!", function()
      if not is_male(playerPed) then 
         gender_control_message(control_message)
         return 
      end
      apply_scenario(object_name, type)
   end)
end

menu.addToggleButton("self", "Use Custom Camera", "...", false, function(toggle)
   if not toggle then 
      settings.useCustomCam = false 
      if camera then 
         toggleCamera(false)
      end
      return settings.useCustomCam
   end
   settings.useCustomCam = true 
end)

menu.addButton(MALE_SECTION, "~t8~Delete & Stop", "...", delete_objects)
menu.addButton(FEMALE_SECTION, "~t8~Delete & Stop", "...", delete_objects)


--- safety
if settings.useSafety then 
   ---@param callback string 
   ---@return string callback  
   local repetitive_user_input = function(callback)
      keyboard.getInput("", function(result)
         callback(result)
      end)	
   end
   ---@return nil 
   local leave_current_session = function()
      natives.network_networkSessionLeaveSession()
   end

   menu.addButton("self", "~t8~Panic Button", "This will disable all the ticks made by the script. Also clean the rest up.", function()
      local safety_coords = {x=-368.92419433594, y=796.81695556641, z=116.19823455811, h=268.15090942383}
      local playerPed = player.getLocalPed()
      if settings.ticks.cameraMoveControls then 
         system.unregisterTick(settings.ticks.cameraMoveControls)
      end
      if camera then 
         toggleCamera(false) 
         settings.useCustomCam = false 
      end
      delete_objects() -- this already comes with a 'end task' -- also this function is already checking for us, if there is any object to delete.
      system.yield(3000)
      natives.entity_setEntityCoordsAndHeading(playerPed, safety_coords.x, safety_coords.y, safety_coords.z, safety_coords.h, false, false, false)
      toggleText(true, "y = leave_session, n = stay_in_session")
      repetitive_user_input(function(result)
         if not result then 
            notifications.alertDanger("Choice:", "You will not leave the session.") 
            toggleText(false)
         end
         if result == "n" then
            notifications.alertDanger("Choice:", "You will not leave the session.") 
            toggleText(false)
            return 
         else 
            toggleText(false)
            leave_current_session()
         end
      end)
   end)
end