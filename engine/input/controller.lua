---@class Controller
Controller = Object:extend()

--The controller contains all engine logic for how human input interacts with any game objects.
function Controller:Initialize()
    --Each of these are calculated per frame to pass along to the corresponding nodes for input handling
    self.clicked = { target = nil, handled = true, prev_target = nil }     --The node that was clicked this frame
    self.focused = { target = nil, handled = true, prev_target = nil }     --The node that is being focused on this frame, only applies when using controller
    self.dragging = { target = nil, handled = true, prev_target = nil }    --The node being dragged this frame
    self.hovering = { target = nil, handled = true, prev_target = nil }    --The node being hovered this frame
    self.released_on = { target = nil, handled = true, prev_target = nil } --The node that the cursor 'Released' on, like letting go of LMB

    self.collision_list = {}                                               --A list of all node that the cursor currently collides with

    --Input values to be determined by this controller - the actual game objects should not have to see any of this
    self.cursor_down = { T = { x = 0, y = 0 }, target = nil, time = 0, handled = true }
    self.cursor_up = { T = { x = 0, y = 0 }, target = nil, time = 0.1, handled = true }
    self.cursor_hover = { T = { x = 0, y = 0 }, target = nil, time = 0, handled = true }
    self.cursor_collider = nil              --The node that collides with the cursor this frame
    self.cursor_position = { x = 0, y = 0 } --NOT IN GAME UNITS

    --For key presses, hold times, and if they are released directly from LOVE
    self.pressed_keys = {}
    self.held_keys = {}
    self.held_key_times = {}
    self.released_keys = {}

    --For button presses, hold times, and if they are released directly from LOVE
    self.pressed_buttons = {}
    self.held_buttons = {}
    self.held_button_times = {}
    self.released_buttons = {}

    --For all controller interrupts
    self.interrupt = {
        focus = false,
    }

    --For all controller locks
    self.locks = {}
    self.locked = nil

    --Buttons pressed and released during axis updates
    self.axis_buttons = {
        l_stick = { current = '', previous = '' },
        r_stick = { current = '', previous = '' },
        l_trig = { current = '', previous = '' },
        r_trig = { current = '', previous = '' }
    }

    --The speed that the controller thumbstick moves the cursor
    self.axis_cursor_speed = 20

    --A registry of buttons, each a valid button input name corresponding to a node (likely a button). This is modified with the registry functions
    self.button_registry = {}

    --A node representing where the cursor should 'snap' to. When this is set, then next frame should have the cursor to that position or on that node. Use :snap_to
    self.snap_cursor_to = nil

    --A stack of cursor positions, this stack changes depending on the depth of menus on screen so the game can remember where you last had your cursor
    --This needs to keep track of both positions and nodes if possible, as well as the depth
    self.cursor_context = {
        layer = 1,
        stack = {}
    }

    self.cardarea_context = {}

    --Human Interface device flags, these are set per frame to ensure that correct controller updates are taking place
    self.HID = {
        last_type = '',
        dpad = false,
        pointer = true,
        touch = false,
        controller = false,
        mouse = true,
        axis_cursor = false,
    }

    --The gamepad most recently used, if any
    self.GAMEPAD = { object = nil, mapping = nil, name = nil }
    self.GAMEPAD_CONSOLE = '' --Valid button icons for Xbox, Playstation and Nintendo controllers

    --If we need an emulated gamepad for keyboard controls
    self.keyboard_controller = {
        getGamepadMappingString = function() return 'balatro_kbm' end,
        getGamepadAxis = function() return 0 end
    }

    self.is_cursor_down = false
end

--Sets the gamepad to be the updated gamepad, searches for the console type and sets the art button pips accordingly
--Some code here is from github.com/idbrii/love-gamepadguesser (MIT License)
function Controller:set_gamepad(_gamepad)
    if self.GAMEPAD.object ~= _gamepad then
        self.GAMEPAD.object = _gamepad
        self.GAMEPAD.mapping = _gamepad:getGamepadMappingString() or ''
        self.GAMEPAD.name = self.GAMEPAD.mapping:match("^%x*,(.-),") or ''
        self.GAMEPAD.temp_console = self:get_console_from_gamepad(self.GAMEPAD.name)
        if self.GAMEPAD_CONSOLE ~= self.GAMEPAD.temp_console then
            self.GAMEPAD_CONSOLE = self.GAMEPAD.temp_console
            for k, v in pairs(Game.INSTANCES.SPRITE) do
                if v.atlas == Game.ASSET_ATLAS["gamepad_ui"] then
                    v.sprite_pos.y = Game.CONTROLLER.GAMEPAD_CONSOLE == 'Nintendo' and 2 or
                        Game.CONTROLLER.GAMEPAD_CONSOLE == 'Playstation' and (Game.F_PS4_PLAYSTATION_GLYPHS and 3 or 1) or
                        0
                    v:set_sprite_pos(v.sprite_pos)
                end
            end
        end
        self.GAMEPAD.temp_console = nil
    end
end

--Some code here is from github.com/idbrii/love-gamepadguesser (MIT License)
function Controller:get_console_from_gamepad(_gamepad)
    Game.ARGS.gamepad_patterns = Game.ARGS.gamepad_patterns or
        {
            Playstation = { "%f[%w]PS%d%f[%D]", "Sony%f[%W]", "Play[Ss]tation" },
            Nintendo = { "Wii%f[%L]", "%f[%u]S?NES%f[%U]", "%f[%l]s?nes%f[%L]", "%f[%u]Switch%f[%L]", "Joy[- ]Cons?%f[%L]", },
            --Keyboard = {'balatro_kbm'}
        }

    for k, v in pairs(Game.ARGS.gamepad_patterns) do
        for kk, vv in ipairs(v) do
            if _gamepad:match(vv) then
                return k
            end
        end
    end
    return 'Xbox'
end

--The universal controller for what type of HID Device the player is using to interact with the game. The Game should be able to handle switching
--to any viable HID at any time
function Controller:set_HID_flags(HID_type, button)
    --we need to determine it the axis input will be handled like a button or pointer
    --if button and self.HID.controller and not string.find(button, 'dp') then return end
    if HID_type == 'axis' then
        self.HID.controller = true
        self.HID.last_type = 'axis'
    elseif HID_type and HID_type ~= self.HID.last_type then
        self.HID.dpad = HID_type == 'button'
        self.HID.pointer = HID_type == 'mouse' or HID_type == 'axis_cursor' or HID_type == 'touch'
        self.HID.controller = HID_type == 'button' or HID_type == 'axis_cursor'
        self.HID.mouse = HID_type == 'mouse'
        self.HID.touch = HID_type == 'touch'
        self.HID.axis_cursor = HID_type == 'axis_cursor'
        self.HID.last_type = HID_type

        if self.HID.mouse then
            love.mouse.setVisible(true)
        else
            love.mouse.setVisible(false)
        end
    end
    if not self.HID.controller then
        self.GAMEPAD_CONSOLE = ''
        self.GAMEPAD.object = nil
        self.GAMEPAD.mapping = nil
        self.GAMEPAD.name = nil
    end
end

--Sets the current position of the cursor
function Controller:set_cursor_position()
    --If using a mouse for the cursor
    if self.HID.mouse or self.HID.touch then
        self.interrupt.focus = false
        --Never focus if using the mouse
        if self.focused.target then
            self.focused.target.states.focus.is = false
            self.focused.target = nil
        end

        --Set the position of the cursor to the love position of the mouse, derive cursor transform from that
        self.cursor_position.x, self.cursor_position.y = love.mouse.getPosition()
        Game.CURSOR.T.x = self.cursor_position.x / (Game.TILESCALE * Game.TILESIZE)
        Game.CURSOR.T.y = self.cursor_position.y / (Game.TILESCALE * Game.TILESIZE)
        Game.CURSOR.VT.x = Game.CURSOR.T.x
        Game.CURSOR.VT.y = Game.CURSOR.T.y
    end
end

--Called every game logic update frame
function Controller:update(dt)
    --parse all locks and set
    self.locked = false
    if Game.screenwipe then self.locks.wipe = true else self.locks.wipe = false end

    for k, v in pairs(self.locks) do
        if v then self.locked = true end
    end

    if self.locks.frame_set then
        self.locks.frame_set = nil
        self.overlay_timer = 0
        Game.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            timer = 'UPTIME',
            blocking = false,
            blockable = false,
            no_delete = true,
            func = (function()
                self.locks.frame = nil
                return true
            end)
        }))
    end

    self.overlay_timer = self.overlay_timer or 0
    if Game.OVERLAY_MENU then
        self.overlay_timer = self.overlay_timer + dt
    else
        self.overlay_timer = 0
    end

    if self.overlay_timer > 1.5 then self.locks.frame = nil end

    --Remove anything from the registry that is no longer in game
    self:cull_registry()

    --Calculate the axis update and set the HID flags if there is any axis input
    self:set_HID_flags(self:update_axis(dt))

    --Set the cursor to be visible only if we are using a mouse or an axis to control the cursor position
    if self.HID.pointer and not (self.HID.mouse or self.HID.touch) and not self.interrupt.focus then
        Game.CURSOR.states.visible = true
    else
        Game.CURSOR.states.visible = false
    end

    --For mouse input, reset any controller things and set the cursor to be where the mouse is
    self:set_cursor_position()

    --Handle all the button updates and key updates, call the required functions
    if not Game.screenwipe then
        --Key press and release handling
        for k, v in pairs(self.pressed_keys) do
            if v then self:key_press_update(k, dt) end
        end
        for k, v in pairs(self.held_keys) do
            if v then self:key_hold_update(k, dt) end
        end
        for k, v in pairs(self.released_keys) do
            if v then self:key_release_update(k, dt) end
        end

        --Button press and release handling
        for k, v in pairs(self.pressed_buttons) do
            if v then self:button_press_update(k, dt) end
        end
        for k, v in pairs(self.held_buttons) do
            if v then self:button_hold_update(k, dt) end
        end
        for k, v in pairs(self.released_buttons) do
            if v then self:button_release_update(k, dt) end
        end
    end

    self.frame_buttonpress = false

    --reset press and release lists
    self.pressed_keys = EMPTY(self.pressed_keys)
    self.released_keys = EMPTY(self.released_keys)
    self.pressed_buttons = EMPTY(self.pressed_buttons)
    self.released_buttons = EMPTY(self.released_buttons)


    --If using controller, update context and snap tos
    if self.HID.controller then
        --If there is a node/position to snap to from the cursor context layer
        if self.cursor_context.stack[self.cursor_context.layer] then
            local _context = self.cursor_context.stack[self.cursor_context.layer]
            self:snap_to { node = (_context.node and not _context.node.REMOVED and _context.node), T = _context.cursor_pos }
            self.interrupt.stack = _context.interrupt
            self.cursor_context.stack[self.cursor_context.layer] = nil
        end
        --If there is a card the was being dragged but no longer is, snap to it
        if self.dragging.prev_target and not self.dragging.target and getmetatable(self.dragging.prev_target) == Card and not self.dragging.prev_target.REMOVED then
            --Overly complicated coyote time focus, so the user can quickly select cards without things going wonky
            if not self.COYOTE_FOCUS then
                self:snap_to { node = self.dragging.prev_target }
            else
                self.COYOTE_FOCUS = nil
            end
        end
        --If the cursor should snap to a location
        if self.snap_cursor_to then
            self.interrupt.focus = self.interrupt.stack
            self.interrupt.stack = false
            if self.snap_cursor_to.type == 'node' and not self.snap_cursor_to.node.REMOVED then
                self.focused.prev_target = self.focused.target
                self.focused.target = self.snap_cursor_to.node
                self:update_cursor()
            elseif self.snap_cursor_to.type == 'transform' then
                self:update_cursor(self.snap_cursor_to.T)
            end
            if self.focused.prev_target ~= self.focused.target and self.focused.prev_target then self.focused.prev_target.states.focus.is = false end
            self.snap_cursor_to = nil
        end
    end

    --Reset all collision states, get every node that collides with the cursor, then update the focus and hover targets
    self:get_cursor_collision(Game.CURSOR.T)
    self:update_focus()
    self:set_cursor_hover()
    if self.L_cursor_queue then
        self:L_cursor_press(self.L_cursor_queue.x, self.L_cursor_queue.y)
        self.L_cursor_queue = nil
    end

    self.dragging.prev_target = self.dragging.target
    self.released_on.prev_target = self.released_on.target
    self.clicked.prev_target = self.clicked.target
    self.hovering.prev_target = self.hovering.target

    --Cursor is currently down
    if not self.cursor_down.handled then
        if self.cursor_down.target.states.drag.can then
            self.cursor_down.target.states.drag.is = true
            self.cursor_down.target:set_offset(self.cursor_down.T, 'Click')
            self.dragging.target = self.cursor_down.target
            self.dragging.handled = false
        end
        self.cursor_down.handled = true
    end

    if not self.cursor_up.handled then
        --First, stop dragging
        if self.dragging.target then
            self.dragging.target:stop_drag()
            self.dragging.target.states.drag.is = false
            self.dragging.target = nil
        end
        --Now, handle the Cursor release
        --Was the Cursor release in the same location as the Cursor press and within Cursor timeout?
        if self.cursor_down.target then
            if (not self.cursor_down.target.click_timeout or self.cursor_down.target.click_timeout * Game.SPEEDFACTOR > self.cursor_up.time - self.cursor_down.time) then
                if Vector_Dist(self.cursor_down.T, self.cursor_up.T) < Game.MIN_CLICK_DIST then
                    if self.cursor_down.target.states.click.can then
                        self.clicked.target = self.cursor_down.target
                        self.clicked.handled = false
                    end
                    --if not, was the Cursor dragging some other thing?
                elseif self.dragging.prev_target and self.cursor_up.target and self.cursor_up.target.states.release_on.can then
                    self.released_on.target = self.cursor_up.target
                    self.released_on.handled = false
                end
            end
        end
        self.cursor_up.handled = true
    end

    --Cursor is currently hovering over something
    if self.cursor_hover.target and self.cursor_hover.target.states.hover.can and (not self.HID.touch or self.is_cursor_down) then
        self.hovering.target = self.cursor_hover.target
        if self.hovering.prev_target and self.hovering.prev_target ~= self.hovering.target then self.hovering.prev_target.states.hover.is = false end
        self.hovering.target.states.hover.is = true
        self.hovering.target:set_offset(self.cursor_hover.T, 'Hover')
    elseif (self.cursor_hover.target == nil or (self.HID.touch and not self.is_cursor_down)) and self.hovering.target then
        self.hovering.target.states.hover.is = false
        self.hovering.target = nil
    end

    --------------------------------------------------------------------
    -- Sending all input updates to the game objects
    --------------------------------------------------------------------
    --The clicked object
    if not self.clicked.handled then
        self.clicked.target:click()
        self.clicked.handled = true
    end

    --Process registry clicks
    self:process_registry()

    --The object being dragged
    if self.dragging.target then
        self.dragging.target:drag()
    end

    --The object released on
    if not self.released_on.handled and self.dragging.prev_target then
        if self.dragging.prev_target == self.hovering.target then
            self.hovering.target:stop_hover(); self.hovering.target = nil
        end
        self.released_on.target:release(self.dragging.prev_target)
        self.released_on.handled = true
    end

    --The object being hovered over
    if self.hovering.target then
        self.hovering.target:set_offset(self.cursor_hover.T, 'Hover')
        if self.hovering.prev_target ~= self.hovering.target then
            if self.hovering.target ~= self.dragging.target and not self.HID.touch then
                self.hovering.target:hover()
            elseif self.HID.touch then
                local _ID = self.hovering.target.ID
                Game.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    blockable = false,
                    blocking = false,
                    delay = Game.MIN_HOVER_TIME,
                    func = function()
                        if self.hovering.target and _ID == self.hovering.target.ID then
                            self.hovering.target:hover()
                        end
                        return true
                    end
                }))
                if self.hovering.prev_target then
                    self.hovering.prev_target:stop_hover()
                end
            end
            if self.hovering.prev_target then
                self.hovering.prev_target:stop_hover()
            end
        end
    elseif self.hovering.prev_target then
        self.hovering.prev_target:stop_hover()
    end
    if self.hovering.target and self.hovering.target == self.dragging.target and not self.HID.touch then
        self.hovering.target:stop_hover()
    end
end

--Brute force remove all registries that no longer have valid nodes
function Controller:cull_registry()
    for k, registry in pairs(self.button_registry) do
        for i = #registry, 1, -1 do
            if registry[i].node.REMOVED then
                table.remove(registry, i)
            end
        end
    end
end

--Adds a node to the controller registry. Supply the button that will be pressed in order to click this node
--
---@param node Node The node that will be clicked when the registry is pressed
---@param registry string The button to register, must be a valid gamepad input
function Controller:add_to_registry(node, registry)
    --If the button doesn't have a registry list yet, add it
    self.button_registry[registry] = self.button_registry[registry] or {}

    --There really should only ever be one entry per registered button, but that is hard sometimes with all the stuff on screen.
    --If that does happen, the most recently registered one will be used and the old one will be kept in case we remove the new button and want to keep the old binding
    table.insert(self.button_registry[registry], 1,
        { node = node, menu = (not not Game.OVERLAY_MENU) or (not not Game.SETTINGS.paused) })
end

--Process any click function of any nodes that have been clicked in the button registry
function Controller:process_registry()
    for _, registry in pairs(self.button_registry) do
        for i = 1, #registry do
            if registry[i].click and registry[i].node.click then
                if registry[i].menu == not not Game.OVERLAY_MENU and
                    registry[i].node.T.x > -2 and registry[i].node.T.x < Game.ROOM.T.w + 2 and
                    registry[i].node.T.y > -2 and registry[i].node.T.y < Game.ROOM.T.h + 2 then
                    registry[i].node:click()
                end
                registry[i].click = nil
            end
        end
    end
end

--Add or remove layers from the context for the cursor. This allows the cursor to 'snap' back to the previous layer when the current layer is removed\
--in such cases where a menu on screen is removed or nested menus are being navigated
--
---@param delta number The direction to modify the cursor context, 1 to add a layer, -1 to remove a layer, -1000 to remove all layers except for the base
function Controller:mod_cursor_context_layer(delta)
    --Add a layer to the context, reference the node but if that node has been removed also save the cursor position too
    if delta == 1 then
        local prev_cursor_context = {
            node = self.focused.target,
            cursor_pos = { x = Game.CURSOR.T.x, y = Game.CURSOR.T.y },
            interrupt =
                self.interrupt.focus
        }
        self.cursor_context.stack[self.cursor_context.layer] = prev_cursor_context
        self.cursor_context.layer = self.cursor_context.layer + 1

        --remove the top layer from the stack
    elseif delta == -1 then
        self.cursor_context.stack[self.cursor_context.layer] = nil
        self.cursor_context.layer = self.cursor_context.layer - 1

        --remove all but the base layer from the stack
    elseif delta == -1000 then
        self.cursor_context.layer = 1
        self.cursor_context.stack = { self.cursor_context.stack[1] }

        --remove all layers
    elseif delta == -2000 then
        self.cursor_context.layer = 1
        self.cursor_context.stack = {}
    end

    --Navigate focus, will default to the top layer on the stack
    self:navigate_focus()
end

--Snap the cursor to a particular node or transform
function Controller:snap_to(args)
    self.snap_cursor_to = { node = args.node, T = args.T, type = args.node and 'node' or 'transform' }
end

--saves the focus context to be loaded in the future, for example if the shop is rerolled while a card is highlighted
function Controller:save_cardarea_focus(_cardarea)
    if Game[_cardarea] then
        if self.focused.target and self.focused.target.area and self.focused.target.area == Game[_cardarea] then
            self.cardarea_context[_cardarea] = self.focused.target.rank
            return true
        else
            self.cardarea_context[_cardarea] = nil
        end
    end
end

--recalls the focus context for a particular cardarea
function Controller:recall_cardarea_focus(_cardarea)
    local ca_string = nil
    if type(_cardarea) == 'string' then
        ca_string = _cardarea; _cardarea = Game[_cardarea]
    end

    if _cardarea and (not self.focused.target or
            self.interrupt.focus or
            (not self.interrupt.focus and self.focused.target.area and self.focused.target.area == _cardarea)) then
        if ca_string and self.cardarea_context[ca_string] then
            for i = self.cardarea_context[ca_string], 1, -1 do
                if _cardarea.cards[i] then
                    self:snap_to({ node = _cardarea.cards[i] })
                    self.interrupt.focus = false
                    break
                end
            end
        elseif _cardarea.cards and _cardarea.cards[1] then
            self:snap_to({ node = _cardarea.cards[1] })
            self.interrupt.focus = false
        end
    end
    if ca_string then self.cardarea_context[ca_string] = nil end
end

--Updated the location of the cursor, either with a specific T or if there is a Node target
function Controller:update_cursor(hard_set_T)
    if hard_set_T then
        Game.CURSOR.T.x = hard_set_T.x
        Game.CURSOR.T.y = hard_set_T.y
        self.cursor_position.x = Game.CURSOR.T.x * (Game.TILESCALE * Game.TILESIZE)
        self.cursor_position.y = Game.CURSOR.T.y * (Game.TILESCALE * Game.TILESIZE)
        Game.CURSOR.VT.x = Game.CURSOR.T.x
        Game.CURSOR.VT.y = Game.CURSOR.T.y
        return
    end
    if self.focused.target then
        self.cursor_position.x, self.cursor_position.y = self.focused.target:put_focused_cursor()
        Game.CURSOR.T.x = self.cursor_position.x / (Game.TILESCALE * Game.TILESIZE)
        Game.CURSOR.T.y = self.cursor_position.y / (Game.TILESCALE * Game.TILESIZE)
        Game.CURSOR.VT.x = Game.CURSOR.T.x
        Game.CURSOR.VT.y = Game.CURSOR.T.y
    end
end

--Helper function to set the button presses/releases for the values determined in update_axis()
function Controller:handle_axis_buttons()
    for _, v in pairs(Game.CONTROLLER.axis_buttons) do
        --Button is no longer being pressed
        if v.previous ~= '' and (v.current == '' or v.previous ~= v.current) then
            Game.CONTROLLER:button_release(v.previous)
        end
        --New button is being pressed
        if v.current ~= '' and v.previous ~= v.current then
            Game.CONTROLLER:button_press(v.current)
        end
    end
end

--Handles all axis input for left stick, right stick and triggers. Treats them as buttons or cursors depending on context
function Controller:update_axis(dt)
    --Keep track of if there is any cursor movement from the axis changes
    local axis_interpretation = nil

    --Advance all the axis buttons to determine if there were any changes
    self.axis_buttons.l_stick.previous = self.axis_buttons.l_stick.current; self.axis_buttons.l_stick.current = ''
    self.axis_buttons.r_stick.previous = self.axis_buttons.r_stick.current; self.axis_buttons.r_stick.current = ''
    self.axis_buttons.l_trig.previous = self.axis_buttons.l_trig.current; self.axis_buttons.l_trig.current = ''
    self.axis_buttons.r_trig.previous = self.axis_buttons.r_trig.current; self.axis_buttons.r_trig.current = ''

    if self.HID.controller then
        ---------------------------------------------------------------
        --                     Left Thumbstick
        ---------------------------------------------------------------
        local l_stick_x = self.GAMEPAD.object:getGamepadAxis('leftx')
        local l_stick_y = self.GAMEPAD.object:getGamepadAxis('lefty')
        --If there is something being dragged, we want to treat the left stick as a cursor input
        if self.dragging.target and math.abs(l_stick_x) + math.abs(l_stick_y) > 0.1 then
            axis_interpretation = 'axis_cursor' --There is some cursor movement

            --deadzone of 10% for each axis of l_stick
            if math.abs(l_stick_x) < 0.1 then l_stick_x = 0 end
            if math.abs(l_stick_y) < 0.1 then l_stick_y = 0 end
            l_stick_x = l_stick_x + (l_stick_x > 0 and -0.1 or 0) + (l_stick_x < 0 and 0.1 or 0)
            l_stick_y = l_stick_y + (l_stick_y > 0 and -0.1 or 0) + (l_stick_y < 0 and 0.1 or 0)

            --Modify the cursor position according to the l_stick axis values
            Game.CURSOR.T.x = Game.CURSOR.T.x + dt * l_stick_x * self.axis_cursor_speed
            Game.CURSOR.T.y = Game.CURSOR.T.y + dt * l_stick_y * self.axis_cursor_speed
            Game.CURSOR.VT.x = Game.CURSOR.T.x
            Game.CURSOR.VT.y = Game.CURSOR.T.y

            self.cursor_position.x = Game.CURSOR.T.x * (Game.TILESCALE * Game.TILESIZE)
            self.cursor_position.y = Game.CURSOR.T.y * (Game.TILESCALE * Game.TILESIZE)

            --If nothing is being dragged, we want to treat the left stick as a dpad input
        else
            self.axis_buttons.l_stick.current = self.axis_buttons.l_stick.previous
            if math.abs(l_stick_x) + math.abs(l_stick_y) > 0.5 then
                axis_interpretation =
                'button' --left stick is no longer a cursor, can be set below from the right stick though

                self.axis_buttons.l_stick.current = math.abs(l_stick_x) > math.abs(l_stick_y) and
                    (l_stick_x > 0 and 'dpright' or 'dpleft') or
                    (l_stick_y > 0 and 'dpdown' or 'dpup')
            elseif math.abs(l_stick_x) + math.abs(l_stick_y) < 0.3 then
                self.axis_buttons.l_stick.current = ''
            end
        end

        ---------------------------------------------------------------
        --                     Right Thumbstick
        ---------------------------------------------------------------
        local r_stick_x = self.GAMEPAD.object:getGamepadAxis('rightx')
        local r_stick_y = self.GAMEPAD.object:getGamepadAxis('righty')
        Game.DEADZONE = 0.2
        local mag = math.sqrt(math.abs(r_stick_x) ^ 2 + math.abs(r_stick_y) ^ 2)
        if mag > Game.DEADZONE then
            axis_interpretation = 'axis_cursor' --There is some cursor movement

            --deadzone of 20% for each axis of l_stick
            if math.abs(r_stick_x) < Game.DEADZONE then r_stick_x = 0 end
            if math.abs(r_stick_y) < Game.DEADZONE then r_stick_y = 0 end
            r_stick_x = r_stick_x + (r_stick_x > 0 and -Game.DEADZONE or 0) + (r_stick_x < 0 and Game.DEADZONE or 0)
            r_stick_y = r_stick_y + (r_stick_y > 0 and -Game.DEADZONE or 0) + (r_stick_y < 0 and Game.DEADZONE or 0)

            --Modify the cursor position according to the l_stick axis values
            Game.CURSOR.T.x = Game.CURSOR.T.x + dt * r_stick_x * self.axis_cursor_speed
            Game.CURSOR.T.y = Game.CURSOR.T.y + dt * r_stick_y * self.axis_cursor_speed
            Game.CURSOR.VT.x = Game.CURSOR.T.x
            Game.CURSOR.VT.y = Game.CURSOR.T.y

            self.cursor_position.x = Game.CURSOR.T.x * (Game.TILESCALE * Game.TILESIZE)
            self.cursor_position.y = Game.CURSOR.T.y * (Game.TILESCALE * Game.TILESIZE)
        end

        ---------------------------------------------------------------
        --                         Triggers
        ---------------------------------------------------------------
        --Triggers are just buttons
        local l_trig = self.GAMEPAD.object:getGamepadAxis('triggerleft')
        local r_trig = self.GAMEPAD.object:getGamepadAxis('triggerright')

        --Set the current to be the same as previous, only set to '' if the trigger value is low enough
        self.axis_buttons.l_trig.current = self.axis_buttons.l_trig.previous
        self.axis_buttons.r_trig.current = self.axis_buttons.r_trig.previous

        --Make a tilting effect when you press the triggers while hovering over a node that has tilt_var
        if self.focused.target and self.focused.target.tilt_var then
            --self.focused.target.tilt_var.dx = 0.1*(r_trig - l_trig) + 0.9*self.focused.target.tilt_var.dx
        end

        if l_trig > 0.5 then
            self.axis_buttons.l_trig.current = 'triggerleft'
        elseif l_trig < 0.3 then
            self.axis_buttons.l_trig.current = ''
        end
        if r_trig > 0.5 then
            self.axis_buttons.r_trig.current = 'triggerright'
        elseif r_trig < 0.3 then
            self.axis_buttons.r_trig.current = ''
        end

        --return 'button' if trigger is being used and axis is not
        if self.axis_buttons.r_trig.current ~= '' or self.axis_buttons.l_trig.current ~= '' then
            axis_interpretation = axis_interpretation or 'button'
        end

        self:handle_axis_buttons()
    end

    if axis_interpretation then self.interrupt.focus = false end

    return axis_interpretation
end

function Controller:button_press_update(button, dt)
    if self.locks.frame then return end
    self.held_button_times[button] = 0
    self.interrupt.focus = false

    if not self:capture_focused_input(button, 'press', dt) then
        if button == "dpup" then
            self:navigate_focus('U')
        end
        if button == "dpdown" then
            self:navigate_focus('D')
        end
        if button == "dpleft" then
            self:navigate_focus('L')
        end
        if button == "dpright" then
            self:navigate_focus('R')
        end
    end

    if ((self.locked) and not Game.SETTINGS.paused) or (self.locks.frame) or (self.frame_buttonpress) then return end
    self.frame_buttonpress = true

    if self.button_registry[button] and self.button_registry[button][1] and not self.button_registry[button][1].node.under_overlay then
        self.button_registry[button][1].click = true
    else
        if button == 'start' then
            if Game.STATE == Game.STATES.SPLASH then
                Game:delete_run()
                Game:main_menu()
            end
        end
        if button == "a" then
            if self.focused.target and
                self.focused.target.config.focus_args and
                self.focused.target.config.focus_args.type == 'slider' and
                (not Game.CONTROLLER.HID.mouse and not Game.CONTROLLER.HID.axis_cursor) then
            else
                self:L_cursor_press()
            end
        end
        if button == 'b' then
            if Game.hand and self.focused.target and
                self.focused.target.area == Game.hand then
                self:queue_R_cursor_press()
            else
                self.interrupt.focus = true
            end
        end
    end
end

function Controller:button_hold_update(button, dt)
    if ((self.locked) and not Game.SETTINGS.paused) or (self.locks.frame) or (self.frame_buttonpress) then return end
    self.frame_buttonpress = true
    if self.held_button_times[button] then
        self.held_button_times[button] = self.held_button_times[button] + dt
        self:capture_focused_input(button, 'hold', dt)
    end
    if (button == 'dpleft' or button == 'dpright' or button == 'dpup' or button == 'dpdown') and not self.no_holdcap then
        self.repress_timer = self.repress_timer or 0.3
        if self.held_button_times[button] and (self.held_button_times[button] > self.repress_timer) then
            self.repress_timer = 0.1
            self.held_button_times[button] = 0
            self:button_press_update(button, dt)
        end
    end
end

function Controller:button_release_update(button, dt)
    if not self.held_button_times[button] then return end
    self.repress_timer = 0.3
    self.held_button_times[button] = nil
    if button == 'a' then
        self:L_cursor_release()
    end
end

function Controller:key_press_update(key, dt)
    if self.locks.frame then return end
    if string.sub(key, 1, 2) == 'kp' then key = string.sub(key, 3) end
    if key == 'enter' then key = 'return' end

    if self.text_input_hook then
        if key == "escape" then
            self.text_input_hook = nil
        elseif key == "capslock" then
            self.capslock = not self.capslock
        else
            Game.FUNCS.text_input_key {
                e = self.text_input_hook,
                key = key,
                caps = self.held_keys["lshift"] or self.held_keys["rshift"]
            }
        end
        return
    end

    if key == "escape" then
        if Game.STATE == Game.STATES.SPLASH then
            Game:delete_run()
            Game:main_menu()
        else
            if not Game.OVERLAY_MENU then
                Game.FUNCS:options()
            elseif not Game.OVERLAY_MENU.config.no_esc then
                Game.FUNCS:exit_overlay_menu()
            end
        end
    end

    if ((self.locked) and not Game.SETTINGS.paused) or (self.locks.frame) or (self.frame_buttonpress) then return end
    self.frame_buttonpress = true
    self.held_key_times[key] = 0


    if not _RELEASE_MODE then
        if key == 'tab' and not Game.debug_tools then
            Game.debug_tools = UIBox {
                definition = create_UIBox_debug_tools(),
                config = { align = 'cr', offset = { x = Game.ROOM.T.x + 11, y = 0 }, major = Game.ROOM_ATTACH, bond = 'Weak' }
            }
            Game.E_MANAGER:add_event(Event({
                blockable = false,
                func = function()
                    Game.debug_tools.alignment.offset.x = -4
                    return true
                end
            }))
        end
        if self.hovering.target and self.hovering.target:is(Card) then
            local _card = self.hovering.target
            if Game.OVERLAY_MENU then
                if key == "1" then
                    unlock_card(_card.config.center)
                    _card:set_sprites(_card.config.center)
                end
                if key == "2" then
                    unlock_card(_card.config.center)
                    discover_card(_card.config.center)
                    _card:set_sprites(_card.config.center)
                end
                if key == "3" then
                    if _card.ability.set == 'Joker' and Game.jokers and #Game.jokers.cards < Game.jokers.config.card_limit then
                        add_joker(_card.config.center.key)
                        _card:set_sprites(_card.config.center)
                    end
                    if _card.ability.consumeable and Game.consumeables and #Game.consumeables.cards < Game.consumeables.config.card_limit then
                        add_joker(_card.config.center.key)
                        _card:set_sprites(_card.config.center)
                    end
                end
            end
            if key == 'q' then
                if (_card.ability.set == 'Joker' or _card.playing_card or _card.area) then
                    local _edition = {
                        foil = not _card.edition,
                        holo = _card.edition and _card.edition.foil,
                        polychrome = _card.edition and _card.edition.holo,
                        negative = _card.edition and _card.edition.polychrome,
                    }
                    _card:set_edition(_edition, true, true)
                end
            end
        end
        if key == 'h' then
            Game.debug_UI_toggle = not Game.debug_UI_toggle
        end
        if key == 'b' then
            Game:delete_run()
            Game:start_run({})
        end
        if key == 'l' then
            Game:delete_run()
            Game.SAVED_GAME = get_compressed(Game.SETTINGS.profile .. '/' .. 'save.jkr')
            if Game.SAVED_GAME ~= nil then Game.SAVED_GAME = STR_UNPACK(Game.SAVED_GAME) end
            Game:start_run({ savetext = Game.SAVED_GAME })
        end
        if key == 'j' then
            Game.debug_splash_size_toggle = not Game.debug_splash_size_toggle
            Game:delete_run()
            Game:main_menu('splash')
        end
        if key == '8' then
            love.mouse.setVisible(not love.mouse.isVisible())
        end
        if key == '9' then
            Game.debug_tooltip_toggle = not Game.debug_tooltip_toggle
        end
        if key == "space" then
            live_test()
        end
        if key == 'v' then
            if not Game.prof then
                Game.prof = require "engine/profile"; Game.prof.start()
            else
                Game.prof:stop();
                print(Game.prof.report()); Game.prof = nil
            end
        end
        if key == "p" then
            Game.SETTINGS.perf_mode = not Game.SETTINGS.perf_mode
        end
    end
end

function Controller:key_hold_update(key, dt)
    if ((self.locked) and not Game.SETTINGS.paused) or (self.locks.frame) or (self.frame_buttonpress) then return end
    --self.frame_buttonpress = true
    if self.held_key_times[key] then
        if key == "r" and not Game.SETTINGS.paused then
            if self.held_key_times[key] > 0.7 then
                if not Game.GAME.won and not Game.GAME.seeded and not Game.GAME.challenge then
                    Game.PROFILES[Game.SETTINGS.profile].high_scores.current_streak.amt = 0
                end
                Game:save_settings()
                self.held_key_times[key] = nil
                Game.SETTINGS.current_setup = 'New Run'
                Game.GAME.viewed_back = nil
                Game.run_setup_seed = Game.GAME.seeded
                Game.challenge_tab = Game.GAME and Game.GAME.challenge and Game.GAME.challenge_tab or nil
                Game.forced_seed, Game.setup_seed = nil, nil
                if Game.GAME.seeded then Game.forced_seed = Game.GAME.pseudorandom.seed end
                Game.forced_stake = Game.GAME.stake
                if Game.STAGE == Game.STAGES.RUN then Game.FUNCS.start_setup_run() end
                Game.forced_stake = nil
                Game.challenge_tab = nil
                Game.forced_seed = nil
            else
                self.held_key_times[key] = self.held_key_times[key] + dt
            end
        end
    end
end

function Controller:key_release_update(key, dt)
    if ((self.locked) and not Game.SETTINGS.paused) or (self.locks.frame) or (self.frame_buttonpress) then return end
    self.frame_buttonpress = true
    if key == "a" and self.held_keys["g"] and not _RELEASE_MODE then
        Game.DEBUG = not (Game.DEBUG)
    end
    if key == 'tab' and Game.debug_tools then
        Game.debug_tools:remove()
        Game.debug_tools = nil
    end
end

function Controller:key_press(key)
    self.pressed_keys[key] = true
    self.held_keys[key] = true
end

function Controller:key_release(key)
    self.held_keys[key] = nil
    self.released_keys[key] = true
end

function Controller:button_press(button)
    self.pressed_buttons[button] = true
    self.held_buttons[button] = true
end

function Controller:button_release(button)
    self.held_buttons[button] = nil
    self.released_buttons[button] = true
end

function Controller:get_cursor_collision(cursor_trans)
    self.collision_list = EMPTY(self.collision_list)
    self.nodes_at_cursor = EMPTY(self.nodes_at_cursor)

    if self.COYOTE_FOCUS then return end
    if self.dragging.target then
        self.dragging.target.states.collide.is = true
        self.nodes_at_cursor[#self.nodes_at_cursor + 1] = self.dragging.target
        self.collision_list[#self.collision_list + 1] = self.dragging.target
    end

    if not Game.DRAW_HASH[1] or
        cursor_trans.x - Game.ROOM.T.x < -Game.DRAW_HASH_BUFF or cursor_trans.x - Game.ROOM.T.x > Game.TILE_W + Game.DRAW_HASH_BUFF or
        cursor_trans.y - Game.ROOM.T.y < -Game.DRAW_HASH_BUFF or cursor_trans.y - Game.ROOM.T.y > Game.TILE_H + Game.DRAW_HASH_BUFF then
        return
    end

    local DRAW_HASH_SQUARE = Game.DRAW_HASH
    for i = #DRAW_HASH_SQUARE, 1, -1 do
        local v = DRAW_HASH_SQUARE[i]
        if v:collides_with_point(cursor_trans) and not v.REMOVED then
            self.nodes_at_cursor[#self.nodes_at_cursor + 1] = v
            if v.states.collide.can then
                v.states.collide.is = true
                self.collision_list[#self.collision_list + 1] = v
            end
        end
    end
end

function Controller:set_cursor_hover()
    self.cursor_hover.T = self.cursor_hover.T or {}
    self.cursor_hover.T.x, self.cursor_hover.T.y = Game.CURSOR.T.x, Game.CURSOR.T.y
    self.cursor_hover.time = Game.TIMERS.TOTAL

    self.cursor_hover.prev_target = self.cursor_hover.target
    self.cursor_hover.target = nil

    if self.interrupt.focus or ((self.locked) and (not Game.SETTINGS.paused or Game.screenwipe)) or self.locks.frame or self.COYOTE_FOCUS then
        self.cursor_hover.target = Game.ROOM; return
    end

    if self.HID.controller and self.focused.target and self.focused.target.states.hover.can then
        if (self.HID.dpad or self.HID.axis_cursor) and self.focused.target.states.collide.is then
            self.cursor_hover.target = self.focused.target
        else
            for _, v in ipairs(self.collision_list) do
                if v.states.hover.can then
                    self.cursor_hover.target = v
                    break
                end
            end
        end
    else
        for _, v in ipairs(self.collision_list) do
            if v.states.hover.can and (not v.states.drag.is or self.HID.touch) then
                self.cursor_hover.target = v
                break
            end
        end
    end

    if not self.cursor_hover.target or (self.dragging.target and not self.HID.touch) then
        self.cursor_hover.target = Game
            .ROOM
    end
    if self.cursor_hover.target ~= self.cursor_hover.prev_target then self.cursor_hover.handled = false end
end

function Controller:queue_L_cursor_press(x, y)
    if self.locks.frame then return end
    if Game.STATE == Game.STATES.SPLASH then
        self:key_press('escape')
    end
    self.L_cursor_queue = { x = x, y = y }
end

function Controller:queue_R_cursor_press(x, y)
    if self.locks.frame then return end
    if not Game.SETTINGS.paused and Game.hand and Game.hand.highlighted[1] then
        if (Game.play and #Game.play.cards > 0) or
            (self.locked) or
            (self.locks.frame) or
            (Game.GAME.STOP_USE and Game.GAME.STOP_USE > 0) then
            return
        end
        Game.hand:unhighlight_all()
    end
end

function Controller:L_cursor_press(x, y)
    x = x or self.cursor_position.x
    y = y or self.cursor_position.y

    if ((self.locked) and (not Game.SETTINGS.paused or Game.screenwipe)) or (self.locks.frame) then return end

    self.cursor_down.T = { x = x / (Game.TILESCALE * Game.TILESIZE), y = y / (Game.TILESCALE * Game.TILESIZE) }
    self.cursor_down.time = Game.TIMERS.TOTAL
    self.cursor_down.handled = false
    self.cursor_down.target = nil
    self.is_cursor_down = true

    local press_node = (self.HID.touch and self.cursor_hover.target) or self.hovering.target or self.focused.target

    if press_node then
        self.cursor_down.target = press_node.states.click.can and press_node or press_node:can_drag() or nil
    end

    if self.cursor_down.target == nil then
        self.cursor_down.target = Game.ROOM
    end
end

function Controller:L_cursor_release(x, y)
    x = x or self.cursor_position.x
    y = y or self.cursor_position.y

    if ((self.locked) and (not Game.SETTINGS.paused or Game.screenwipe)) or (self.locks.frame) then return end

    self.cursor_up.T = { x = x / (Game.TILESCALE * Game.TILESIZE), y = y / (Game.TILESCALE * Game.TILESIZE) }
    self.cursor_up.time = Game.TIMERS.TOTAL
    self.cursor_up.handled = false
    self.cursor_up.target = nil
    self.is_cursor_down = false

    self.cursor_up.target = self.hovering.target or self.focused.target

    if self.cursor_up.target == nil then
        self.cursor_up.target = Game.ROOM
    end
end

function Controller:is_node_focusable(node)
    local ret_val = false
    if node.T.y > Game.ROOM.T.h + 3 then return false end
    if not node.REMOVED and not node.under_overlay and (node.states.hover.can and not self.dragging.target or self.dragging.target == node) and
        (not not node.created_on_pause) == (not not Game.SETTINGS.paused) and
        (node.states.visible) and (not node.UIBox or node.UIBox.states.visible) then
        if self.screen_keyboard then
            if node.UIBox and node.UIBox == self.screen_keyboard and node.config.button then
                ret_val = true
            end
        else
            if node:is(Card) and (node.facing == 'front' or node.area == Game.hand or node.area == Game.jokers or (node == Game.deck)) and
                node.states.hover.can and not node.jimbo then
                ret_val = true
            end
            if node.config and node.config.force_focus then ret_val = true end
            if node.config and node.config.button then ret_val = true end
            if node.config and node.config.focus_args then
                if node.config.focus_args.type == 'none' or node.config.focus_args.funnel_from then
                    ret_val = false
                else
                    ret_val = true
                end
            end
        end
    end
    return ret_val
end

--essentially works like 'hovering' with any nodes that are focusable, but
--the nodes can also be navigated to via controller key inputs. If no direction is supplied,
--this function focuses on any nodes that collide with this cursor. If a direction is
--supplied, focuses on the nearest node in that direction.
function Controller:update_focus(dir)
    self.focused.prev_target = self.focused.target

    --Only needed when using a controller, hovering covers all KBM scenarios
    if not self.HID.controller or self.interrupt.focus or (self.locked) and (not Game.SETTINGS.paused or Game.screenwipe) then
        if self.focused.target then self.focused.target.states.focus.is = false end
        self.focused.target = nil
        return
    end

    Game.ARGS.focus_list = EMPTY(Game.ARGS.focus_list)
    Game.ARGS.focusables = EMPTY(Game.ARGS.focusables)

    -------------------------------------------------
    --  Find the focusable starting point
    -------------------------------------------------
    --First, is there currently a focusable target that is still valid?
    if self.focused.target then
        self.focused.target.states.focus.is = false

        --If that node is no longer focusable or if the cursor no longer collides with the node, remove the target
        if not self:is_node_focusable(self.focused.target) or not self.focused.target:collides_with_point(Game.CURSOR.T) or self.HID.axis_cursor then
            self.focused.target = nil
        end
    end

    --Now we check for 3 criteria:
    --1: is there a current focused target and no dpad direction? if so, we simply add the currsnt focused target to the focusable list and set the state to true
    --2: if not, and there is no dpad direction, iterate through the node list that the cursor intersects and check if any are focusable, only add the first one
    --3: if there is a direction, add all focusable moveables to the focusable list to check later
    if not dir and self.focused.target then
        self.focused.target.states.focus.can = true
        Game.ARGS.focusables[#Game.ARGS.focusables + 1] = self.focused.target
    else
        if not dir then
            for k, v in ipairs(self.nodes_at_cursor) do
                v.states.focus.can = false
                v.states.focus.is = false
                if #Game.ARGS.focusables == 0 and self:is_node_focusable(v) then
                    v.states.focus.can = true
                    Game.ARGS.focusables[#Game.ARGS.focusables + 1] = v
                end
            end
        else
            for k, v in pairs(Game.MOVEABLES) do
                v.states.focus.can = false
                v.states.focus.is = false
                if self:is_node_focusable(v) then
                    v.states.focus.can = true
                    Game.ARGS.focusables[#Game.ARGS.focusables + 1] = v
                end
            end
        end
    end

    --If there are any valid focusables
    if #Game.ARGS.focusables > 0 then
        --If a direction control is supplied, set the target to be the closest node in that direction
        if dir then
            if (dir == 'L' or dir == 'R') and self.focused.target and self.focused.target:is(Card) and self.focused.target.area == Game.hand and Game.hand then
                local nu_rank = self.focused.target.rank + (dir == 'L' and -1 or 1)
                if nu_rank > #Game.hand.cards then nu_rank = 1 end
                if nu_rank == 0 then nu_rank = #Game.hand.cards end
                if nu_rank ~= self.focused.target.rank then Game.ARGS.focus_list[1] = { node = Game.hand.cards[nu_rank] } end
            else
                --set the cursor position to where it currently is on screen
                Game.ARGS.focus_cursor_pos = Game.ARGS.focus_cursor_pos or {}
                Game.ARGS.focus_cursor_pos.x, Game.ARGS.focus_cursor_pos.y = Game.CURSOR.T.x - Game.ROOM.T.x,
                    Game.CURSOR.T.y - Game.ROOM.T.y

                --if there is a focused target, set the cursor to the midpoint
                if self.focused.target then
                    _ft = self.focused.target
                    if self.focused.target.config.focus_args and self.focused.target.config.focus_args.funnel_to then
                        _ft = self.focused.target.config.focus_args.funnel_to
                    end
                    Game.ARGS.focus_cursor_pos.x, Game.ARGS.focus_cursor_pos.y = _ft.T.x + 0.5 * _ft.T.w, _ft.T.y + 0.5 *
                        _ft.T.h
                    --if not but there is a focusable hovering target, put the cursor on it instead
                elseif self.hovering.target and self.hovering.target.states.focus.can then
                    Game.ARGS.focus_cursor_pos.x, Game.ARGS.focus_cursor_pos.y = self.hovering.target:put_focused_cursor()
                    Game.ARGS.focus_cursor_pos.x = Game.ARGS.focus_cursor_pos.x / (Game.TILESCALE * Game.TILESIZE) -
                        Game.ROOM.T.x
                    Game.ARGS.focus_cursor_pos.y = Game.ARGS.focus_cursor_pos.y / (Game.TILESCALE * Game.TILESIZE) -
                        Game.ROOM.T.y
                end

                --set the list to be all the nodes in that direction sorted by the closest node
                for _, v in pairs(Game.ARGS.focusables) do
                    if v ~= self.hovering.target and v ~= self.focused.target then
                        local eligible = false

                        if v.config.focus_args and v.config.focus_args.funnel_to then
                            v = v.config.focus_args.funnel_to
                        end

                        Game.ARGS.focus_vec = Game.ARGS.focus_vec or {}
                        Game.ARGS.focus_vec.x = v.T.x + 0.5 * v.T.w - (Game.ARGS.focus_cursor_pos.x)
                        Game.ARGS.focus_vec.y = v.T.y + 0.5 * v.T.h - (Game.ARGS.focus_cursor_pos.y)

                        if v.config.focus_args and v.config.focus_args.nav then
                            if v.config.focus_args.nav == 'wide' then
                                if Game.ARGS.focus_vec.y > 0.1 and dir == 'D' then
                                    eligible = true
                                elseif Game.ARGS.focus_vec.y < -0.1 and dir == 'U' then
                                    eligible = true
                                elseif math.abs(Game.ARGS.focus_vec.y) < v.T.h / 2 then
                                    eligible = true
                                end
                            elseif v.config.focus_args.nav == 'tall' then
                                if Game.ARGS.focus_vec.x > 0.1 and dir == 'R' then
                                    eligible = true
                                elseif Game.ARGS.focus_vec.x < -0.1 and dir == 'L' then
                                    eligible = true
                                elseif math.abs(Game.ARGS.focus_vec.x) < v.T.w / 2 then
                                    eligible = true
                                end
                            end
                        elseif math.abs(Game.ARGS.focus_vec.x) > math.abs(Game.ARGS.focus_vec.y) then
                            if Game.ARGS.focus_vec.x > 0 and dir == 'R' then
                                eligible = true
                            elseif Game.ARGS.focus_vec.x < 0 and dir == 'L' then
                                eligible = true
                            end
                        else
                            if Game.ARGS.focus_vec.y > 0 and dir == 'D' then
                                eligible = true
                            elseif Game.ARGS.focus_vec.y < 0 and dir == 'U' then
                                eligible = true
                            end
                        end

                        if eligible then
                            Game.ARGS.focus_list[#Game.ARGS.focus_list + 1] = {
                                node = v,
                                dist = math.abs(Game.ARGS.focus_vec.x) +
                                    math.abs(Game.ARGS.focus_vec.y)
                            }
                        end
                    end
                end
                if #Game.ARGS.focus_list < 1 then
                    if self.focused.target then self.focused.target.states.focus.is = true end
                    return
                end
                table.sort(Game.ARGS.focus_list, function(a, b) return a.dist < b.dist end)
            end
        else
            if self.focused.target then
                Game.ARGS.focus_list[#Game.ARGS.focus_list + 1] = { node = self.focused.target, dist = 0 }
            else
                --otherwise, get the focusable that collides
                Game.ARGS.focus_list[#Game.ARGS.focus_list + 1] = { node = Game.ARGS.focusables[1], dist = 0 }
            end
        end
    end

    --now with the lists created, set the focused target to be the first node in the list
    if Game.ARGS.focus_list[1] then
        if Game.ARGS.focus_list[1].node.config and Game.ARGS.focus_list[1].node.config.focus_args and Game.ARGS.focus_list[1].node.config.focus_args.funnel_from then
            self.focused.target = Game.ARGS.focus_list[1].node.config.focus_args.funnel_from
        else
            self.focused.target = Game.ARGS.focus_list[1].node
        end
        if self.focused.target ~= self.focused.prev_target then Game.VIBRATION = Game.VIBRATION + 0.7 end
    else
        self.focused.target = nil
    end

    if self.focused.target then self.focused.target.states.focus.is = true end
end

function Controller:capture_focused_input(button, input_type, dt)
    local ret = false
    local focused = self.focused.target
    local extern_button = false
    self.no_holdcap = nil

    --Implementing 'coyote time' type selection where a full button press isnt needed to select a card in hand. As long as a button down has been registered
    --before a timer is up and the dpad is used to move to the next card it should register
    if input_type == 'press' and (button == 'dpleft' or button == 'dpright') and
        focused and self.dragging.target and
        (self.held_button_times['a'] and self.held_button_times['a'] < 0.12) and
        focused.area and focused.area:can_highlight(focused) then
        self:L_cursor_release()
        self:navigate_focus(button == 'dpleft' and 'L' or 'R')
        self.held_button_times['a'] = nil
        self.COYOTE_FOCUS = true
        ret = true
    elseif input_type == 'press' and focused and focused.area and focused == self.dragging.target then
        focused.states.drag.is = false
        if button == 'dpleft' and focused.rank > 1 then
            focused.rank = focused.rank - 1
            focused.area.cards[focused.rank].rank = focused.rank + 1
            table.sort(focused.area.cards, function(a, b) return a.rank < b.rank end)
            focused.area:align_cards()
            self:update_cursor()
        elseif button == 'dpright' and focused.rank < #focused.area.cards then
            focused.rank = focused.rank + 1
            focused.area.cards[focused.rank].rank = focused.rank - 1
            table.sort(focused.area.cards, function(a, b) return a.rank < b.rank end)
            focused.area:align_cards()
            self:update_cursor()
        end
        focused.states.drag.is = true
        ret = true
    end

    if Game.OVERLAY_MENU and not self.screen_keyboard and input_type == 'press' and Game.OVERLAY_MENU:get_UIE_by_ID('tab_shoulders') and (button == 'leftshoulder' or button == 'rightshoulder') then
        focused = Game.OVERLAY_MENU:get_UIE_by_ID('tab_shoulders')
        extern_button = true
    end
    if Game.OVERLAY_MENU and not self.screen_keyboard and input_type == 'press' and Game.OVERLAY_MENU:get_UIE_by_ID('cycle_shoulders') and (button == 'leftshoulder' or button == 'rightshoulder') then
        focused = Game.OVERLAY_MENU:get_UIE_by_ID('cycle_shoulders').children[1]
        extern_button = true
    end
    if focused and focused.config.focus_args then
        if focused.config.focus_args.type == 'cycle' and input_type == 'press' then
            if ((extern_button and button == 'leftshoulder') or (not extern_button and button == 'dpleft')) then
                focused.children[1]:click()
                ret = true
            end
            if ((extern_button and button == 'rightshoulder') or (not extern_button and button == 'dpright')) then
                focused.children[3]:click()
                ret = true
            end
        end
        if focused.config.focus_args.type == 'tab' and input_type == 'press' then
            local proto_choices = focused.UIBox:get_group(nil, focused.children[1].children[1].config.group)
            local choices = {}
            for k, v in ipairs(proto_choices) do
                if v.config.choice and v.config.button then choices[#choices + 1] = v end
            end
            for k, v in ipairs(choices) do
                if v.config.chosen then
                    if ((extern_button and button == 'leftshoulder') or (not extern_button and button == 'dpleft')) then
                        local next_i = k ~= 1 and (k - 1) or (#choices)
                        if focused.config.focus_args.no_loop and next_i > k then
                            ret = nil
                        else
                            choices[next_i]:click()
                            self:snap_to({ node = choices[next_i] })
                            self:update_cursor()
                            ret = true
                        end
                    elseif ((extern_button and button == 'rightshoulder') or (not extern_button and button == 'dpright')) then
                        local next_i = k ~= #choices and (k + 1) or (1)
                        if focused.config.focus_args.no_loop and next_i < k then
                            ret = nil
                        else
                            choices[next_i]:click()
                            self:snap_to({ node = choices[next_i] })
                            self:update_cursor()
                            ret = true
                        end
                    end
                    break
                end
            end
        end
        if focused.config.focus_args.type == 'slider' then
            if button == 'dpleft' then
                self.no_holdcap = true
                if input_type == 'hold' and self.held_button_times[button] > 0.2 then
                    Game.FUNCS.slider_descreet(focused.children[1], -dt * self.held_button_times[button] * 0.6)
                end
                if input_type == 'press' then
                    Game.FUNCS.slider_descreet(focused.children[1], -0.01)
                end
                ret = true
            end
            if button == 'dpright' then
                self.no_holdcap = true
                if input_type == 'hold' and self.held_button_times[button] > 0.2 then
                    Game.FUNCS.slider_descreet(focused.children[1], dt * self.held_button_times[button] * 0.6)
                end
                if input_type == 'press' then
                    Game.FUNCS.slider_descreet(focused.children[1], 0.01)
                end
                ret = true
            end
        end
    end
    if ret == true then Game.VIBRATION = Game.VIBRATION + 1 end
    return ret
end

function Controller:navigate_focus(dir)
    --Get the corresponding focus target first, with or without a direction
    self:update_focus(dir)

    --Set the cursor to be in the correct position for that target
    self:update_cursor()
end
