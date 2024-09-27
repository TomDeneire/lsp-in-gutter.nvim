-- Imports the plugin's additional Lua modules.
local diagnostics = require("lsp-in-gutter.diagnostics")

-- Creates an object for the module. All of the module's
-- functions are associated with this object, which is
-- returned when the module is called with `require`.

local M = {}

M.init = function()
    if not vim.g.lspingutter_namespace then
        vim.g.lspingutter_namespace = vim.api.nvim_create_namespace("lspingutter")
    end
end

-- Setup with user configuration
M.setup = function(user_options)
    vim.g.lspingutter_opts = user_options
    vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lspingutter', { clear = true }),
        callback = function(event)
            if vim.lsp.get_client_by_id(event.data.client_id) then
                vim.api.nvim_create_autocmd({ "CursorHold" }, {
                    group = vim.api.nvim_create_augroup('lspingutter-attach', { clear = true }),
                    callback = diagnostics.print_line_diagnostics
                })
                vim.api.nvim_create_autocmd('LspDetach', {
                    group = vim.api.nvim_create_augroup('lspingutter-detach', { clear = true }),
                    callback = function(event2)
                        vim.lsp.buf.clear_references()
                        vim.api.nvim_clear_autocmds { group = 'lspingutter-attach', buffer = event2.buf }
                    end,
                })
            end
        end,
    })
end

return M
