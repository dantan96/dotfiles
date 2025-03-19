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

-- Add parser and query directories to runtimepath
vim.opt.runtimepath:append(vim.fn.stdpath('config') .. '/parser')
vim.opt.runtimepath:append(vim.fn.stdpath('config') .. '/parser/spthy')
vim.opt.runtimepath:append(vim.fn.stdpath('config') .. '/queries')

-- Set up filetype detection for Tamarin files - do this as early as possible
vim.filetype.add({
  extension = {
    spthy = "tamarin",
    sapic = "tamarin"
  },
})

-- Suppress errors from the treesitter module
vim.schedule(function()
  local old_require = require

  -- Use pcall to handle the case when tamarin is requested but not available
  _G.require = function(modname)
    if modname == "vim.treesitter.language" then
      local ok, mod = pcall(old_require, modname)
      if not ok then return nil end

      -- Override the require_language function to handle missing parsers
      local old_require_language = mod.require_language
      mod.require_language = function(lang, path)
        if lang == "tamarin" or lang == "spthy" then
          -- Silently skip tamarin language if parser not found
          if not path or vim.fn.filereadable(path) == 0 then
            return false
          end
        end
        return old_require_language(lang, path)
      end

      return mod
    end
    return old_require(modname)
  end

  -- Restore the original require after startup
  vim.defer_fn(function()
    _G.require = old_require
  end, 1000)
end)

-- Initialize Tamarin TreeSitter integration on startup
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    local tamarin_ok, tamarin = pcall(require, "tamarin")
    if tamarin_ok then
      tamarin.cleanup() -- Clean up any previous setup
      tamarin.setup()
    end
  end,
  once = true,
})

-- Restore normal notification after initialization
vim.defer_fn(function()
  vim.notify = _G._original_notify or vim.notify
end, 1000)

require("config.lazy")

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
