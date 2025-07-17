local M = {}

function M.get_cursor_pos(winid)
    winid = winid or vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(winid)
    cursor[1] = cursor[1] - 1 -- we always want line to be 0-indexed
    return cursor
end

function M.list_to_set(list)
    if list == nil then
        return nil
    end

    local set = {}
    for _, v in pairs(list) do
        set[v] = true
    end
    return set
end

function M.is_allowed(allow_list, deny_list, thing)
    if #allow_list == 0 and #deny_list == 0 then
        return true
    end

    if #deny_list > 0 then
        return not vim.tbl_contains(deny_list, thing)
    end

    return vim.tbl_contains(allow_list, thing)
end

function M.tbl_get(tbl, expected_type, ...)
    local cur = tbl
    for _, key in ipairs({ ... }) do
        if type(cur) ~= "table" or cur[key] == nil then
            return nil
        end

        cur = cur[key]
    end

    return type(cur) == expected_type and cur or nil
end

function M.has_keymap(mode, lhs)
    return vim.fn.mapcheck(lhs, mode) ~= ""
end

function M.get_visual_selection()
    local mode = vim.api.nvim_get_mode().mode
    if not (mode == "v" or mode == "V" or mode == "" or mode == "vs" or mode == "Vs" or mode == "s") then
        return nil
    end

    -- Get current cursor position and visual start
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local cursor_line = cursor_pos[1] - 1 -- Convert to 0-indexed
    local cursor_col = cursor_pos[2]

    -- Get visual start position using vim.fn.getpos('v') for real-time selection
    local visual_start = vim.fn.getpos("v")
    local start_line = visual_start[2] - 1 -- Convert to 0-indexed
    local start_col = visual_start[3] - 1 -- Convert to 0-indexed

    -- Determine actual start and end positions
    local sel_start_line, sel_start_col, sel_end_line, sel_end_col

    if start_line < cursor_line or (start_line == cursor_line and start_col <= cursor_col) then
        sel_start_line, sel_start_col = start_line, start_col
        sel_end_line, sel_end_col = cursor_line, cursor_col
    else
        sel_start_line, sel_start_col = cursor_line, cursor_col
        sel_end_line, sel_end_col = start_line, start_col
    end

    -- Check if selection spans multiple lines
    if sel_start_line ~= sel_end_line then
        return nil -- Don't highlight multi-line selections
    end

    -- Get the selected text
    local lines = vim.api.nvim_buf_get_lines(0, sel_start_line, sel_start_line + 1, false)
    if #lines == 0 then
        return nil
    end

    local selected_text = string.sub(lines[1], sel_start_col + 1, sel_end_col + 1)

    -- Don't highlight empty selections or selections with whitespace only
    if not selected_text or selected_text:match("^%s*$") then
        return nil
    end

    return {
        text = selected_text,
        start_pos = { sel_start_line, sel_start_col },
        end_pos = { sel_end_line, sel_end_col + 1 },
    }
end

function M.is_visual_mode()
    local mode = vim.api.nvim_get_mode().mode
    return mode == "v" or mode == "V" or mode == "" or mode == "vs" or mode == "Vs" or mode == "s"
end

return M
