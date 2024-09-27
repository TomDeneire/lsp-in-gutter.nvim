local M = {}

local _default_icons = {}
_default_icons[vim.diagnostic.severity.ERROR] = " "
_default_icons[vim.diagnostic.severity.WARN] = " "
_default_icons[vim.diagnostic.severity.HINT] = " "
_default_icons[vim.diagnostic.severity.INFO] = " "

local _default_opts = {}
_default_opts["icons"] = _default_icons
_default_opts["show_icons"] = true
_default_opts["show_lnum"] = true
_default_opts["show_colors"] = true
-- formatter, e.g. `function format(diagnostic) return diagnostic.message end`
_default_opts["format"] = nil

function M.print_line_diagnostics()
    -- Add default options to user options
    local opts = vim.g.lspingutter_opts
    for key, _ in pairs(_default_opts) do
        if opts[key] == nil then opts[key] = _default_opts[key] end
    end

    -- Get diagnostics data
    local bufnr = vim.api.nvim_get_current_buf()
    local line_nr = vim.api.nvim_win_get_cursor(0)[1] - 1
    local diagnostics = vim.diagnostic.get(bufnr, { lnum = line_nr })

    if vim.tbl_isempty(diagnostics) then
        -- Clear gutter
        vim.api.nvim_echo({ { "", "" } }, false, {})
    else
        -- Prevent message overflowing gutter length
        -- Otherwise, neovim will focus on the gutter
        -- and require ENTER to quit
        local max_length = vim.o.columns - 20

        for _, diagnostic in ipairs(diagnostics) do
            local echo_mode = ""
            if opts["show_colors"] then
                if diagnostic.severity == vim.diagnostic.severity.ERROR then
                    echo_mode = "ErrorMsg"
                elseif diagnostic.severity == vim.diagnostic.severity.WARN then
                    echo_mode = "WarningMsg"
                end
            end

            local output = ""

            -- User-defined formatting
            if opts["format"] ~= nil then
                output = opts["format"](diagnostic)
            end

            -- Option-defined formatting
            if opts["format"] == nil then
                -- Replace newlines. Otherwise same scenario as gutter overflow
                local message = string.gsub(diagnostic.message, "\n", " ; ")

                if string.len(message) > max_length then
                    message = string.sub(message, 1, max_length) .. "..."
                end

                output = message
                if opts["show_lnum"] then
                    output = diagnostic.lnum + 1 .. ": " .. message
                end
                if opts["show_icons"] then
                    local icon = opts["icons"][diagnostic.severity]
                    output = icon .. output
                end
            end

            vim.api.nvim_echo({ { output, echo_mode } }, false, {})
        end
    end
end

return M