local M = {}

local _default_icons = {
    [vim.diagnostic.severity.ERROR] = " ",
    [vim.diagnostic.severity.WARN] = " ",
    [vim.diagnostic.severity.HINT] = " ",
    [vim.diagnostic.severity.INFO] = " ",
}

local _default_opts = {
    icons = _default_icons,
    show_icons = true,
    show_lnum = true,
    show_colors = true,
    format = nil,
}

local _opts = {}

local _highlight_map = {
    [vim.diagnostic.severity.ERROR] = "ErrorMsg",
    [vim.diagnostic.severity.WARN] = "WarningMsg",
    [vim.diagnostic.severity.HINT] = "DiagnosticHint",
    [vim.diagnostic.severity.INFO] = "DiagnosticInfo",
}

function M.configure(user_options)
    _opts = vim.tbl_deep_extend("keep", user_options, _default_opts)
end

local function _sort_diagnostics(diags)
    local severity_order = {
        [vim.diagnostic.severity.ERROR] = 1,
        [vim.diagnostic.severity.WARN] = 2,
        [vim.diagnostic.severity.HINT] = 3,
        [vim.diagnostic.severity.INFO] = 4,
    }

    table.sort(diags, function(a, b)
        local a_order = severity_order[a.severity] or 999
        local b_order = severity_order[b.severity] or 999
        return a_order < b_order
    end)

    return diags
end

function M.print_line_diagnostics()
    local bufnr = vim.api.nvim_get_current_buf()
    local line_nr = vim.api.nvim_win_get_cursor(0)[1] - 1
    local diags = vim.diagnostic.get(bufnr, { lnum = line_nr })
    diags = _sort_diagnostics(diags)

    if vim.tbl_isempty(diags) then
        vim.api.nvim_echo({ { "", "" } }, false, {})
        return
    end

    local diagnostic = diags[1]

    -- Determine highlight
    local echo_hl = ""
    if _opts.show_colors then
        echo_hl = _highlight_map[diagnostic.severity] or ""
    end

    -- Build prefix (icon + line number) to account for its length
    local prefix = ""
    if _opts.show_icons then
        prefix = _opts.icons[diagnostic.severity] or ""
    end
    if _opts.show_lnum then
        prefix = prefix .. (diagnostic.lnum + 1) .. ": "
    end

    -- Max length for the full output (prefix + message)
    local max_length = vim.o.columns - 20
    local max_message_length = max_length - vim.fn.strdisplaywidth(prefix)

    local output
    if _opts.format ~= nil then
        output = _opts.format(diagnostic)
    else
        -- Replace newlines to avoid gutter overflow
        output = string.gsub(diagnostic.message, "\n", " ; ")
    end

    if vim.fn.strdisplaywidth(output) > max_message_length then
        -- Truncate by characters; approximate for multibyte
        output = string.sub(output, 1, max_message_length - 3) .. "..."
    end

    vim.api.nvim_echo({ { prefix .. output, echo_hl } }, false, {})
end

return M
