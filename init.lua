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
        if lang == "tamarin" then
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

-- Safely load the Tamarin parser to avoid startup errors
local function setup_tamarin_parser()
  -- Load tamarin-highlights without trying to load the parser yet
  require("config.tamarin-highlights").setup()

  -- Only try to load the parser when a Tamarin file is opened
  vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = { "*.spthy", "*.sapic" },
    callback = function()
      local parser_path = vim.api.nvim_get_runtime_file("parser/spthy/spthy.so", false)[1]
      if parser_path then
        -- Suppress error messages during parser loading
        local ok = pcall(function()
          vim.treesitter.language.add('spthy', { path = parser_path })
          vim.treesitter.language.register('spthy', 'tamarin')
        end)

        if ok then
          pcall(vim.treesitter.start, 0, 'spthy')
          vim.g.tamarin_treesitter_initialized = true
        end
      end
    end
  })
end

-- Setup without errors
pcall(setup_tamarin_parser)

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
