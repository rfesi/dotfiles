-- Set up
-----------------------------------------------

local hyper = {"shift", "cmd", "alt", "ctrl"}
hs.window.animationDuration = 0
hs.grid.setGrid('12x12')
hs.grid.MARGINX = 0
hs.grid.MARGINY = 0

require("hs.application")
require("hs.window")

-----------------------------------------------
-- Window Grid
-----------------------------------------------

local grid = {
  topHalf = '0,0 12x6',
  topThird = '0,0 12x4',
  topTwoThirds = '0,0 12x8',
  rightHalf = '6,0 6x12',
  rightThird = '8,0 4x12',
  rightTwoThirds = '4,0 8x12',
  bottomHalf = '0,6 12x6',
  bottomThird = '0,8 12x4',
  bottomTwoThirds = '0,4 12x8',
  leftHalf = '0,0 6x12',
  leftThird = '0,0 4x12',
  leftTwoThirds = '0,0 8x12',
  topLeft = '0,0 6x6',
  topRight = '6,0 6x6',
  bottomRight = '6,6 6x6',
  bottomLeft = '0,6 6x6',
  fullScreen = '0,0 12x12',
  centeredBig = '0.5,0.5 11x11',
  centeredSmall = '4,4 4x4',
}

local lastSeenChain = nil
local lastSeenWindow = nil

-- Chain the specified movement commands.
--
-- This is like the "chain" feature in Slate, but with a couple of enhancements:
--
--  - Chains always start on the screen the window is currently on.
--  - A chain will be reset after 2 seconds of inactivity, or on switching from
--    one chain to another, or on switching from one app to another, or from one
--    window to another.
--
local chain = (function(movements)
  local chainResetInterval = 2 -- seconds
  local cycleLength = #movements
  local sequenceNumber = 1

  return function()
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local now = hs.timer.secondsSinceEpoch()
    local screen = win:screen()

    if
      lastSeenChain ~= movements or
      lastSeenAt < now - chainResetInterval or
      lastSeenWindow ~= id
    then
      sequenceNumber = 1
      lastSeenChain = movements
    elseif (sequenceNumber == 1) then
      -- At end of chain, restart chain on next screen.
      screen = screen:next()
    end
    lastSeenAt = now
    lastSeenWindow = id

    hs.grid.set(win, movements[sequenceNumber], screen)
    sequenceNumber = sequenceNumber % cycleLength + 1
  end
end)


hs.fnutils.each({
  { key='q', positions = { grid.leftHalf, grid.leftTwoThirds, grid.topLeft, grid.bottomLeft, grid.leftThird }},
  { key='w', positions = { grid.fullScreen, grid.centeredBig }},
  { key='e', positions = { grid.rightHalf, grid.rightTwoThirds, grid.topRight, grid.bottomRight, grid.rightThird }},
}, function(entry)
  hs.hotkey.bind(hyper, entry.key, chain(entry.positions))
end)

-----------------------------------------------
-- Hotkeys
-----------------------------------------------

local hotkeys = {
  -- Movement
  { 'h', {}, 'left'},
  { 'j', {}, 'down'},
  { 'k', {}, 'up'},
  { 'l', {}, 'right'},
  { 'n', {'cmd'}, 'left'},  -- beginning of line
  { 'p', {'cmd'}, 'right'}, -- end of line
  { 'm', {'alt'}, 'left'},  -- back word
  { '.', {'alt'}, 'right'}, -- forward word

  -- Rebinds
  { 'delete', {}, 'forwarddelete'} -- forward delete
}
for i,bnd in ipairs(hotkeys) do
  hs.hotkey.bind(hyper, bnd[1], function()
    hs.eventtap.keyStroke(bnd[2],bnd[3])
  end)
end

-----------------------------------------------
-- App shortcuts
-----------------------------------------------
local apps = {
  { ';', 'iTerm'}
}
for i,app in ipairs(apps) do
  hs.hotkey.bind(hyper, app[1], function()
    hs.application.launchOrFocus(app[2])
  end)
end

-----------------------------------------------
-- Reload config on write
-----------------------------------------------

function reload_config(files)
    hs.reload()
end
hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reload_config):start()
hs.alert.show("Config loaded")

-----------------------------------------------
-- Hyper i to show window hints
-----------------------------------------------

hs.hotkey.bind(hyper, '/', function()
    hs.hints.windowHints()
end)