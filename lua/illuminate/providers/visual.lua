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
    local max_matches = config.visual_max_matches()
    local total_lines = vim.api.nvim_buf_line_count(bufnr)
    
    -- For large files, consider viewport-only searching or respect large_file_cutoff
    local start_line, end_line
    if config.visual_viewport_only() or (config.large_file_cutoff() and total_lines > config.large_file_cutoff()) then
        -- Get viewport range with some padding
        local winid = vim.api.nvim_get_current_win()
        local win_start = vim.fn.line('w0', winid) - 1  -- Convert to 0-indexed
        local win_end = vim.fn.line('w$', winid) - 1    -- Convert to 0-indexed
        local padding = math.min(100, math.floor(total_lines * 0.1)) -- 10% of file or 100 lines
        
        start_line = math.max(0, win_start - padding)
        end_line = math.min(total_lines - 1, win_end + padding)
    else
        start_line = 0
        end_line = total_lines - 1
    end

    -- Get lines in the search range
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)

    -- Search for matches in each line
    for line_offset, line in ipairs(lines) do
        local line_idx = start_line + line_offset - 1  -- Convert back to absolute line number
        local start_col = 1
        
        while true do
            -- Early exit if we've found enough matches
            if #references >= max_matches then
                return references
            end
            
            local match_start, match_end = string.find(line, vim.pesc(text), start_col, true)
            if not match_start then
                break
            end

            -- Convert to 0-indexed positions
            local start_pos = { line_idx, match_start - 1 }
            local end_pos = { line_idx, match_end }

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

