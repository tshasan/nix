-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- Firefox lints TOML manifests, YAML and docs with its own rules, which taplo,
-- yamlls and markdownlint's defaults don't match, so formatting these on save
-- rewrites lines the patch never touched. <leader>cf still formats on demand.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("no_autoformat", { clear = true }),
  pattern = { "markdown", "toml", "yaml" },
  callback = function()
    vim.b.autoformat = false
  end,
})
