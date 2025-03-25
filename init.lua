-- Enable 24-bit RGB colors in the terminal
vim.opt.termguicolors = true

-- Set up filetype detection for Tamarin files - do this as early as possible
vim.filetype.add({
    extension = {
        spthy = "spthy",
        sapic = "spthy"
    },
})
-- log("Registered Tamarin filetype")

-- Setup spthy support with the streamlined module
pcall(function()
    require('config.spthy_setup').setup()
end)

-- Load lazy.nvim plugin manager
-- log("Loading plugin manager")
require("config.lazy")
-- log("Plugin manager loaded")

-- General keymaps
vim.keymap.set("n", "<space><space>x", "<cmd>source %<CR>")
vim.keymap.set("n", "<space>x", "<cmd>:.lua<CR>")
vim.keymap.set("v", "<space>x", "<cmd>:lua<CR>")

-- Basic editor settings
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.wrap = false

-- Highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

-- Oil.nvim keymaps
vim.keymap.set("n", "<leader>-", "<cmd>Oil<CR>")
vim.keymap.set("n", "<leader>vim", "<cmd>Oil ~/.config/nvim/<CR>")

-- General keymaps
vim.keymap.set({ "n", "v" }, "<leader>p", '"+p', { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "<Esc><Esc>", "<Esc><cmd>nohlsearch<CR><Esc>", { noremap = true, silent = true })

-- Toggle diagnostics
local isLspDiagnosticsVisible = true
vim.keymap.set("n", "<leader>lx", function()
    isLspDiagnosticsVisible = not isLspDiagnosticsVisible
    vim.diagnostic.config({
        virtual_text = isLspDiagnosticsVisible,
        underline = isLspDiagnosticsVisible
    })
end)

-- Add TreeSitter info command
pcall(function()
    require('ts_info').setup()
end)
