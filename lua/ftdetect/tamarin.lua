-- Filetype detection for Tamarin Prover files
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = {"*.spthy", "*.sapic"},
  callback = function(args)
    -- Set filetype to tamarin
    vim.api.nvim_set_option_value("filetype", "tamarin", {buf = args.buf})
    
    -- Create filetype-to-parser mapping for TreeSitter
    local parsers = require("nvim-treesitter.parsers")
    if parsers then
      -- Register 'tamarin' filetype to use 'spthy' parser
      if not parsers.get_parser_configs().tamarin then
        parsers.get_parser_configs().tamarin = {
          install_info = {
            url = "none", -- No installation required, using spthy directly
            files = {},
          },
          -- This is the key part - map tamarin filetype to spthy parser
          used_by = { "tamarin" },
        }
      end
      
      -- Attempt to start TreeSitter with the 'spthy' parser for tamarin files
      pcall(function()
        vim.treesitter.start(args.buf, "spthy")
      end)
    end
  end
}) 