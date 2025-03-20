-- Improved Tamarin filetype detection

-- Define an autocommand group for Tamarin filetype detection
local augroup = vim.api.nvim_create_augroup("TamarinFileTypeDetection", { clear = true })

-- Detect Tamarin files
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = augroup,
  pattern = { "*.spthy", "*.sapic" },
  callback = function()
    -- Set the filetype to spthy
    vim.bo.filetype = "spthy"
    
    -- Log the detection if debug mode is enabled
    if vim.fn.isdirectory('/tmp/tamarin-debug') == 1 then
      local log_file = io.open("/tmp/tamarin-debug/ftdetect.log", "a")
      if log_file then
        log_file:write(os.date("%Y-%m-%d %H:%M:%S") .. " Detected spthy filetype for: " .. vim.fn.expand("%:p") .. "\n")
        log_file:close()
      end
    end
  end,
})

-- For backwards compatibility with older Neovim versions, add the ftdetect command
vim.cmd([[
  au BufRead,BufNewFile *.spthy setfiletype spthy
  au BufRead,BufNewFile *.sapic setfiletype spthy
]])

