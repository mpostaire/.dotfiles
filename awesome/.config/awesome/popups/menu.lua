--------------------------------------------------------------------------------
--- A menu for awful.
--
-- @author Damien Leone &lt;damien.leone@gmail.com&gt;
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @author dodo
-- @copyright 2008, 2011 Damien Leone, Julien Danjou, dodo
-- @popupmod awful.menu
--------------------------------------------------------------------------------

local wibox = require("wibox")
local autoclose_wibox = require("util.autoclose_wibox")
local button = require("awful.button")
local gstring = require("gears.string")
local gtable = require("gears.table")
local timer = require("gears.timer")
local spawn = require("awful.spawn")
local tags = require("awful.tag")
local keygrabber = require("awful.keygrabber")
local client_iterate = require("awful.client").iterate
local beautiful = require("beautiful")
local dpi = require("beautiful").xresources.apply_dpi
local object = require("gears.object")
local surface = require("gears.surface")
local protected_call = require("gears.protected_call")
local cairo = require("lgi").cairo
local setmetatable = setmetatable
local tonumber = tonumber
local string = string
local ipairs = ipairs
local pairs = pairs
local print = print
local table = table
local type = type
local math = math
local capi = {
    screen = screen,
    mouse = mouse,
    client = client }
local screen = require("awful.screen")


local menu = { mt = {} }


local table_update = function (t, set)
    for k, v in pairs(set) do
        t[k] = v
    end
    return t
end

--- The icon used for sub-menus.
-- @beautiful beautiful.menu_submenu_icon
-- @tparam string|gears.surface menu_submenu_icon

--- The menu text font.
-- @beautiful beautiful.menu_font
-- @param string
-- @see string

--- The item height.
-- @beautiful beautiful.menu_height
-- @tparam[opt=16] number menu_height

--- The default menu width.
-- @beautiful beautiful.menu_width
-- @tparam[opt=100] number menu_width

--- The menu item border color.
-- @beautiful beautiful.menu_border_color
-- @tparam[opt=0] number menu_border_color

--- The menu item border width.
-- @beautiful beautiful.menu_border_width
-- @tparam[opt=0] number menu_border_width

--- The default focused item foreground (text) color.
-- @beautiful beautiful.menu_fg_focus
-- @param color
-- @see gears.color

--- The default focused item background color.
-- @beautiful beautiful.menu_bg_focus
-- @param color
-- @see gears.color

--- The default foreground (text) color.
-- @beautiful beautiful.menu_fg_normal
-- @param color
-- @see gears.color

--- The default background color.
-- @beautiful beautiful.menu_bg_normal
-- @param color
-- @see gears.color

--- The default sub-menu indicator if no menu_submenu_icon is provided.
-- @beautiful beautiful.menu_submenu
-- @tparam[opt="▶"] string menu_submenu The sub-menu text.
-- @see beautiful.menu_submenu_icon

--- Key bindings for menu navigation.
-- Keys are: up, down, exec, enter, back, close. Value are table with a list of valid
-- keys for the action, i.e. menu_keys.up =  { "j", "k" } will bind 'j' and 'k'
-- key to up action. This is common to all created menu.
-- @class table
-- @name menu_keys
menu.menu_keys = { up = { "Up" },
              down = { "Down" },
              back = { "Left" },
              exec = { "Return" },
              enter = { "Right" },
              close = { "Escape" } }


local function load_theme(a, b)
    a = a or {}
    b = b or {}
    local ret = {}
    local fallback = beautiful.get()
    if a.reset      then b = fallback end
    if a == "reset" then a = fallback end
    ret.border = a.border_color or b.menu_border_color or b.border_color_normal or
                 fallback.menu_border_color or fallback.border_color_normal
    ret.border_width= a.border_width or b.menu_border_width or b.border_width or
                      fallback.menu_border_width or fallback.border_width or dpi(0)
    ret.fg_focus = a.fg_focus or b.menu_fg_focus or b.fg_focus or
                   fallback.menu_fg_focus or fallback.fg_focus
    ret.bg_focus = a.bg_focus or b.menu_bg_focus or b.bg_focus or
                   fallback.menu_bg_focus or fallback.bg_focus
    ret.fg_normal = a.fg_normal or b.menu_fg_normal or b.fg_normal or
                    fallback.menu_fg_normal or fallback.fg_normal
    ret.bg_normal = a.bg_normal or b.menu_bg_normal or b.bg_normal or
                    fallback.menu_bg_normal or fallback.bg_normal
    ret.fg_disabled = a.fg_disabled or b.menu_fg_disabled or b.fg_disabled or
                    fallback.menu_fg_disabled or fallback.fg_disabled
    ret.bg_disabled = a.bg_disabled or b.menu_bg_disabled or b.bg_disabled or
                    fallback.menu_bg_disabled or fallback.bg_disabled
    ret.submenu_icon= a.submenu_icon or b.menu_submenu_icon or b.submenu_icon or
                      fallback.menu_submenu_icon or fallback.submenu_icon
    ret.submenu = a.submenu or b.menu_submenu or b.submenu or
                      fallback.menu_submenu or fallback.submenu or "⯈"
    ret.unchecked_icon = a.unchecked_icon or b.menu_unchecked_icon or b.unchecked_icon or
                      fallback.menu_unchecked_icon or fallback.unchecked_icon
    ret.unchecked = a.unchecked or b.menu_unchecked or b.unchecked or
                      fallback.menu_unchecked or fallback.unchecked or "☐"
    ret.checked_icon = a.checked_icon or b.menu_checked_icon or b.checked_icon or
                      fallback.menu_checked_icon or fallback.checked_icon
    ret.checked = a.checked or b.menu_checked or b.checked or
                      fallback.menu_checked or fallback.checked or "☑"
    ret.height = a.height or b.menu_height or b.height or
                 fallback.menu_height or dpi(16)
    ret.width = a.width or b.menu_width or b.width or
                fallback.menu_width or dpi(100)
    ret.max_width = a.max_width or b.menu_max_width or b.max_width or
                    fallback.menu_max_width or dpi(500)
    ret.font = a.font or b.font or fallback.menu_font or fallback.font
    ret.separator_color = a.separator_color or b.menu_separator_color or
                            fallback.menu_separator_color or ret.border
    ret.separator_span_ratio = a.separator_span_ratio or b.menu_separator_span_ratio or
                            fallback.menu_separator_span_ratio or 1
    ret.separator_spacing = a.separator_spacing or b.menu_separator_spacing or
                            fallback.menu_separator_spacing or dpi(0)
    ret.separator_thickness = a.separator_thickness or b.menu_separator_thickness or
                            fallback.menu_separator_thickness or dpi(1)
    ret.submenu_timer = a.submenu_timer or b.menu_submenu_timer or
                                fallback.menu_submenu_timer or 0.2
    ret.disable_icons = a.disable_icons or b.menu_disable_icons or
                                fallback.menu_disable_icons or false
    for _, prop in ipairs({"width", "height", "menu_width", "max_width"}) do
        if type(ret[prop]) ~= "number" then ret[prop] = tonumber(ret[prop]) end
    end
    return ret
end


local function item_position(_menu, child)
    local a, b = "height", "width"
    local dir = _menu.layout.dir or "y"
    if dir == "x" then  a, b = b, a  end

    local in_dir, other = 0, _menu[b]
    local num = gtable.hasitem(_menu.child, child)
    if num then
        for i = 0, num - 1 do
            local item = _menu.items[i]
            if item then
                other = math.max(other, item[b])
                in_dir = in_dir + item[a]
            end
        end
    end
    local w, h = other, in_dir
    if dir == "x" then  w, h = h, w  end
    return w, h
end


local function set_coords(_menu, s, m_coords)
    local s_geometry = s.workarea
    local screen_w = s_geometry.x + s_geometry.width
    local screen_h = s_geometry.y + s_geometry.height

    _menu.width = _menu.wibox.width
    _menu.height = _menu.wibox.height

    _menu.x = _menu.wibox.x
    _menu.y = _menu.wibox.y

    if _menu.parent then
        local w, h = item_position(_menu.parent, _menu)
        w = w + _menu.parent.theme.border_width

        _menu.y = _menu.parent.y + h + _menu.height > screen_h and
                 screen_h - _menu.height or _menu.parent.y + h
        _menu.x = _menu.parent.x + w + _menu.width > screen_w and
                 _menu.parent.x - _menu.width or _menu.parent.x + w
    else
        if m_coords == nil then
            m_coords = capi.mouse.coords()
            m_coords.x = m_coords.x + 1
            m_coords.y = m_coords.y + 1
        end
        _menu.y = m_coords.y < s_geometry.y and s_geometry.y or m_coords.y
        _menu.x = m_coords.x < s_geometry.x and s_geometry.x or m_coords.x

        _menu.y = _menu.y + _menu.height > screen_h and
                 screen_h - _menu.height or _menu.y
        _menu.x = _menu.x + _menu.width  > screen_w and
                 screen_w - _menu.width  or _menu.x
    end

    _menu.wibox.x = _menu.x
    _menu.wibox.y = _menu.y
end


local function set_size(_menu)
    local in_dir, other, a, b = 0, 0, "height", "width"
    local dir = _menu.layout.dir or "y"
    if dir == "x" then  a, b = b, a  end
    for _, item in ipairs(_menu.items) do
        other = math.max(other, item[b])
        in_dir = in_dir + item[a]
    end
    _menu[a], _menu[b] = in_dir, other
    if in_dir > 0 and other > 0 then
        _menu.wibox[a] = in_dir
        _menu.wibox[b] = other
        return true
    end
    return false
end


local function check_access_key(_menu, key)
   for i, item in ipairs(_menu.items) do
      if not item.disabled and item.akey == key then
            _menu:item_enter(i)
            _menu:exec(i, { exec = true })
            return
      end
   end
   if _menu.parent then
      check_access_key(_menu.parent, key)
   end
end


local function grabber(_menu, _, key, event)
    if event ~= "press" then return end

    local sel = _menu.sel or 0
    if gtable.hasitem(menu.menu_keys.up, key) then
        local sel_new, num_items, iter = sel, #_menu.items, 0
        repeat
            sel_new = sel_new-1 < 1 and num_items or sel_new-1
            iter = iter + 1
        until _menu:item_enter(sel_new) == 0 or iter >= num_items
    elseif gtable.hasitem(menu.menu_keys.down, key) then
        local sel_new, num_items, iter = sel, #_menu.items, 0
        repeat
            sel_new = sel_new+1 > #_menu.items and 1 or sel_new+1
            iter = iter + 1
        until _menu:item_enter(sel_new) == 0 or iter >= num_items
        _menu:item_enter(sel_new)
    elseif sel > 0 and gtable.hasitem(menu.menu_keys.enter, key) then
        _menu:exec(sel)
    elseif sel > 0 and gtable.hasitem(menu.menu_keys.exec, key) then
        _menu:exec(sel, { exec = true })
    elseif gtable.hasitem(menu.menu_keys.back, key) then
        _menu:hide()
    elseif gtable.hasitem(menu.menu_keys.close, key) then
        menu.get_root(_menu):hide()
    else
        check_access_key(_menu, key)
    end
end


function menu:exec(num, opts)
    opts = opts or {}
    local item = self.items[num]
    if not item or item.disabled then return end
    local cmd = item.cmd
    if type(cmd) == "table" then
        if cmd.generator then
            -- we put the generated submenu inside item.cmd to cache it for next time
            -- TODO make it generate after timer and not before ???? or not ?? check kde implem
            item.cmd = cmd.generator()
            cmd = item.cmd
        end
        if cmd.hide_callback then
            self.hide_callback = cmd.hide_callback
        end
        local action = cmd.cmd
        if #cmd == 0 then
            if opts.exec and action and type(action) == "function" then
                action()
            end
            return
        end
        if not self.child[num] then
            self.child[num] = menu.new(cmd, self)
        end
        local can_invoke_action = opts.exec and
            action and type(action) == "function" and
            (not opts.mouse or (opts.mouse and (self.auto_expand or
            (self.active_child == self.child[num] and
            self.active_child.wibox.visible))))
        if can_invoke_action then
            local visible = action(self.child[num], item)
            if not visible then
                menu.get_root(self):hide()
                return
            else
                self.child[num]:update() -- TODO what does it do ???
            end
        end
        if self.active_child and self.active_child ~= self.child[num] then
            self.active_child:hide()
        end
        self.active_child = self.child[num]
        if not self.active_child.wibox.visible then
            if opts.mouse then
                -- TODO make timer object at menu creation and reuse it when needed
                
                if self._timer then
                    self._timer:again()
                else
                    self.active_child:show()
                end
                
            else
                self.active_child:show({sel = 1})
            end
        end
    elseif type(cmd) == "string" then
        menu.get_root(self):hide()
        spawn(cmd)
    elseif type(cmd) == "function" then
        local visible, action = cmd(item, self)
        if not visible then
            menu.get_root(self):hide()
        else
            self:update()
            if self.items[num] then
                self:item_enter(num, opts)
            end
        end
        if action and type(action) == "function" then
            action()
        end
    end
end

function menu:item_enter(num, opts)
    opts = opts or {}
    local item = self.items[num]
    if num == nil or self.sel == num or not item then
        return 2
    elseif self.sel then
        self:item_leave(self.sel)
    end
    --print("sel", num, menu.sel, item.theme.bg_focus)
    if not item.disabled then
        item._background:set_fg(item.theme.fg_focus)
        item._background:set_bg(item.theme.bg_focus)
    end
    self.sel = num

    if self.auto_expand and opts.hover then
        if self.active_child then
            self.active_child:hide()
            self.active_child = nil
        end

        if type(item.cmd) == "table" then
            self:exec(num, opts)
        end
    end

    return item.disabled and 1 or 0
end


function menu:item_leave(num)
    --print("leave", num)
    if self._timer and self._timer.started then self._timer:stop() end
    local item = self.items[num]
    if item and not item.disabled then
        item._background:set_fg(item.theme.fg_normal)
        item._background:set_bg(item.theme.bg_normal)
    end
end


--- Show a menu.
-- @param args The arguments
-- @param args.coords Menu position defaulting to mouse.coords()
-- @method show
function menu:show(args)
    args = args or {}
    local coords = args.coords or nil
    local s = capi.screen[screen.focused()]

    if not set_size(self) then return end
    set_coords(self, s, coords)

    keygrabber.run(self._keygrabber)
    self:item_enter(args.sel or 0)
    self.wibox.visible = true
end

--- Hide a menu popup.
-- @method hide
function menu:hide()
    -- Remove items from screen
    for i = 1, #self.items do
        self:item_leave(i)
    end
    if self.active_child then
        self.active_child:hide()
        self.active_child = nil
    end
    self.sel = nil

    keygrabber.stop(self._keygrabber)
    self.wibox.visible = false

    if self.hide_callback then self.hide_callback() end
end

--- Toggle menu visibility.
-- @param args The arguments
-- @param args.coords Menu position {x,y}
-- @method toggle
function menu:toggle(args)
    if self.wibox.visible then
        self:hide()
    else
        self:show(args)
    end
end

--- Update menu content.
-- @method update
function menu:update()
    if self.wibox.visible then
        self:show({ coords = { x = self.x, y = self.y } })
    end
end


--- Get the elder parent so for example when you kill
-- it, it will destroy the whole family.
-- @method get_root
function menu:get_root()
    return self.parent and menu.get_root(self.parent) or self
end

--- Add a new menu entry.
-- args.* params needed for the menu entry constructor.
-- @param args The item params
-- @param args.new (Default: awful.menu.entry) The menu entry constructor.
-- @param[opt] args.theme The menu entry theme.
-- @param[opt] index The index where the new entry will inserted.
-- @method add
function menu:add(args, index)
    if not args then return end
    local theme = load_theme(args.theme or {}, self.theme)
    args.theme = theme
    args.new = args.new or menu.entry
    local item = protected_call(args.new, self, args)
    -- TODO this case is when an item is invisible (better implement the invisible state ?)
    if item == 1 then return end
    if (not item) or (not item.widget) then
        print("Error while checking menu entry: no property widget found.")
        return
    end
    item.parent = self
    item.theme = item.theme or theme
    item.width = item.width or theme.width
    item.height = item.height or theme.height
    wibox.widget.base.check_widget(item.widget)
    item._background = wibox.container.background()
    item._background.forced_height = item.height
    item._background:set_widget(item.widget)
    if item.disabled then
        item._background:set_fg(item.theme.fg_disabled)
        item._background:set_bg(item.theme.bg_disabled)
    else
        item._background:set_fg(item.theme.fg_normal)
        item._background:set_bg(item.theme.bg_normal)

        -- Create bindings
        local function on_click()
            local num = gtable.hasitem(self.items, item)
            self:item_enter(num, { mouse = true })
            self:exec(num, { exec = true, mouse = true })
        end
        item._background.buttons = {
            button({}, 3, _, on_click),
            button({}, 1, _, on_click)
        }
    end

    item._mouse = function ()
        local num = gtable.hasitem(self.items, item)
        self:item_enter(num, { hover = true, mouse = true })
    end
    item.widget:connect_signal("mouse::enter", item._mouse)

    if index then
        self.layout:reset()
        table.insert(self.items, index, item)
        for _, i in ipairs(self.items) do
            self.layout:add(i._background)
        end
    else
        table.insert(self.items, item)
        self.layout:add(item._background)
    end
    if self.wibox then
        set_size(self)
    end

    return item
end

--- Delete menu entry at given position.
-- @param num The position in the table of the menu entry to be deleted; can be also the menu entry itself.
-- @method delete
function menu:delete(num)
    if type(num) == "table" then
        num = gtable.hasitem(self.items, num)
    end
    local item = self.items[num]
    if not item then return end
    item.widget:disconnect_signal("mouse::enter", item._mouse)
    item.widget:set_visible(false)
    table.remove(self.items, num)
    if self.sel == num then
        self:item_leave(self.sel)
        self.sel = nil
    end
    self.layout:reset()
    for _, i in ipairs(self.items) do
        self.layout:add(i._background)
    end
    if self.child[num] then
        self.child[num]:hide()
        if self.active_child == self.child[num] then
            self.active_child = nil
        end
        table.remove(self.child, num)
    end
    if self.wibox then
        set_size(self)
    end
end

--------------------------------------------------------------------------------

--- Default awful.menu.entry constructor.
-- @param parent The parent menu
-- @param args the item params
-- @return table with 'widget', 'cmd', 'akey' and all the properties the user wants to change
-- @constructorfct awful.menu.entry
function menu.entry(parent, args) -- luacheck: no unused args
    args = args or {}
    args.invisible = args[5] or args.invisible
    if args.invisible then return 1 end
    args.text = args[1] or args.text or ""
    args.cmd = args[2] or args.cmd
    args.icon = args[3] or args.icon
    args.disabled = args[4] or args.disabled
    args.separator = args[6] or args.separator
    args.toggle_state = args[7] or args.toggle_state
    local ret = {}
    
    if args.separator then
        local widget = wibox.widget {
            {
                color = args.theme.separator_color,
                thickness = args.theme.separator_thickness,
                span_ratio = args.theme.separator_span_ratio,
                widget = wibox.widget.separator
            },
            top = args.theme.separator_spacing,
            bottom = args.theme.separator_spacing,
            widget = wibox.container.margin
        }

        return table_update(ret, {
            widget = widget,
            height = args.theme.separator_thickness + (2 * args.theme.separator_spacing),
            disabled = true
        })
    end

    local iconbox
    if args.toggle_state == 0 or args.toggle_state == 1 then
        iconbox = wibox.widget {
            text = args.toggle_state == 0 and (args.theme.unchecked_icon or args.theme.unchecked) or
                    (args.theme.checked_icon or args.theme.checked),
            align = "center",
            font = args.theme.font,
            forced_width = args.theme.height or dpi(25),
            widget = wibox.widget.textbox
        }
    else
        iconbox = wibox.widget {
            image = not args.theme.disable_icons and args.icon or nil,
            forced_width = args.theme.height or dpi(25),
            widget = wibox.widget.imagebox
        }
    end
    
    local key = ''
    local label = wibox.widget {
        markup = string.gsub(
            gstring.xml_escape(args.text), "(_+)(%w?)",
            function (l, ll)
                local len = #l
                if key == '' and len % 2 == 1 then
                    key = string.lower(ll)
                    return "<u>" .. ll .. "</u>"
                else
                    -- use math.floor(a / b) here because luajit doesn't support the // operator
                    return l:sub(0, math.floor(len / 2)) .. ll
                end
            end
        ),
        font = args.theme.font,
        widget = wibox.widget.textbox
    }

    local submenu
    if args.theme.submenu_icon then
        submenu = wibox.widget {
            image = type(args.cmd) == "table" and args.theme.submenu_icon or nil,
            forced_width = args.theme.height or dpi(25),
            widget = wibox.widget.imagebox
        }
    else
        submenu = wibox.widget {
            text = type(args.cmd) == "table" and args.theme.submenu or nil,
            align = "center",
            font = args.theme.font,
            forced_width = args.theme.height or dpi(25),
            widget = wibox.widget.textbox
        }
    end

    local layout = wibox.widget {
        {
            iconbox,
            margins = dpi(2),
            widget = wibox.container.margin
        },
        {
            label,
            margins = dpi(2),
            widget = wibox.container.margin
        },
        {
            submenu,
            margins = dpi(2),
            widget = wibox.container.margin
        },
        layout = wibox.layout.align.horizontal
    }

    return table_update(ret, {
        label = label,
        sep = submenu,
        icon = iconbox,
        widget = layout,
        cmd = args.cmd,
        akey = key,
        width = math.min(
            label:get_preferred_size(capi.screen[screen.focused()]) +
            iconbox.forced_width + submenu.forced_width +
            6 * dpi(2), args.theme.max_width
        ),
        disabled = args.disabled
    })
end

--------------------------------------------------------------------------------

--- Create a menu popup.
-- @param args Table containing the menu informations.
--
-- * Key items: Table containing the displayed items. Each element is a table by default (when element 'new' is
--   awful.menu.entry) containing: item name, triggered action (submenu table or function), item icon (optional).
-- * Keys theme.[fg|bg]_[focus|normal], theme.border_color, theme.border_width, theme.submenu_icon, theme.height
--   and theme.width override the default display for your menu and/or of your menu entry, each of them are optional.
-- * Key auto_expand controls the submenu auto expand behaviour by setting it to true (default) or false.
--
-- @param parent Specify the parent menu if we want to open a submenu, this value should never be set by the user.
-- @constructorfct awful.menu
-- @usage -- The following function builds and shows a menu of clients that match
-- -- a particular rule.
-- -- Bound to a key, it can be used to select from dozens of terminals open on
-- -- several tags.
-- -- When using @{ruled.client.match_any} instead of @{ruled.client.match},
-- -- a menu of clients with different classes could be build.
--
-- function terminal_menu ()
--   terms = {}
--   for i, c in pairs(client.get()) do
--     if ruled.client.match(c, {class = "URxvt"}) then
--       terms[i] =
--         {c.name,
--          function()
--            c.first_tag:view_only()
--            client.focus = c
--          end,
--          c.icon
--         }
--     end
--   end
--   awful.menu(terms):show()
-- end
function menu.new(args, parent)
    args = args or {}
    args.layout = args.layout or wibox.layout.fixed.vertical
    local _menu = table_update(object(), {
        item_enter = menu.item_enter,
        item_leave = menu.item_leave,
        get_root = menu.get_root,
        delete = menu.delete,
        update = menu.update,
        toggle = menu.toggle,
        hide = menu.hide,
        show = menu.show,
        exec = menu.exec,
        add = menu.add,
        child = {},
        items = {},
        parent = parent,
        layout = args.layout(),
        theme = load_theme(args.theme or {}, parent and parent.theme) })

    if parent then
        _menu.auto_expand = parent.auto_expand
    elseif args.auto_expand ~= nil then
        _menu.auto_expand = args.auto_expand
    else
        _menu.auto_expand = true
    end

    -- TODO vertical scrollable contents if screen space too short. Maybe take inspiration of my inputlist
    --      arrow widgets on top and bottom of menu. when hover scroll by 1 in corresponding direction and repeat with timer
    --      as long as mouse is hovering. check firefox menus for example
    _menu.wibox = autoclose_wibox {
        close_callback = function()
            if _menu == _menu:get_root() and type(args.close_callback) == "function" then
                args.close_callback()
            end
            _menu:hide()
        end,
        mouse_free_area = args.mouse_free_area,
        ontop = true,
        fg = _menu.theme.fg_normal,
        bg = _menu.theme.bg_normal,
        border_color = _menu.theme.border,
        border_width = _menu.theme.border_width,
        parent = parent and parent.wibox or nil,
        visible = false,
        type = "popup_menu"
    }
    _menu.wibox:set_widget(_menu.layout)
    
    -- unselect item when mouse leave menu
    _menu.wibox:connect_signal("mouse::leave", function()
        if not _menu.active_child or not _menu.active_child.wibox.visible then
            _menu:item_leave(_menu.sel)
            _menu.sel = nil
        end
    end)

    if _menu.theme.submenu_timer > 0 then
        _menu._timer = timer {
            timeout = _menu.theme.submenu_timer,
            autostart = false,
            call_now = false,
            callback = function()
                _menu.active_child:show()
            end,
            single_shot = true
        }
    end

    -- Create items
    for _, v in ipairs(args) do  _menu:add(v)  end
    if args.items then
        for _, v in pairs(args.items) do  _menu:add(v)  end
    end

    _menu._keygrabber = function (...)
        grabber(_menu, ...)
    end

    set_size(_menu)

    _menu.x = _menu.wibox.x
    _menu.y = _menu.wibox.y
    return _menu
end

function menu.mt:__call(...)
    return menu.new(...)
end

return setmetatable(menu, menu.mt)
