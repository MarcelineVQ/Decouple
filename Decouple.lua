-- By and for Weird Vibes of Turtle WoW

local _G = _G or getfenv()


--------------------
-- coroutines lib test
--------------------
-- ── CoroutineLib for WoW 1.12 (requires UnitXP SP3) ────────────────────
-- ── CoroutineLib (no pcall, no error) ────────────────────────────────
do
  local co_lib     = {}
  local threadMap  = {}     -- timerID → { fn=…, args={…} }
  local YIELD      = {}     -- sentinel object

  -- helper to schedule the next run
  local function schedule(fn, argsTbl, delay)
    local ms = math.floor((delay or 0) * 1000)
    local id = UnitXP("timer", "arm", ms, 0, "CoTimerCallback")
    threadMap[id] = { fn = fn, args = argsTbl }
  end

  -- called when a timer fires
  function CoTimerCallback(timerID)
    local entry = threadMap[timerID]
    threadMap[timerID] = nil
    if not entry then return end

    -- unpack exactly ten slots
    local a1,a2,a3,a4,a5,a6,a7,a8,a9,a10 =
      entry.args[1], entry.args[2], entry.args[3], entry.args[4],
      entry.args[5], entry.args[6], entry.args[7], entry.args[8],
      entry.args[9], entry.args[10], entry.args[11], entry.args[12]

    -- **direct** call, no pcall
    local r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12 = entry.fn(
      a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12
    )

    if r1 == YIELD then
      -- coroutine asked to yield: reschedule
      local delay = r2
      local nextArgs = { r3,r4,r5,r6,r7,r8,r9,r10,r11,r12 }
      schedule(entry.fn, nextArgs, delay)
    else
      -- r1~=YIELD → thread returned or errored
      -- if it errored, WoW will print the stack‐trace for you
    end
  end

  -- `spawn` packs your initial args into a flat table
  function co_lib.spawn(fn,
    a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12
  )
    local init_args = { a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12 }
    schedule(fn, init_args, 0)
    return fn
  end

  -- `yield` just returns the sentinel plus delay+args
  function co_lib.yield(delay,
    b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12
  )
    return YIELD, delay,
           b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12
  end

  rawset(_G, "coroutine", co_lib)

  -- cleanup on logout
  local f = CreateFrame("Frame")
  f:RegisterEvent("PLAYER_LOGOUT")
  f:SetScript("OnEvent", function()
    for id in pairs(threadMap) do
      UnitXP("timer","disarm",id)
    end
  end)
end

-- test it
function Testo()
  coroutine.spawn(function(n)
    if n > 0 then
      print("Step " .. n)
      -- pure‐return yield
      return coroutine.yield(0, n-1)
    else
      print("Done counting down!")
    end
  end, 5)
end

--------------------


-- Call this once on any frame you want to make “concurrent”
function HookOnEventConcurrent(frame, func)
  -- grab whatever they set previously (could be nil)
  local oldHandler = frame:GetScript("OnEvent")
  func = func or oldHandler
  if not func then return end

  frame.events_tagged = true

  frame:SetScript("OnEvent", function()
    -- spawn a coroutine for this single event
    local a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12 = this,event,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10

    -- We can't delay macro executions, game will prevent this as automation
    if event == "EXECUTE_CHAT_LINE" then
      func()
    else
      coroutine.spawn(
        function(frame,fevent,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10)
        -- stash and restore globals
          local othis,oevent,oarg1,oarg2,oarg3,oarg4,oarg5,oarg6,oarg7,oarg8,oarg9,oarg10 = this,event,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10
          this,event,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10 = frame,fevent,b1,b2,b3,b4,b5,b6,b7,b8,b9,b10
            func()
          -- print(format("conc for %s, %s: %s %s %s %s %s %s %s %s %s %s",this:GetName() or tostring(this), event, arg1 or "",arg2 or "",arg3 or "",arg4 or "",arg5 or "",arg6 or "",arg7 or "",arg8 or "",arg9 or "",arg10 or ""))
          this,event,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10 = othis,oevent,oarg1,oarg2,oarg3,oarg4,oarg5,oarg6,oarg7,oarg8,oarg9,oarg10
        end,
        -- pass through the exact same arguments
        a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12
        -- this, event,
        -- arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10
      )
    end
  end)
end

-- Example usage:
-- local myFrame = CreateFrame("Frame", "MyConcurrentFrame", UIParent)
-- myFrame:RegisterEvent("UNIT_CASTEVENT")
-- myFrame:SetScript("OnEvent", function()
--   -- your original logic here
--   local arg1 = arg1 ~= "" and arg1 or "_"
--   local arg2 = arg2 ~= "" and arg2 or "_"
--   local arg3 = arg3 or "_"
--   local arg4 = arg4 or "_"
--   local arg5 = arg5 or "_"

--   print(format("conc for %s: %s %s %s %s %s",this:GetName(),arg1,arg2,arg3,arg4,arg5))
-- end)

-- now wrap it to be concurrent
-- HookOnEventConcurrent(myFrame)
-- HookOnEventConcurrent(MCEHEventFrame)

-- Ensure the new timer facility is available. Would/should this work on the Glue screens?
local has_unitxp3 = pcall(UnitXP, "nop", "nop") and true or false
if not has_unitxp3 then
  StaticPopupDialogs["NO_UNITXP3"] = {
    text = "|cffffff00Decouple|r requires the |cffffff00UnitXP SP3|r dll to operate.",
    button1 = TEXT(OKAY),
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    showAlert = 1,
  }
  StaticPopup_Show("NO_UNITXP3")
  return
end

-- todo, check if this is interfering with autotrade

-- global addon update rates (ms)
local update_rate_animation = 1 / 120 * 1000
local update_rate = 1 / 30 * 1000  -- ~16.67 ms (30 fps)

-- special per-frame rates (ms)
local special_cases = {
  UIParent              = 1 / 60 * 1000,
  -- WorldFrame            = 1 / 60 * 1000,
  SuperAPI_Castlib      = 1 / 20 * 1000,
  -- AceEvent20Frame       = 1 / 30 * 1000,
  -- GameTooltip           = 1 / 12 * 1000, -- the general update limit is enough
  LUFUnitplayer         = 1 / 60 * 1000,
  LUFUnittarget         = 1 / 60 * 1000,
  -- BearCastBar           = update_rate_animation,
  -- MSBTFrameIncoming     = update_rate_animation,
  -- MSBTFrameNotification = update_rate_animation,
  -- MSBTFrameOutgoing     = update_rate_animation,
}

-- for things like animation in particular
local skip_cases = {
  -- AceEvent20Frame       = true, -- potentially causes missed or re-fired events if skipped
  WorldFrame       = true,
  -- UIParent       = true,
  -- LUFUnitplayer         = true,
  -- LUFUnittarget         = true,
  BearCastBar           = true,
  MSBTFrameIncoming     = true,
  MSBTFrameNotification = true,
  MSBTFrameOutgoing     = true,
  ItemRollFrame         = true, -- todo, fix lootblare instead
}

-- single task list: key = frameID, value = { frame, func, rate, last, nextTime }
local scheduledTasks = {}

-- track the one master dispatch timerID to prevent duplicates
local primaryMasterTimerID

-- master dispatch callback (one SP3 timer), disarms extras
_G.UnitXP_MasterDispatch = function(timerID)
  if not primaryMasterTimerID then
    primaryMasterTimerID = timerID
  elseif timerID ~= primaryMasterTimerID then
    UnitXP("timer", "disarm", timerID)
    return
  end

  local now = GetTime()
  for frameID, task in pairs(scheduledTasks) do
    if now >= task.nextTime then
      local elapsed = now - task.last
      task.last = now
      task.nextTime = now + (task.rate / 1000)

      -- stash and restore globals
      local oldThis, oldArg1 = _G.this, _G.arg1
      _G.this, _G.arg1 = task.frame, elapsed
      task.func()
      _G.this, _G.arg1 = oldThis, oldArg1
    end
  end
end

-- arm the master dispatch timer
local function ArmMasterTimer()
  primaryMasterTimerID = UnitXP("timer", "arm", 0, update_rate, "UnitXP_MasterDispatch")
end

-- helper to schedule/unschedule frame updates
local function ScheduleFrame(frame, func, rate)
  local frameID = tostring(frame)
  if scheduledTasks[frameID] then return end
  local now = GetTime()
  scheduledTasks[frameID] = {
    frame    = frame,
    func     = func,
    rate     = rate or update_rate,
    last     = now,
    nextTime = now + ((rate or update_rate) / 1000),
  }
end

local function UnscheduleFrame(frame)
  scheduledTasks[tostring(frame)] = nil
end

-- Replace OnUpdate with master dispatch scheduling
local function replaceOnUpdateLogic(frame, originalOnUpdate, rate)
  local n = frame:GetName()
  local p = frame:GetParent() and frame:GetParent():GetName()

  local skip = (n and skip_cases[n]) or (p and skip_cases[p])
  local special_rate = (n and special_cases[n]) or (p and special_cases[p])

  -- only wrap once per frame!
  if frame.__decoupleHooked or skip then
    return
  end
  frame.__decoupleHooked = true

  local n = frame:GetName()
  local p = frame:GetParent() and frame:GetParent():GetName()
  local rate = special_rate or update_rate

  frame:SetScript("OnUpdate", nil)
  -- schedule if visible
  if frame:IsVisible() then
    ScheduleFrame(frame, originalOnUpdate, rate)
  end

  -- preserve and chain OnHide
  local prevOnHide = frame:GetScript("OnHide")
  frame:SetScript("OnHide", function()
    if prevOnHide then prevOnHide() end
    UnscheduleFrame(this)
  end)

  -- preserve and chain OnShow
  local prevOnShow = frame:GetScript("OnShow")
  frame:SetScript("OnShow", function()
    if prevOnShow then prevOnShow() end
    ScheduleFrame(this, originalOnUpdate, rate)
  end)
end

-- local function replaceOnEventLogic(frame)
  -- HookOnEventConcurrent(frame)
-- end

-- iterate and hook existing frames (with special-case rates)
local function replaceAllFrameOnUpdateSpecial()
  local f = EnumerateFrames()
  while f do
    local onup = f:GetScript("OnUpdate")
    if onup then
      -- local n = f:GetName()
      -- local p = f:GetParent() and f:GetParent():GetName()
      -- local r = ((n and special_cases[n]) or (p and special_cases[p])) or update_rate
      -- if string.find(p or "", "LUF") then
      --   print("rep")
      --   print(p)
      -- end
      replaceOnUpdateLogic(f, onup, r)
    end
    -- HookOnEventConcurrent(f)
    f = EnumerateFrames(f)
  end
end

function findFrame(find)
  local f = EnumerateFrames()
  while f do
    if string.find(f:GetName() or "", find) then print(f:GetName()) end
    f = EnumerateFrames(f)
  end
end

-- todo, add in-game frame customizing to this

-- apply hotfixes and hooks
local function do_replaces()
  -- hook frames now
  replaceAllFrameOnUpdateSpecial()

  -- intercept newly created frames
  do
    local FrameMeta = getmetatable(CreateFrame("Frame"))
    local OriginalIndex = FrameMeta.__index
    local OriginalSetScript = OriginalIndex(CreateFrame("Frame"), "SetScript")
    FrameMeta.__index = function(self, key)
      if key == "SetScript" then
        return function(frame, scriptType, func)
          if scriptType == "OnUpdate" then
            local n = frame:GetName()
            local p = frame:GetParent() and frame:GetParent():GetName()
            local skip = (n and skip_cases[n]) or (p and skip_cases[p])
            if skip then
              -- print("skipping "..(frame:GetName() or tostring(frame)))
              OriginalSetScript(frame, scriptType, func)
            elseif func then
              replaceOnUpdateLogic(frame, func)
            else
              UnscheduleFrame(frame)
            end
          -- elseif scriptType == "OnEvent" then
            -- OriginalSetScript(frame, scriptType, func)
            -- if func and not frame.events_tagged then
              -- HookOnEventConcurrent(frame, func)
            -- end
          else
            OriginalSetScript(frame, scriptType, func)
          end
        end
      end
      return OriginalIndex(self, key)
    end
  end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGOUT")
-- f:RegisterEvent("PLAYER_QUITTING") ???
-- f:RegisterEvent("PLAYER_LEAVING_WORLD")
f:SetScript("OnEvent", function()
  if event == "ADDON_LOADED" and arg1 == "Decouple" then
    ArmMasterTimer()
    do_replaces()
  elseif event == "PLAYER_LOGOUT" then
    -- disable the master timer
    if primaryMasterTimerID then UnitXP("timer", "disarm", primaryMasterTimerID) end
  end
end)
