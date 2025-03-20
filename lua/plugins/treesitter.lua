return {
  -- Core nvim-treesitter plugin configuration
  -- Provides syntax highlighting, indentation, and more using tree-sitter parsers
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate", -- Automatically update parsers on plugin updates
  priority = 1000, -- Load treesitter early in the startup process
  lazy = false, -- Disable lazy loading to ensure immediate availability
  
  -- Plugin dependencies
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
  },

  config = function()
    -- Basic treesitter setup
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        -- Shell/Terminal
        "bash",
        "fish",
        "make",
        "awk",
        "cmake",
        "dockerfile",
        
        -- Web Development
        "css",
        "html",
        "javascript",
        "json",
        "tsx",
        "typescript",
        "yaml",
        
        -- Systems Programming
        "c",
        "cpp",
        "rust",
        "go",
        
        -- Functional Programming
        "haskell",
        "ocaml",
        
        -- Scripting
        "lua",
        "luadoc",
        "python",
        "ruby",
        
        -- Documentation/Config
        "markdown",
        "markdown_inline",
        "regex",
        "toml",
        "vim",
        "vimdoc",
      },
      auto_install = false,     -- Prevent automatic installation of new parsers
      notify_install = false,   -- Disable installation notifications
      highlight = { enable = true },
      indent = { enable = true },
    })

    -- Add parser path to runtimepath
    local parser_path = vim.fn.stdpath("config") .. "/parser"
    vim.opt.runtimepath:append(parser_path)

    -- Register the spthy parser if it exists
    local spthy_parser_path = parser_path .. "/spthy.so"
    if vim.fn.filereadable(spthy_parser_path) == 1 then
      -- Direct language registration 
      pcall(function()
        vim.treesitter.language.register('spthy', 'spthy')
      end)
      
      -- Also add the parser for spthy
      pcall(function()
        vim.treesitter.language.add('spthy', {
          path = spthy_parser_path
        })
      end)
      
      -- Ensure the parser can be loaded
      pcall(function()
        vim.treesitter.language.require_language("spthy")
      end)
    end
  end,
}
