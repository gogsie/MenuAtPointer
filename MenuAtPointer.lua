-- MenuAtPointer
-- Show the frontmost macOS application's main menu at the mouse pointer.
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

local function showMenuAtPointer(point)
    local app = hs.application.frontmostApplication()

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

    -- Option + left-click (by default) opens the application menu.
    if event:getType() == hs.eventtap.event.types.leftMouseDown then
        showMenuAtPointer(hs.mouse.absolutePosition())
    end

    -- Swallow the triggering click so the underlying application does
    -- not also receive it.
    return true
end)

MenuAtPointerEventTap:start()
