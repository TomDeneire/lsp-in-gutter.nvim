local diagnostics = require("lsp-in-gutter.diagnostics")

local M = {}

-- Track which buffers have our autocmd
local attached_bufs = {}

M.setup = function(user_options)
    user_options = user_options or {}
    diagnostics.configure(user_options)

    vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lspingutter', { clear = true }),
        callback = function(event)
            local client = vim.lsp.get_client_by_id(event.data.client_id)
            if not client then return end

            local buf = event.buf
            if not attached_bufs[buf] then
                attached_bufs[buf] = vim.api.nvim_create_autocmd("CursorHold", {
                    buffer = buf,
                    callback = diagnostics.print_line_diagnostics,
                })
            end
        end,
    })

    vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('lspingutter-detach', { clear = true }),
        callback = function(event)
            local buf = event.buf
            -- Check if any LSP clients remain on this buffer
            local remaining = vim.lsp.get_clients({ bufnr = buf })
            -- The detaching client is still counted, so check for <= 1
            if #remaining <= 1 and attached_bufs[buf] then
                vim.api.nvim_del_autocmd(attached_bufs[buf])
                attached_bufs[buf] = nil
                vim.api.nvim_echo({ { "", "" } }, false, {})
            end
        end,
    })
end

return M
