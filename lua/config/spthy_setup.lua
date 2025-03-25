-- spthy_setup.lua
-- A streamlined setup for Tamarin Security Protocol Theory (.spthy) files
-- This replaces the multiple files that were previously used

local M = {}

-- Setup function
function M.setup()
  -- 1. Register filetype directly in Neovim
  vim.filetype.add({
    extension = {
      spthy = "spthy",
      sapic = "spthy"
    },
  })

  -- 2. Add parser directory to runtimepath to ensure parser is found
  local parser_path = vim.fn.stdpath("config") .. "/parser"

  -- Check if the path is already in runtimepath
  local rtp = vim.opt.runtimepath:get()
  local in_rtp = false
  for _, path in ipairs(rtp) do
    if path == parser_path then
      in_rtp = true
      break
    end
  end

  -- Add to runtimepath if not already there
  if not in_rtp then
    vim.opt.runtimepath:prepend(parser_path)
  end

  -- 3. Ensure the parser is available and properly registered
  pcall(function()
    -- Check if spthy parser exists in site directory
    local parser_dir = vim.fn.stdpath('data') .. '/site/parser'
    local spthy_path = parser_dir .. '/spthy.so'

    -- Register language with TreeSitter if available
    if vim.fn.filereadable(spthy_path) == 1 and vim.treesitter and vim.treesitter.language then
      vim.treesitter.language.register('spthy', 'spthy')
    end
  end)

  -- 4. Setup highlights for spthy files
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "spthy",
    callback = function()
      -- Make sure tamarin-colors is loaded first
      local tc = require("config.tamarin-colors")
      tc.setup()

      -- Explicitly enable TreeSitter for this buffer
      pcall(function()
        if vim.treesitter and vim.treesitter.start then
          vim.treesitter.start(0, "spthy")
        elseif vim.fn.exists(':TSBufEnable') == 2 then
          vim.cmd('TSBufEnable highlight')
        end
      end)

      local highlights = tc.highlights
      for group, color in pairs(highlights) do
        local groupSuffix = string.sub(group, 2)
        local spthyGroup = "@spthy" .. groupSuffix
        vim.api.nvim_set_hl(0, spthyGroup, color)
      end
    end,
  })

  return true
end

return M
