---@diagnostic disable: undefined-global
hs.window.animationDuration = 0
local units = {
	right50 = { x = 0.50, y = 0.00, w = 0.50, h = 1.00 },
	right70 = { x = 0.30, y = 0.00, w = 0.70, h = 1.00 },
	left50 = { x = 0.00, y = 0.00, w = 0.50, h = 1.00 },
	left30 = { x = 0.00, y = 0.00, w = 0.30, h = 1.00 },
	top50 = { x = 0.00, y = 0.00, w = 1.00, h = 0.50 },
	bot50 = { x = 0.00, y = 0.50, w = 1.00, h = 0.50 },
	upright = { x = 0.50, y = 0.00, w = 0.50, h = 0.50 },
	botright = { x = 0.50, y = 0.50, w = 0.50, h = 0.50 },
	upleft = { x = 0.00, y = 0.00, w = 0.50, h = 0.50 },
	botleft = { x = 0.00, y = 0.50, w = 0.50, h = 0.50 },
	maximum = { x = 0.00, y = 0.00, w = 1.00, h = 1.00 },
}

local mash = { "ctrl", "cmd" }
--mash = { 'ctrl', 'space' }
hs.hotkey.bind(mash, "l", function()
	hs.window.focusedWindow():move(units.right50, nil, true)
end)
hs.hotkey.bind(mash, "h", function()
	hs.window.focusedWindow():move(units.left50, nil, true)
end)
hs.hotkey.bind(mash, "7", function()
	hs.window.focusedWindow():move(units.left30, nil, true)
end)
hs.hotkey.bind(mash, "0", function()
	hs.window.focusedWindow():move(units.right70, nil, true)
end)
hs.hotkey.bind(mash, "k", function()
	hs.window.focusedWindow():move(units.top50, nil, true)
end)
hs.hotkey.bind(mash, "j", function()
	hs.window.focusedWindow():move(units.bot50, nil, true)
end)
hs.hotkey.bind(mash, "'", function()
	hs.window.focusedWindow():move(units.upright, nil, true)
end)
hs.hotkey.bind(mash, ";", function()
	hs.window.focusedWindow():move(units.upleft, nil, true)
end)
hs.hotkey.bind(mash, ".", function()
	hs.window.focusedWindow():move(units.botleft, nil, true)
end)
hs.hotkey.bind(mash, "/", function()
	hs.window.focusedWindow():move(units.botright, nil, true)
end)
hs.hotkey.bind(mash, "m", function()
	hs.window.focusedWindow():move(units.maximum, nil, true)
end)
hs.hotkey.bind(mash, "n", function()
	hs.window.focusedWindow():moveToScreen(hs.window.focusedWindow():screen():next(), false, true, 0)
end)
hs.hotkey.bind(mash, "p", function()
	hs.window.focusedWindow():moveToScreen(hs.window.focusedWindow():screen():previous(), false, true, 0)
end)
