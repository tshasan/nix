-- Everything specific to working on Firefox. Delete this file to drop it all.

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

-- Firefox lints TOML manifests, YAML and docs with its own rules, which taplo,
-- yamlls and markdownlint's defaults don't match, so formatting these on save
-- rewrites lines the patch never touched. <leader>cf still formats on demand.
-- Only inside a Firefox checkout (it has mach at the root); other repos keep format on save.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("no_autoformat", { clear = true }),
  pattern = { "markdown", "toml", "yaml" },
  callback = function(args)
    if vim.fs.root(args.buf, "mach") then
      vim.b[args.buf].autoformat = false
    end
  end,
})

-- moz.build and moz.configure run in mach's sandbox, which injects globals like
-- DIRS and Files that pyright reports as undefined on nearly every line.
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("mozbuild_diagnostics", { clear = true }),
  pattern = { "moz.build", "moz.configure", "*.mozbuild" },
  callback = function(args)
    vim.diagnostic.enable(false, { bufnr = args.buf })
  end,
})

return {}
