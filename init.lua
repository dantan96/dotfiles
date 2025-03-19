-- Enable 24-bit RGB colors in the terminal
vim.opt.termguicolors = true

-- Save original notify function
_G._original_notify = vim.notify

-- Disable error messages during startup
vim.notify = (function(old_notify)
  return function(msg, level, opts)
    -- Ignore the tamarin parser error
    if msg and msg:match("Failed to load parser for language 'tamarin'") then
      return
    end
    old_notify(msg, level, opts)
  end
end)(vim.notify)

-- Set up filetype detection for Tamarin files - do this as early as possible
vim.filetype.add({
  extension = {
    spthy = "tamarin",
    sapic = "tamarin"
  },
})

-- Initialize Tamarin syntax highlighting module
pcall(function()
  require('config.tamarin-highlights').setup()
end)

-- Ensure syntax highlighting is used for Tamarin files
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "tamarin", "spthy" },
  callback = function()
    -- Force syntax highlighting
    vim.bo.syntax = "tamarin"
  end,
})

-- Restore normal notification after initialization
vim.defer_fn(function()
  vim.notify = _G._original_notify or vim.notify
end, 1000)

require("config.lazy")

-- Add command to clear session cache
vim.api.nvim_create_user_command("ClearSession", function()
  local session_dir = vim.fn.stdpath("data") .. "/sessions/"
  if vim.fn.isdirectory(session_dir) == 1 then
    vim.fn.delete(session_dir, "rf")
    vim.fn.mkdir(session_dir, "p")
    vim.notify("Session cache cleared", vim.log.levels.INFO)
  end
end, {})

vim.keymap.set("n", "<space><space>x", "<cmd>source %<CR>")
vim.keymap.set("n", "<space>x", "<cmd>:.lua<CR>")
vim.keymap.set("v", "<space>x", "<cmd>:lua<CR>")

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.wrap = false

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.keymap.set("n", "<leader>-", "<cmd>Oil<CR>")
vim.keymap.set("n", "<leader>vim", "<cmd>Oil ~/.config/nvim/<CR>")

local isLspDiagnosticsVisible = true
vim.keymap.set("n", "<leader>lx", function()
  isLspDiagnosticsVisible = not isLspDiagnosticsVisible
  vim.diagnostic.config({
    virtual_text = isLspDiagnosticsVisible,
    underline = isLspDiagnosticsVisible
  })
end)
