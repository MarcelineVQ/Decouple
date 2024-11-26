-- By and for Weird Vibes of Turtle WoW

local _G = _G or getfenv()

-- Ensure the new timer facility is available. But would/should this work on the Glue screens?
local has_unitxp3 = pcall(UnitXP, "inSight", "player", "player") and true or false

if not has_unitxp3 then
  StaticPopupDialogs["NO_UNITXP3"] = {
    text = (c("Decouple",color.yellow)..c(" requires the UnitXP SP3 dll to operate.",color.red)),
    button1 = TEXT(OKAY),
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    showAlert = 1,
  }

  StaticPopup_Show("NO_UNITXP3")
  return
end

-- global addon update rate
local update_rate = 1 / 60 * 1000 -- 60 fps update rate

-- update rate special cases
local special_cases = {
  UIParent         = 1/30 * 1000,
  WorldFrame       = 1/30 * 1000,
  SuperAPI_Castlib = 1/30 * 1000, -- this one runs heavy for some reason
}

-- store timers and callbacks
local TimerManager = {}

-- Function to handle the replacement of OnUpdate
local function replaceOnUpdateLogic(frame, originalOnUpdate, rate)
  -- Remove the old OnUpdate script
  if frame:GetScript("OnUpdate") then frame:SetScript("OnUpdate", nil) end

  -- default to update_rate if none provided
  local rate = rate or update_rate
  -- Create a unique key for the frame
  local frameID = tostring(frame)

  -- simulate elapsed time (arg1)
  local lastUpdateTime = GetTime()

  -- Define a global callback function for this frame
  local globalCallbackName = "UnitXP_Callback_" .. frameID
  _G[globalCallbackName] = function(timerID)
    if TimerManager[frameID] == timerID then
      -- Calculate elapsed time since the last update
      local currentTime = GetTime()
      local elapsedTime = currentTime - lastUpdateTime
      lastUpdateTime = currentTime

      -- 1.12 uses globals, so set them before the call
      local oldThis = _G.this
      local oldArg1 = _G.arg1
      _G.this = frame
      _G.arg1 = elapsedTime
      pcall(originalOnUpdate)
       -- Restore the previous value, probably not neccesary, depends how the backend timer lib changes over time
      _G.this = oldThis
      _G.arg1 = oldArg1
    end
  end

  -- Arm the timer and store the timer ID
  local timerID
  if frame:IsVisible() then
    timerID = UnitXP("timer", "arm", 0, rate, globalCallbackName)
    TimerManager[frameID] = timerID
  end

  local original_OnHide = frame:GetScript("OnHide")
  -- Clean up on frame hide
  frame:SetScript("OnHide", function()
    if TimerManager[frameID] then
      UnitXP("timer", "disarm", TimerManager[frameID])
      TimerManager[frameID] = nil
    end
    if original_OnHide then original_OnHide() end
  end)

  local original_OnShow = frame:GetScript("OnShow")
  -- Re-arm the timer on frame show
  frame:SetScript("OnShow", function()
    if not TimerManager[frameID] then
      timerID = UnitXP("timer", "arm", 0, rate, globalCallbackName)
      TimerManager[frameID] = timerID
      lastUpdateTime = GetTime() -- Reset the update time
    end
    if original_OnShow then original_OnShow() end
  end)
end

local function replaceFrameOnUpdate(frame,rate)
  local originalOnUpdate = frame:GetScript("OnUpdate")
  if originalOnUpdate then
    replaceOnUpdateLogic(frame,originalOnUpdate,rate)
  end
end

local function replaceAllFrameOnUpdate(rate)
  local frame = EnumerateFrames()
  while frame do
    if frame:GetScript("OnUpdate") then
        replaceFrameOnUpdate(frame,rate)
    end
    frame = EnumerateFrames(frame)
  end
end

local function replaceAllFrameOnUpdateSpecial(rate)
  local frame = EnumerateFrames()
  while frame do
    if frame:GetScript("OnUpdate") then
      local n = frame:GetName()
      local special_rate = n and special_cases[n]
      if print and special_rate then print(n .. " ".. special_cases[n] .. " " .. special_rate) end
      replaceFrameOnUpdate(frame,special_rate or rate)
    end
    frame = EnumerateFrames(frame)
  end
end

local function replaceAllMatchFrameOnUpdate(match,rate)
  local frame = EnumerateFrames()
  while frame do
    if frame:GetScript("OnUpdate") and string.find(frame:GetName() or "", match) then
      -- if print then print(frame:GetName()) end
      replaceFrameOnUpdate(frame,rate)
    end
    frame = EnumerateFrames(frame)
  end
end

-- Function to clean up all timers on PLAYER_LOGOUT
-- This is becasue I'm not sure if logging between acounts keeps timers but I expect it does.
local function cleanUpTimers()
  for frameID, timerID in pairs(TimerManager) do
    UnitXP("timer", "disarm", timerID)
    TimerManager[frameID] = nil
  end
end

function RepeatingTimer(delay, repeat_t, handler)
  if type(handler) ~= "string" then
    if print then print("Timer handler needs to be a string referring to a global function.") end
    return
  end
  return UnitXP("timer", "arm", delay, repeat_t, handler)
end

function OneShotTimer(delay,handler)
  RepeatingTimer(delay,0,handler)
end

function do_replaces()
  -- Hook ui reload since it will clear frames
  local original_ReloadUI = ReloadUI
  ReloadUI = function ()
    cleanUpTimers()
    original_ReloadUI()
  end

  -- Replace OnUpdates of all existing frames, respecting special cases
  replaceAllFrameOnUpdateSpecial()

  do -- Replace OnUpdates of any newly created frame:
    -- Get the frame metatable
    local FrameMeta = getmetatable(CreateFrame("Frame"))

    -- Retrieve the original __index function (not a table in WoW 1.12)
    local OriginalIndex = FrameMeta.__index

    -- Retrieve the original SetScript function from the __index function
    local OriginalSetScript = OriginalIndex(CreateFrame("Frame"), "SetScript")

    -- Safely override SetScript for OnUpdate
    FrameMeta.__index = function(self, key)
      -- Check if the key is "SetScript" and return a custom function
      if key == "SetScript" then
        return function(frame, scriptType, func)
          if scriptType == "OnUpdate" then
            if func then
              -- Replace the OnUpdate logic with custom logic
              local originalOnUpdate = func
              replaceOnUpdateLogic(frame, originalOnUpdate)
            elseif func == nil then -- clear the async timer if OnUpdate is explicitly niled
              local frameID = tostring(frame)
              TimerManager[frameID] = nil
            end
          else
            -- Call the original SetScript for other script types
            OriginalSetScript(frame, scriptType, func)
          end
        end
      end
      -- For all other keys, use the original __index
      return OriginalIndex(self, key)
    end
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGOUT")
f:SetScript("OnEvent", function ()
  if event == "PLAYER_LOGOUT" then
    cleanUpTimers()
  elseif event == "ADDON_LOADED" and arg1 == "Decouple" then
    do_replaces()
  end
end)
-- DEFAULT_CHAT_FRAME:AddMessage("OnUpdate replacement with UnitXP-based timers is complete.")
