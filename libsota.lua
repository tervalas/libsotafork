-- libsota.0.4.8 by Catweazle Waldschrath
-- Revision 0.5.0t by tervalas


--[[
 * libsota.lua
 * Copyright (C) 2019 Michael Fritscher <catweazle@tunipages.de>

 This file is part of libsota.

   libsota is free software: you can redistribute it and/or modify it
   under the terms of the GNU Lesser General Public License as published
   by the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   libsota is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
   See the GNU Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.";
]]



client = {
	timeStarted = os.time(),
	timeToLoad = 0,
	timeInGame = 0,
	timeDelta = 0,
	fps = 0,
	accuracy = 0,
	isHitching = false,
	isLoading = false,
	_statEnum = {},
	_statDescr = {},
	screen = {
		width = 0,
		height = 0,
		isFullScreen = false,
		aspectRatio = 0,
		_fsmul = 1,
	},
	api = {
		luaVersion = "",
		luaPath = "",
		list = {},
		isImplemented = function(name)
			return client.api.list[name] ~= nil
		end
	},
	mouse = {
		button = {},
		x = 0,
		y = 0,
	},
	window = {
		paperdoll = { name = "paperdoll", open = false, left = 0, top = 0, width = 267, height = 487 }
	}
}
scene = {
	name = "none",
	maxPlayer = 0,
	isPvp = false,
	isPot = false,
	timeInScene = 0,
	timeToLoad = 0,
	timeStarted = 0,
}
player = {
	caption = "",
	name = "none",
	flag = "",
	isPvp = false,
	isAfk = false,
	isGod = false,
	isMoving = false,
	isStill = false,
	lastMoved = os.time(),
	location = { x = 0, y = 0 , z = 0, scene = scene },
	health = { current = 0, max = 0, percentage = 0 },
	focus = { current = 0, max = 0, percentage = 0 },
	xp = { producer = 0, adventurer = 0 },
	inventory = {},
	stat = function(index)
		local ret = {
			number = -1,
			name = "invalid",
			value = -999,
			description = "",
		}
		if tonumber(index) == nil then
			index = client._statEnum[index]
		else
			index = tonumber(index)
		end
		if index and index <= #client._statEnum then
			ret.number = index
			ret.name = client._statEnum[index]
			ret.value = ShroudGetStatValueByNumber(index)
			ret.description = client._statDescr[index]
		end
		return ret
	end,
}
ui = {
	version = "0.5.0t",

	timer = {
		list = {},
		add = function(timeout, once, callback, ...)
			local index = #ui.timer.list + 1
			local interval = nil

			if not once then
				interval = timeout
			end

			ui.timer.list[index] = {
				_index = index,
				time = os.time() + timeout,
				interval = interval,
				enabled = true,
				callback = callback,
				userdata = table.pack(...),
			}
			return index
		end,
		get = function(index)
			return ui.timer.list[index]
		end,
		remove = function(index)
			ui.timer.list[index] = nil
		end,
		enabled = function(index, enabled)
			if enabled ~= nil then
				ui.timer.list[index].enabled = enabled
			end
			return ui.timer.list[index].enabled
		end,
		pause = function(index)
			ui.timer.list[index].enabled = false
		end,
		resume = function(index)
			ui.timer.list[index].enabled = true
		end,
		toggle = function(index)
			ui.timer.list[index].enabled = not ui.timer.list[index].enabled
		end,
	},
	setTimeout = function(timeout, callback, ...) return ui.timer.add(timeout, true, callback, ...) end,
	setInterval = function(interval, callback, ...) return ui.timer.add(interval, false, callback, ...) end,

	
	handler = {
		list = {},
		add = function(name, callback)
			local index = #ui.handler.list + 1

			ui.handler.list[index] = {
				_index = index,
				name = name,
				callback = callback,
			}
			return index	
		end,
		remove = function(index)
			ui.handler.list[index] = nil
		end,
		invoke = function(name, ...)
			if not ui_initialized then return end
			for _,h in next, ui.handler.list do
				if h.name == name then
					h.callback(...)
				end
			end
		end,
	},
	onInit = function(callback) return ui.handler.add("_init", callback) end,
	onStart = function(callback) return ui.handler.add("_start", callback) end,
	onUpdate = function(callback) return ui.handler.add("_update", callback) end,
	onConsoleInput = function(callback) return ui.handler.add("_consoleInput", callback) end,
	onConsoleCommand = function(callback) return ui.handler.add("_consoleCommand", callback) end,
	onSceneChanged = function(callback) return ui.handler.add("_sceneChanged", callback) end,
	onPlayerChanged = function(callback) return ui.handler.add("_playerChanged", callback) end,
	onPlayerMove = function(callback) return ui.handler.add("_playerMove", callback) end,
	onPlayerMoveStart = function(callback) return ui.handler.add("_playerMoveStart", callback) end, -- depricated
	onPlayerMoveStop = function(callback) return ui.handler.add("_playerMoveStop", callback) end, -- depricated
	onPlayerIsStill = function(callback) return ui.handler.add("_playerIsStill", callback) end,
	onPlayerDamage = function(callback) return ui.handler.add("_playerDamage", callback) end,
	onPlayerInventory = function(callback) return ui.handler.add("_playerInventory", callback) end,
	onClientWindow = function(callback) return ui.handler.add("_clientWindow", callback) end,
	onClientIsHitching = function(callback) return ui.handler.add("_clientIsHitching", callback) end,
	onClientIsLoading = function(callback) return ui.handler.add("_clientIsLoading", callback) end,
	onMouseMove = function(callback) return ui.handler.add("_mouseMove", callback) end,
	onMouseButton = function(callback) return ui.handler.add("_mouseButton", callback) end,
	onMouseClick = function(callback) return ui.handler.add("_mouseClick", callback) end,
	onMouseOver = function(callback) return ui.handler.add("_mouseOver", callback) end,
	onMouseOut = function(callback) return ui.handler.add("_mouseOut", callback) end,
	onInputChange = function(callback) return ui.handler.add("_inputChange", callback) end,
	onToggleChange = function(callback) return ui.handler.add("_toggleChange", callback) end,

	guiObject = {
		add = function(objectID, objKind) -- move window info back to window object as stored value
			local index = #ui_guiObjectList + 1
			ui_guiObjectList[index] = {
				rect = { left = left or 0, top = top or 0, width = width or 0, height = height or 0 },
				visible = false,
				shownInScene = true,
				shownInLoadScreen = false,
				raycast = true,
				transparency = 0.0,
				draggable = false,
				clickable = false,
				resizable = false,
				resizeDirection = "None",
				sizeMin = nil,
				sizeMax = nil,
				vecx = nil,
			}
			local obj = {
				guiObjectId = index,
				objId = objectID,
				objKind = objKind,
				rect = ui_guiObjectList[index].rect
			}
			ShroudHideObject(objectID, objKind)
			setmetatable(obj, {__index = ui.guiObject})
			setmetatable(ui_guiObjectList[index], {__index = obj})
			return obj
		end,
		remove = function(obj)
			local gObj = obj.guiObjectId
			local oId = obj.objId
			local oKind = tostring(obj.objKind)
			if ShroudDestroyObject(obj.objId, obj.objKind) then
				ui_guiObjectList[obj.guiObjectId] = nil
			end
		end,
		position = function(obj)
			obj.vecx = ShroudGetPosition(obj.objId, obj.objKind)
		end,
		shownInScene = function(obj, shown)
			if shown ~= nil and shown ~= ui_guiObjectList[obj.guiObjectId].shownInScene then
				ui_guiObjectList[obj.guiObjectId].shownInScene = shown
			end
			return ui_guiObjectList[obj.guiObjectId].shownInScene
		end,
		shownInLoadScreen = function(obj, shown)
			if shown ~= nil and shown ~= ui_guiObjectList[obj.guiObjectId].shownInLoadScreen then
				ui_guiObjectList[obj.guiObjectId].shownInLoadScreen = shown
			end
			return ui_guiObjectList[obj.guiObjectId].shownInLoadScreen
		end,
		visible = function(obj, visible)
			if visible ~= nil and visible ~= ui_guiObjectList[obj.guiObjectId].visible then
				ui_guiObjectList[obj.guiObjectId].visible = visible
				if visible then
					ShroudShowObject(obj.objId, obj.objKind)
				else
					ShroudHideObject(obj.objId, obj.objKind)
				end
			end
			return ui_guiObjectList[obj.guiObjectId].visible
		end,
		toggle = function(obj)
			obj:visible(not obj:visible())
		end,
		rect = function(obj, rect)
			if type(rect) == "table" then
				if rect.left then obj.rect.left = rect.left end
				if rect.top then obj.rect.top = rect.top end
				if rect.width then obj.rect.width = rect.width end
				if rect.height then obj.rect.height = rect.height end
			end
			return obj.rect
		end,
		moveTo = function(obj, x, y)
			ShroudSetPosition(obj.objId, obj.objKind, x,y)
			obj.rect.left = x
			obj.rect.top = y
		end,
		moveBy = function(obj, x, y)
			ShroudSetPosition(obj.objId, obj.objKind, obj.rect.left + x, obj.rect.top + y)
			obj.rect.left = obj.rect.left + x
			obj.rect.top = obj.rect.top + y
		end,
		resizeTo = function(obj, w, h)
			ShroudSetSize(obj.objId, obj.objKind, w, h)
		end,
		resizeBy = function(obj, x, y)
			ShroudSetSize(obj.objId, obj.objKind, obj.rect.width + x, obj.rect.height + y)
			obj.rect.width = obj.rect.width + x
			obj.rect.height = obj.rect.height + y
		end,
		anchorMin = function(obj, x, y)
			if obj:getParent() ~= -1 then
				ShroudSetAnchorMin(obj.objId, obj.objKind, x, y)
			end
		end,
		anchorMax = function(obj, x, y)
			if obj:getParent() ~= -1 then
				ShroudSetAnchorMax(obj.objId, obj.objKind, x, y)
			end
		end,
		pivot = function(obj, x, y)
			if obj:getParent() ~= -1 then
				ShroudSetPivot(obj.objId, obj.objKind, x, y)
			end
		end,
		rotate = function(obj, degree)
			ShroudRotateObject(obj.objId, obj.objKind, degree)
		end,
		color = function(obj, color)
			ShroudSetColor(obj.objId, obj.objKind, color)
		end,
		raycast = function(obj, state)
			ShroudRaycastObject(obj.objId, obj.objKind, state)
			ui_guiObjectList[obj.guiObjectId].raycast = state
			return ui_guiObjectList[obj.guiObjectId].raycast
		end,
		transparency = function(obj, transparency)
			ShroudSetTransparency(obj.objId, obj.objKind, transparency)
			ui_guiObjectList[obj.guiObjectId].transparency = transparency
			return ui_guiObjectList[obj.guiObjectId].transparency
		end,
		setParent = function(obj, parentID, parentKind)
			ShroudSetParent(obj.objId, obj.objKind, parentID, parentKind)
		end,
		getParent = function(obj)
			return ShroudGetParentID(obj.objId, obj.objKind)
		end,
		getParentKind = function(obj)
			return ShroudGetParentObjectKind(obj.objId, obj.objKind)
		end,
		draggable = function(obj, drag)
			if drag ~= nil and drag ~= ui_guiObjectList[obj.guiObjectId].draggable then
				ui_guiObjectList[obj.guiObjectId].draggable = drag
				if ui_guiObjectList[obj.guiObjectId].draggable then
					ShroudSetDragguable(obj.objId, obj.objKind)
				else
					ShroudUnsetDragguable(obj.objId, obj.objKind)
				end
			end
			return ui_guiObjectList[obj.guiObjectId].draggable
		end,
		clickable = function(obj, click)
			if click ~= nil and click ~= ui_guiObjectList[obj.guiObjectId].clickable then
				ui_guiObjectList[obj.guiObjectId].clickable = click
			end
			return ui_guiObjectList[obj.guiObjectId].clickable
		end,
		resizable = function(obj, direction)
			if ui_guiObjectList[obj.guiObjectId].draggable == true then
				if direction == "None" then
					ui_guiObjectList[obj.guiObjectId].resizable = false
					ui_guiObjectList[obj.guiObjectId].resizeDirection = "None"
				else
					ui_guiObjectList[obj.guiObjectId].resizable = true
					if direction == nil then
						ui_guiObjectList[obj.guiObjectId].resizeDirection = "ALL"
					else
						ui_guiObjectList[obj.guiObjectId].resizeDirection = direction
					end
				end
				ShroudSetResizable(obj.objId, obj.objKind, direction)
				return ui_guiObjectList[obj.guiObjectId].resizeDirection
			end
		end,
		dragSize = function(obj, min, max, direction)

		end,
		onClick = function(object, callback)
			ui.onMouseClick(function(objectID, objectKind)
				if object.objId == objectID and object.objKind == objectKind then
					callback(objectID, objectKind)
				end
			end)
		end,
		onMouseOver = function(object, callback)
			ui.onMouseOver(function(objectID, objectKind)
				if object.objId == objectID and object.objKind == objectKind then
					callback(objectID, objectKind)
				end
			end)
		end,
		onMouseOut = function(object, callback)
			ui.onMouseOut(function(objectID, objectKind)
				if object.objId == objectID and object.objKind == objectKind then
					callback(objectID, objectKind)
				end
			end)
		end,
		setMask = function(object, status)
			if status then
				ShroudSetMask(object.objId, object.objKind)
			else
				ShroudUnsetMask(object.objId, object.objKind)
			end
		end,
		setScale = function(object, scale)
			ShroudSetScale(object.objId, object.objKind, scale)
		end,
		fontSize = function(object, size)
			ShroudSetFontSize(object.objId, object.objKind, size)
		end,
	},

	label = {
		add = function(caption, font, left, top, width, height, parentID, parentKind)
			local l = ui.guiObject.add(ShroudUIText(caption, font, left, top, width, height, parentID, parentKind),UI.Text)
			l.caption = caption or ""
			setmetatable(l, {__index = ui.label})
			return l
		end,
		setCaption = function(label, capt)
			if capt ~= nil then
				ShroudModifyText(label.objId, capt)
				label.caption = capt
			end
		end,
		align = function(label, anchor)
			ShroudSetTextAlignment(label.objId, anchor)
		end,
		parent = function(label, parent, parentKind)
			ShroudSetTextParent(label, parent, parentKind)
		end,
	},

	image = {
		add = function(left, top, width, height, texture, parentID, parentKind)
			local textureID
			if type(texture) == "string" then 
				textureID = ui.texture.add(texture)
			else
				textureID = texture
			end
			local i = ui.guiObject.add(ShroudUIImage(left, top, width, height, textureID, parentID, parentKind), UI.Image)
			setmetatable(i, {__index = ui.image})
			return i
		end,
		parent = function(image, parent, parentKind)
			ShroudSetImageParent(image, parent, parentKind)
		end,
	},
	
	texture = {
		_loaded = {},
		add = function(texture)
			if not ui.texture._loaded[tostring(texture)] then
				local tid = ShroudLoadTexture(texture)
				if tid < 0 then
					print("ui.texture: Unable to load texture with filename '"..texture.."'")
					return nil
				end
				ui.texture._loaded[tostring(texture)] = {
					filename = texture,
					id = tid,
				}
			end
			local tex = ui.texture._loaded[tostring(texture)]
			setmetatable(tex, {__index = ui.texture})
			return tex.id
		end,
	},
	
	guiButton = {
		add = function(left, top, width, height, texture, parentID, parentKind)
			local textureID
			if type(texture) == "string" then
				textureID = ui.texture.add(texture)
			else
				textureID = texture
			end
			local b = ui.guiObject.add(ShroudUIButton(left, top, width, height, textureID, parentID, parentKind), UI.Button)
			b:clickable(true)
			setmetatable(b, {__index = ui.guiButton})
			return b
		end,
		parent = function(button, parent, parentKind)
			ShroudSetButtonParent(button, parent, parentKind)
		end,
		color = function(button, mode, color)
			ShroudSetButtonColor(button.objId, mode, color)
		end,
		image = function(button, mode, texture)
			if type(texture) == "string" then
				textureID = ui.texture.add(texture)
			else
				textureID = texture
			end
			ShroudSetButtonImage(button.objId, mode, textureID)
		end,
		transition = function(button, transition)
			ShroudSetButtonTransition(button.objId, transition)
		end,
	},

	input = {
		add = function(left, top, width, height, parentID, parentKind)
			local i = ui.guiObject.add(ShroudUIInput(left, top, width, height, parentID, parentKind), UI.Button)
			setmetatable(i, {__index = ui.input})
			return i
		end,
		getText = function(input)
			return ShroudGetInputText(input.objId)
		end,
		setText = function(input, text)
			ShroudSetInputText(input.objId, text)
		end,
		content = function(input, type)
			ShroudSetInputContentType(input.objId, type)
		end,
		placeholder = function(input, text)
			ShroudSetPlaceholderText(input.objId, text)
		end,
		background = function(input, color)
			ShroudSetInputBackgroundColor(input.objId, color)
		end,
		limit = function(input, limit)
			ShroudSetInputCharacterLimit(input.objId, limit)
		end,
		readOnly = function(input, status)
			ShroudSetInputReadOnly(input.objId, status)
		end,
	},

	toggle = {
		add = function(left, top, width, height, parentID, parentKind)
			local t = ui.guiObject.add(ShroudUIToggle(left, top, width, height, parentID, parentKind), UI.Button)
			setmetatable(t, {__index = ui.toggle})
			return t
		end,
		getToggle = function(toggle)
			return ShroudGetToggle(toggle.objId)
		end,
		setToggle = function(toggle, state)
			ShroudSetToggle(toggle.objId, state)
		end,
		readOnly = function(toggle, status)
			ShroudSetToggleReadOnly(toggle.objId, status)
		end,
	},

	shortcut = {
		list = { pressed = {}, watch = {} },
		add = function(action, ...)
			local keys = {...}
			local callback = keys[#keys]; keys[#keys] = nil
			local key = keys[#keys]; keys[#keys] = nil
			if not ui.shortcut.list[action][tostring(key)] then
				ui.shortcut.list[action][tostring(key)] = {}
			end
			if type(callback) == "string" then
				callback = ui.command.list[callback].callback
			end
			local id = #ui.shortcut.list[action][key] + 1
			local index = { action = action, key = key, id = id }
			ui.shortcut.list[action][key][id] = {
				_index = index,
				key = key,
				keysHeld = keys,
				callback = callback,
			}
			if type(callback) == string then
				if ui.command.list[callback].shortcut then
					ui.shortcut.remove(ui.command.list[callback].shortcut)
				end
				ui.command.list[callback].shortcut = index
			end
			return index
		end,
		remove = function(index)
			ui.shortcut.list[index.action][index.key][index.id] = nil
			if #ui.shortcut.list[index.action][index.key] == 0 then ui.shortcut.list[index.action][index.key] = nil end
		end,
		invoke = function(index)
			ui.shortcut.list[index.action][index.key][index.id].callback()
		end,
	},
	
	command = {
		list = {},
		add = function(command, callback)
			ui.command.list[tostring(command)] = {
				_command = command,
				callback = callback,
				shortcut = nil,
				channel = nil,
				sender = player.name,
				receiver = nil,
			}
			return command
		end,
		remove = function(command)
			if ui.command.list[command].shortcut then
				ui.shortcut.remove(ui.command.list[command].shortcut)
			end
			ui.command.list[command] = nil
		end,
		invoke = function(command, ...)
			if ... then
				ui.command.list[command].callback(nil, unpack(...))
			else
				ui.command.list[command].callback()
			end
		end,
		restrict = function(command, channel, sender, receiver)
			if ui.command[command] then
				ui.command[command].channel = channel
				ui.command[command].sender = sender
				ui.command[command].receiver = receiver
			end
		end
	},
	
	module = {
		list = {},
		add = function(modulename, prefix)
			local part = {}
			for p in modulename:gmatch("[^\\/.]+") do part[#part + 1] = p	end
			if part[#part] == "lua" then part[#part] = nil end
			modulename = table.concat(part, ".")
			if not ui.module.list[modulename] then
				local filename = table.concat(part, "/")..".lua"
				local f = nil
				for _,inc in next, {"/","/lib/","/share/","/bin/","/include/"} do
					f = io.open(ShroudLuaPath..inc..filename)
					if f then break end
				end
				if not f then
					print("ui.module: '",filename,"' not found")
					return nil
				end
				local d = f:read("*a")
				f:close()
				local m,e = loadsafe(d, modulename, "bt", _G)
				if not m then
					print("ui.module: '",modulename,"': "..e)
					return nil
				end
				ui.module.list[modulename] = {}
				ui.module.list[modulename][0] = m
			end
			if prefix then
				if prefix == true or prefix == "" then
					prefix = modulename
				else
					part = {}
					for p in prefix:gmatch("[^\\/.]+") do part[#part + 1] = p end
					if part[#part] == "lua" then part[#part] = nil end
					prefix = table.concat(part, ".")
				end
				if #part == 1 then
					_G[part[1]] = ui.module.list[modulename][0]
				else
					local tree = {}
					local leave = tree
					for i=2,#part-1 do
						if not leave[part[i]] then leave[part[i]] = {} end
						leave = leave[part[i]]
					end
					leave[part[#part]] = ui.module.list[modulename][0]
					_G[part[1]] = tree
				end
				ui.module.list[modulename][#ui.module.list[modulename] + 1] = part
			end
			return ui.module.list[modulename][0]
		end,
		get = function(modulename)
			local part = {}
			for p in modulename:gmatch("[^\\/.]+") do part[#part + 1] = p end
			if part[#part] == "lua" then part[#part] = nil end
			modulename = table.concat(part, ".")
			return ui.module.list[tostring(modulename)][0]
		end,
		remove = function(modulename)
			local part = {}
			for p in modulename:gmatch("[^\\/.]+") do part[#part + 1] = p end
			if part[#part] == "lua" then part[#part] = nil end
			modulename = table.concat(part, ".")
			ui.module.list[tostring(modulename)][0] = nil
			for _,prefix in next, ui.module.list[tostring(modulename)] do
				if #prefix == 1 then
					_G[prefix[1]] = nil
				else
					local tree = _G[prefix[1]]
					local leave = tree
					for i=2,#prefix-1 do
						if leave[prefix[i]] then leave = leave[prefix[i]] end
					end
					leave[prefix[#prefix]] = nil
					_G[prefix[1]] = tree
				end
			end
			ui.module.list[tostring(modulename)] = nil
		end,
		invoke = function(modulename, callback, ...)
			local part = {}
			for p in modulename:gmatch("[^\\/.]+") do part[#part + 1] = p end
			if part[#part] == "lua" then part[#part] = nil end
			modulename = table.concat(part, ".")
			if ui.module.list[modulename] then
				if callback then
					return ui.module.list[modulename][0][tostring(callback)](...)
				else
					return ui.module.list[modulename][0](...)
				end
			else
				print("ui.module: ",modulename," not found")
			end
		end,
	},
	
	verbosity = 0,
	consoleLog = function(message, verbosity)
		if not verbosity then verbosity = 0 end
		if ui.verbosity >= verbosity then
			for l in message:gmatch("[^\n]+") do
				ShroudConsoleLog(l)
			end
		end
	end,
}
--setmetatable(ui.timer, {__index = ui.timer.list})
setmetatable(ui.label, {__index = ui.guiObject})
setmetatable(ui.texture, {__index = ui.guiObject})
setmetatable(ui.guiButton, {__index = ui.guiObject})
setmetatable(ui.image, {__index = ui.guiObject})
setmetatable(ui.input, {__index = ui.guiObject})
setmetatable(ui.toggle, {__index = ui.guiObject})


-- internal
ui_initialized = false
ui_client_ts = os.time()
ui_client_frame = 0
ui_guiObjectList = {}
ui_drawListChanged = false
local ui_drawInScene = {}
local ui_drawInLoadScreen = {}
local ui_callback_queue = {}

local ui_inventory_quantity = {}
local ui_inventory_durability = {}

local function ui_getPlayerName()
	if player.caption ~= ShroudGetPlayerName() then
		player.caption = ShroudGetPlayerName()
		player.name = player.caption
		player.flag = ""
		player.isPvp = false
		if player.name:byte(#player.name) == 93 then
			player.name, player.flag = player.name:match("^(.-)(%[.-%])$")
			player.isPvp = player.flag and player.flag:find("PVP") ~= nil
			player.isAfk = player.flag and player.flag:find("AFK") ~= nil
			player.isGod = player.flag and player.flag:find("God") ~= nil
		end
		ui.handler.invoke("_playerChanged", "caption")
	end
end

local function ui_getPlayerChange()
	local loc = { x = ShroudPlayerX, y = ShroudPlayerY, z = ShroudPlayerZ, scene = scene }
	local isMoving = loc.x ~= player.location.x or loc.y ~= player.location.y or loc.z ~= player.location.z
	if isMoving then player.lastMoved = os.time() end
	local isStill = os.time() - player.lastMoved > 5
	local invoke = isStill ~= player.isStill or isMoving ~= player.isMoving
	player.isMoving = isMoving
	player.isStill = isStill
	player.location = loc
	if invoke then
		if isMoving then
			ui.handler.invoke("_playerMoveStart") -- depricated
			ui.handler.invoke("_playerMove", "start", loc)
			ui.handler.invoke("_playerChanged", "moving")
		elseif isStill then
			ui.handler.invoke("_playerIsStill") -- depricated?
			ui.handler.invoke("_playerMove", "stillness", loc) -- hm?
			ui.handler.invoke("_playerChanged", "stillness")
		else
			ui.handler.invoke("_playerMoveStop") -- depricated
			ui.handler.invoke("_playerMove", "stop", loc)
			ui.handler.invoke("_playerChanged", "standing")
		end
	end
	if isMoving then
		ui.handler.invoke("_playerMove", "move", loc)
		ui.handler.invoke("_playerChanged", "location", loc)
	end
	local health = { max = ShroudGetStatValueByNumber(30), current = ShroudPlayerCurrentHealth, percentage = 0 }
	local focus =  { max = ShroudGetStatValueByNumber(27), current = ShroudPlayerCurrentFocus, percentage = 0 }
	health.percentage = health.current / health.max
	focus.percentage = focus.current / focus.max
	invoke = player.health.current ~= health.current or player.focus.current ~= focus.current
	if invoke then
		ui.handler.invoke("_playerDamage", health, focus)
		ui.handler.invoke("_playerChanged", "damage", health, focus)
	end
	player.health = health
	player.focus = focus
end

local function ui_getPlayerInventory()
	local inventory = ShroudGetInventory()
	local ret1 = {}
	local ret2 = {}
	local ret3 = {}
	for _, item in next, inventory do
		item = table.pack(item)
		ret1[#ret1 + 1] = {
			name = item[1],
			durability = item[2],
			primaryDurability = item[3],
			maxDurability = item[4],
			weight = item[5],
			quantity = item[6],
			value = item[7],
		}
		if not ret2[tostring(item[1])] then
			ret2[tostring(item[1])] = 0
		end
		ret2[tostring(item[1])] = ret2[tostring(item[1])] + item[6]
	end
	local cs = { n = 0 }
	for n, q in next, ui_inventory_quantity do
		if not ret2[n] then
			--print("Gegenstand entfernt: "..n.."Menge: "..q)
			cs[n] = { quantity = q, action = "removed" }
			cs.n = cs.n + 1
		elseif ret2[n] ~= q then
			--print("Gegenstand geändert: "..n.."Menge: "..(ret2[n] - q))
			cs[n] = { quantity = ret2[n] - q, action = "changed" }
			cs.n = cs.n + 1
		end
	end
	for n, q in next, ret2 do
		if not ui_inventory_quantity[n] then
			--print("Gegenstand zugefügt: "..n.."Menge: "..q)
			cs[n] = { quantity = q, action = "added" }
			cs.n = cs.n + 1
		end
	end
	
	player.inventory = ret1
	ui_inventory_quantity = ret2

	if cs.n > 0 then
		cs.n = nil
		ui.handler.invoke("_playerInventory", cs)
		ui.handler.invoke("_playerChanged", "inventory", cs)
	end
end

local function ui_getSceneName()
	if scene.name ~= ShroudGetCurrentSceneName() then
		scene.name = ShroudGetCurrentSceneName()
		scene.maxPlayer = ShroudGetCurrentSceneMaxPlayerCount()
		scene.isPvp = ShroudGetCurrentSceneIsPVP()
		scene.isPot = ShroudGetCurrentSceneIsPOT()
		scene.timeStarted = os.time()
		ui.handler.invoke("_sceneChanged")
	end
end

local function ui_initialize()

	client.api.luaPath = ShroudLuaPath
	client.api.luaVersion = _G._MOONSHARP.luacompat
	for i,v in next, _G do
		if i:find("^Shroud") then client.api.list[tostring(i)] = type(v) end
	end

	client.timeToLoad = ui_client_ts - client.timeStarted
	client.screen.width = ShroudGetScreenX()
	client.screen.height = ShroudGetScreenY()
	client.screen.isFullScreen = ShroudGetFullScreen()
	client.screen.aspectRatio = client.screen.width / client.screen.height
	client.screen._fsmul = client.screen.height / 1080
	for i=0, ShroudGetStatCount()-1, 1 do
		local name = ShroudGetStatNameByNumber(i)
		client._statEnum[tostring(name)] = i
		client._statEnum[i] = name
		client._statDescr[i] = ShroudGetStatDescriptionByNumber(i)
	end
	ui_getSceneName()
	ui_getPlayerName()
	ui_getPlayerChange()
	ui_getPlayerInventory()

	ShroudRegisterPeriodic("ui_timer_internal", "ui_timer_internal", 0.01, true)
	ShroudRegisterPeriodic("ui_timer_user", "ui_timer_user", 0.120, true)
end

local function ui_buildDrawList()
	local list = ui_guiObjectList
	local ds = {}
	local dl = {}

	for _,o in next, list do
		if o.visible and o.shownInScene then
			ds[#ds + 1] = o
		elseif o.visible and o.shownInLoadScreen then
			dl[#dl + 1] = o
		end
	end

	table.sort(ds, function(a, b) return a.zIndex < b.zIndex end) -- comment out for update
	table.sort(dl, function(a, b) return a.zIndex < b.zIndex end) -- comment out for update
	
	ui_drawInScene = ds
	ui_drawInLoadScreen = dl
end

local function ui_queue(callback, ...)
	local index = #ui_callback_queue + 1

	if type(callback) == "function" then
		ui_callback_queue[index] = {
			callback = callback,
			userdata = table.pack(...),
		}	
	else
		for _,h in next, ui.handler.list do
			if h.name == callback then
				ui_callback_queue[index] = {
					callback = h.callback,
					userdata = table.pack(...),
				}	
				index = #ui_callback_queue + 1
			end
		end
	end
end


-- shroud callbacks


-- shroud timers
local ui_timer_ts_fast = os.time()
local ui_timer_ts_slow = os.time()
function ui_timer_internal()
	local ts = os.time()
	
	if ts - ui_timer_ts_fast > 0.240 then
		ui_timer_ts_fast = ts

		ui_getPlayerChange()
	end
	
	if ts - ui_timer_ts_slow > 2 then
		ui_timer_ts_slow = ts
		
		-- watch player xp
		player.xp.producer = ShroudGetPooledProducerExperience()
		player.xp.adventurer = ShroudGetPooledAdventurerExperience()

		-- watch player inventory
		ui_getPlayerInventory()
	end


	-- queued callbacks

	for i,q in next, ui_callback_queue do
		q.callback(unpack(q.userdata))
		ui_callback_queue[i] = nil
	end
	
	
	-- watch character sheet window (realtime)

	local wo = ShroudIsCharacterSheetActive()
	if wo then
		local wx, wy = ShroudGetCharacterSheetPosition(); wx = wx - 860 -- bug
		if wx ~= client.window.paperdoll.left or wy ~= client.window.paperdoll.top then
			client.window.paperdoll.left, client.window.paperdoll.top = wx, wy
			ui.handler.invoke("_clientWindow", "moved", client.window.paperdoll)		
		end
	end
	if wo ~= client.window.paperdoll.open then
		client.window.paperdoll.open = wo
		if wo then
			ui.handler.invoke("_clientWindow", "opened", client.window.paperdoll)
		else
			ui.handler.invoke("_clientWindow", "closed", client.window.paperdoll)
		end
	end
end

function ui_timer_user()
	local ts = os.time()
	
	for _,t in next, ui.timer.list do
		if t.enabled and ts >= t.time then
			if t.interval then
				t.time = ts + t.interval
			else
				ui.timer.list[t._index] = nil
			end
			if t.callback(unpack(t.userdata)) then ui.timer.list[t._index] = nil end
		end
	end
end


-- shroud callbacks

function ShroudOnStart()
	ShroudUseLuaConsoleForPrint(true)
	ShroudConsoleLog(_G._MOONSHARP.banner)
	ShroudConsoleLog("LUA Version: ".._G._MOONSHARP.luacompat)
end

local button_ts = {} -- howto: clean up
local button_ts2 = {}
function ShroudOnUpdate()
	local ts = os.time()

	-- init
	if not ui_initialized then
		if not ShroudServerTime then return end -- shroud Api not ready, yet
		ShroudConsoleLog("Shroud Api Ready. ServerTime: "..ShroudServerTime)

		ui_initialize()
		ui_initialized = true

		ui.handler.invoke("_init")
		ui.handler.invoke("_start")
	end

	-- client stats
	ui_client_frame = ui_client_frame + 1;
	if ts - ui_client_ts >= 1 then
		if client.accuracy > 10 then
			ui_getSceneName()
			ui_getPlayerName()
			client.isLoading = false
			scene.timeToLoad = client.accuracy
		end
		client.timeInGame = ShroudTime
		client.timeDelta =  ShroudDeltaTime
		client.fps = ui_client_frame
		ui_client_frame = 0
		client.accuracy = ts - ui_client_ts - 1
		ui_client_ts = ts
		client.isHitching = false
		scene.timeInScene = ts - scene.timeStarted
	end

	-- check key up
	for ku,r in next, ui.shortcut.list.pressed do
		if ShroudGetOnKeyUp(ku) then
			for _,f in next, r do
				local invoke = true
				for _,kd in next, f.keysHeld do
					invoke = invoke and ShroudGetKeyDown(kd)
				end
				if invoke then f.callback() end
			end
		end
	end
	-- check key held/repeat
	for ku,r in next, ui.shortcut.list.watch do
		if ShroudGetOnKeyDown(ku) then
			for _,f in next, r do
				local invoke = true
				for _,kd in next, f.keysHeld do
					invoke = invoke and ShroudGetKeyDown(kd)
				end
				if invoke then
					f.timeDown = os.time()
					f.callback("down", ku, f.keysHeld)
				end
			end

		elseif ShroudGetKeyDown(ku) then
			for _,f in next, r do
				local invoke = true
				for _,kd in next, f.keysHeld do
					invoke = invoke and ShroudGetKeyDown(kd)
				end
				if invoke then
					if os.time() - f.timeDown >= 0.25 then
						f.callback("held", ku, f.keysHeld)
					end
				end
			end

		elseif ShroudGetOnKeyUp(ku) then
			for _,f in next, r do
				local invoke = true
				for _,kd in next, f.keysHeld do
					invoke = invoke and ShroudGetKeyDown(kd)
				end
				if invoke then
					f.timeUp = os.time()
					f.callback("up", ku, f.keysHeld)
					if os.time() - f.timeDown <= 0.25 then
						f.callback("pressed", ku, f.keysHeld)
					end
				end
			end
		end
	end

	-- check mouse
	for i,mb in next, { "Mouse0", "Mouse1", "Mouse2", "Mouse3", "Mouse4", "Mouse5", "Mouse6" } do
		client.mouse.button[i] = nil
		if ShroudGetOnKeyDown(mb) then
			button_ts[i] = os.time()
			client.mouse.button[i] = "down"
		elseif ShroudGetKeyDown(mb) then
			if os.time() - button_ts[i] >= 0.25 then
				client.mouse.button[i] = "held"
			end
		elseif ShroudGetOnKeyUp(mb) then
			client.mouse.button[i] = "up"
			if os.time() - button_ts[i] <= 0.25 then
				if button_ts2[i] and os.time() - button_ts2[i] <= 0.25 then
					ui.handler.invoke("_mouseButton", "dblclicked", i, ShroudMouseX, ShroudMouseY)
					button_ts2[i] = nil
				else
					ui.handler.invoke("_mouseButton", "clicked", i, ShroudMouseX, ShroudMouseY)
					button_ts2[i] = os.time()
				end
			end
		end
	end
	if client.mouse.x ~= ShroudMouseX or client.mouse.y ~= ShroudMouseY then
		client.mouse.x, client.mouse.y = ShroudMouseX, ShroudMouseY
		ui.handler.invoke("_mouseMove", client.mouse.button, client.mouse.x, client.mouse.y)
	end
	for i,mb in next, client.mouse.button do
		ui.handler.invoke("_mouseButton", mb, i, client.mouse.x, client.mouse.y)
	end


	ui.handler.invoke("_update")	
	

end

function ShroudOnGUI() end

function ShroudOnConsoleInput(channel, sender, message)

	ui_queue(function(...)

		-- handle player flag changes
		if (channel == "Story" or channel == "System") and message:find("PvP") then ui_getPlayerName() end

		-- parse message
		local src, dst, msg = message:match("^(.-) to (.-) %[.-:%s*(.*)$")
		if sender == "" then sender = src end
		if sender == "" then sender = player.name end
		if msg:byte() == 92 or msg:byte() == 95 or msg:byte() == 33 then
			local cmd, tail = msg:match("^[\\_!](%w+)%s*(.*)$")
			local source = {
				channel = channel,
				sender = sender,
				receiver = dst,
			}
			if ui.command.list[cmd] then
				if not ui.command.list[cmd].sender or ui.command.list[cmd].sender == sender
				and not ui.command.list[cmd].channel or ui.command.list[cmd].channel == channel
				and not ui.command.list[cmd].receiver or ui.command.list[cmd].receiver == dst
				then
					local arg = {}
					for a in tail:gmatch("%S+") do arg[#arg + 1] = a end
					arg.n = #arg
					ui.command.list[cmd].callback(source, unpack(arg))
				end
			else
				ui.handler.invoke("_consoleCommand", source, cmd, tail)
			end
		else
			ui.handler.invoke("_consoleInput", channel, sender, dst, msg)
		end

	end, channel, sender, message)
end

function ShroudOnMouseClick(objectID, objectKind)
	local list = ui_guiObjectList
	for _, o in next, list do
		if o.objId == objectID and o.objKind == objectKind and o.clickable == true then
			ui.handler.invoke("_mouseClick", o.objId, o.objKind)
		end
	end
end

function ShroudOnMouseOver(objectID, objectKind)
	local list = ui_guiObjectList
	for _, o in next, list do
		if o.objId == objectID and o.objKind == objectKind then
			ui.handler.invoke("_mouseOver", o.objId, o.objKind)
		end
	end
end

function ShroudOnMouseOut(objectID, objectKind)
	local list = ui_guiObjectList
	for _, o in next, list do
		if o.objId == objectID and o.objKind == objectKind then
			ui.handler.invoke("_mouseOut", o.objId, o.objKind)
		end
	end
end

function ShroudOnInputChange(objectID, text)
	local list = ui_guiObjectList
	for _, o in next, list do
		if o.objId == objectID then
			ui.handler.invoke("_inputChange", o.objId, text)
		end
	end
end

function ShroudOnToggleChange(objectID, isOn)
	local list = ui_guiObjectList
	for _, o in next, list do
		if o.objId == objectID then
			ui.handler.invoke("_toggleChange", o.objId, isOn)
		end
	end
end


window = {
	-- _new = function(self, left, top, width, height, titleImage, backgroundImage, borderTable, caption)
	_new = function(self, left, top, width, height, titleImage, backgroundImage, caption)
		return self.new(left, top, width, height, titleImage, backgroundImage, caption)
	end,
	new = function(left, top, width, height, titleImage, backgroundImage, caption)
		local win = {
			left = left,
			top = top,
			width = width,
			height = height,
			tImage = titleImage,
			bImage = backgroundImage,
			caption = caption or "",
			is_visible = false,
			children = {},
			content = nil,
		}
		setmetatable(win, {__index = window})
		win:draw()
		return win
	end,

	draw = function(window)
		--window:rebuild()

		local bTexture = ui.texture.add(window.bImage)
		local buttonImage = ui.texture.add("ShroudTracker/assets/delete.png")
		
		local titleBar = ui.image.add(window.left, window.top, window.width, 20, bTexture)
		ShroudSetDragguable(titleBar.objId, UI.Image)
		window:addChild("titleBar", titleBar, UI.Image)

		local background = ui.image.add(0, 20, window.width, window.height, bTexture, titleBar.objId, UI.Image)
		ShroudSetAnchorMin(background.objId, UI.Image, 0.0, 1.0)
		ShroudSetAnchorMax(background.objId, UI.Image, 0.0, 1.0)
		ShroudSetPivot(background.objId, UI.Image, 0.0, 1.0)
		ShroudRaycastObject(background.objId, UI.Image, false)
		window:addChild("mainWindow", background, UI.Image)
		
		local titleLabel = ui.label.add(window.caption, 12, 0, 0, window.width, 20, titleBar.objId, UI.Image)
		ShroudRaycastObject(titleLabel.objId,UI.Text,false)
		ShroudSetTextAlignment(titleLabel.objId, TextAnchor.MiddleLeft)
		titleLabel:color("#c4a000")
		window:addChild("caption", titleLabel, UI.Text)

		local titleLabel2 = ui.label.add(window.caption, 52, 0, 0, window.width, 20, titleBar.objId, UI.Image)
		ShroudRaycastObject(titleLabel2.objId,UI.Text,false)
		ShroudSetTextAlignment(titleLabel2.objId, TextAnchor.MiddleLeft)
		titleLabel2:color("#c4a000")
		window:addChild("caption1", titleLabel2, UI.Text)
		
		local hideButton = ui.guiButton.add(0, 0, 20, 20, buttonImage, titleBar.objId, UI.Image)
		ShroudSetAnchorMin(hideButton.objId,UI.Button, 1.0, 1.0)
		ShroudSetAnchorMax(hideButton.objId,UI.Button, 1.0, 1.0)
		ShroudSetPivot(hideButton.objId,UI.Button, 1.0, 1.0)
		window:addChild("hideButton", hideButton, UI.Button)
		hideButton:onClick(function(objectID, objectKind)
			window.children["hideButton"].window:visible(false)
		end)
		
		if (window.content ~= nil) then
			window:content()
		end

		window:visible(false)
	end,

	rebuild = function(window)
		for next, obj in pairs(window.children) do
			--print(next)
			--obj.obj:remove()
			window:removeChild(next)
		end
		window.children = {}
	end,

	addChild = function(window, name, object, type)
		window.children[name] = {
			obj = object,
			type = type
		}
		object:visible(window.is_visible)
		window.children[name].window = window
	end,

	visible = function(window, status)
		window.is_visible = status
		for next, obj in pairs(window.children) do
			obj.obj:visible(window.is_visible)
		end
	end,

	removeChild = function(window, name)
		if window.children[name] ~= nil then
			window.children[name].obj:remove()
			window.children[name] = nil
		end
	end
}
setmetatable(window, {__call = window._new})

