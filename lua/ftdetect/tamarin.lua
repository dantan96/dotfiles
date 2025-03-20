-- Filetype detection for Tamarin Prover files
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = {"*.spthy", "*.sapic"},
  callback = function(args)
    -- Set filetype to tamarin
    vim.api.nvim_set_option_value("filetype", "tamarin", {buf = args.buf})
    
    -- Enable TreeSitter if available
    if pcall(require, "nvim-treesitter") then
      -- Try to use the spthy parser
      if pcall(vim.treesitter.language.inspect, "spthy") then
        -- Set the parser explicitly for this buffer
        pcall(function()
          vim.treesitter.start(args.buf, "spthy")
        end)
      end
    end
  end
}) 