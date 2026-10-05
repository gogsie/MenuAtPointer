-- MenuAtPointer
-- Show a macOS application's main menu at the mouse pointer.
--
-- If the pointer is over an inactive window, that window is focused first
-- and its application's menu is shown immediately.
--
-- Default trigger: Option + left-click
-- Requires Hammerspoon and Accessibility permission.

local triggerModifier = "alt"
local popup = hs.menubar.new(false)

local function copyPath(path, extra)
    local result = {}

    for i, value in ipairs(path) do
        result[i] = value
    end

    if extra then
        table.insert(result, extra)
    end

    return result
end

local function menuChildren(item)
    local children = item.AXChildren

    if not children then
        return nil
    end

    -- Some applications wrap menu items in anonymous Accessibility
    -- containers. Walk through those containers until we reach the
    -- actual menu entries.
    while #children == 1
        and type(children[1]) == "table"
        and children[1].AXTitle == nil
        and children[1][1] ~= nil do

        children = children[1]
    end

    return children
end

local function buildMenu(nodes, path, app)
    local result = {}

    if not nodes then
        return result
    end

    for _, item in ipairs(nodes) do
        if type(item) == "table" and item.AXTitle == nil then
            -- Anonymous container: flatten it into the current level.
            local nested = buildMenu(item, path, app)

            for _, value in ipairs(nested) do
                table.insert(result, value)
            end

        elseif type(item) == "table" then
            local title = item.AXTitle

            if title == nil or title == "" then
                table.insert(result, { title = "-" })
            else
                local newPath = copyPath(path, title)
                local children = menuChildren(item)

                local entry = {
                    title = title,
                    disabled = (item.AXEnabled == false),
                }

                if item.AXMenuItemMarkChar
                    and item.AXMenuItemMarkChar ~= "" then
                    entry.checked = true
                end

                if children and #children > 0 then
                    entry.menu = buildMenu(children, newPath, app)
                else
                    entry.fn = function()
                        app:selectMenuItem(newPath)
                    end
                end

                table.insert(result, entry)
            end
        end
    end

    return result
end

-- Return the topmost standard window underneath a screen point.
local function windowUnderPoint(point)
    for _, win in ipairs(hs.window.orderedWindows()) do
        if win:isStandard() then
            local frame = win:frame()

            if point.x >= frame.x
                and point.x <= frame.x + frame.w
                and point.y >= frame.y
                and point.y <= frame.y + frame.h then

                return win
            end
        end
    end

    return nil
end

local function showMenuForApp(app, point)
    if not app then
        return
    end

    app:getMenuItems(function(items)
        if not items then
            return
        end

        local menu = buildMenu(items, {}, app)
        popup:setMenu(menu)
        popup:popupMenu(point)
    end)
end

-- Keep the event tap global. Hammerspoon event taps can otherwise be
-- garbage-collected after the config has loaded.
if MenuAtPointerEventTap then
    MenuAtPointerEventTap:stop()
end

MenuAtPointerEventTap = hs.eventtap.new({
    hs.eventtap.event.types.leftMouseDown,
    hs.eventtap.event.types.leftMouseUp,
}, function(event)
    local flags = event:getFlags()

    -- Leave ordinary clicks completely alone.
    if not flags[triggerModifier] then
        return false
    end

    if event:getType() == hs.eventtap.event.types.leftMouseDown then
        local point = hs.mouse.absolutePosition()
        local win = windowUnderPoint(point)

        if win then
            local app = win:application()

            -- Focus the window under the pointer first. A short delay gives
            -- macOS time to update the active application's menu hierarchy.
            win:focus()

            hs.timer.doAfter(0.05, function()
                showMenuForApp(app, point)
            end)
        else
            -- If the pointer is not over a standard window, fall back to the
            -- application that is already active.
            showMenuForApp(hs.application.frontmostApplication(), point)
        end
    end

    -- Swallow the triggering click so the underlying application does
    -- not also receive it.
    return true
end)

MenuAtPointerEventTap:start()
