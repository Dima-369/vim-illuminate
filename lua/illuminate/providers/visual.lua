local util = require("illuminate.util")
local config = require("illuminate.config")

local M = {}

function M.is_ready(bufnr)
    return util.is_visual_mode()
end

function M.get_references(bufnr, cursor_pos)
    local visual_selection = util.get_visual_selection()
    if not visual_selection then
        return {}
    end

    local text = visual_selection.text

    -- Early exit: Don't process if text is empty or too long
    -- (visual_selection already checks max length, but double-check for safety)
    if not text or text == "" or #text > config.visual_max_length() then
        return {}
    end

    -- Early exit: Don't process if text contains newlines
    if text:find('\n') or text:find('\r') then
        return {}
    end

    local references = {}

    -- Get all lines in the buffer
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- Search for matches in each line
    for line_idx, line in ipairs(lines) do
        local start_col = 1
        while true do
            local match_start, match_end = string.find(line, vim.pesc(text), start_col, true)
            if not match_start then
                break
            end

            -- Convert to 0-indexed positions
            local start_pos = { line_idx - 1, match_start - 1 }
            local end_pos = { line_idx - 1, match_end }

            table.insert(references, { start_pos, end_pos })
            start_col = match_end + 1
        end
    end

    return references
end

function M.initiate_request(bufnr, winid)
    -- No async request needed for visual mode
end

return M

