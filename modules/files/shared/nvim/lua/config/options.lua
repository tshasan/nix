-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.relativenumber = false
vim.opt.shortmess:append("A") -- suppress swap file "ATTENTION" (E325) prompts

-- No remote-plugin hosts installed; skip provider probing and checkhealth noise
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- Firefox build and test files that Neovim doesn't recognize on its own
vim.filetype.add({
  filename = {
    ["moz.build"] = "python",
    ["moz.configure"] = "python",
    ["jar.mn"] = "conf",
  },
  extension = {
    mozbuild = "python",
    sjs = "javascript",
    webidl = "idl",
  },
})
