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

local function phab_notify(message, level)
  vim.notify(message, level or vim.log.levels.WARN, { title = "Phabricator" })
end

local function phab_open(url)
  local _, err = vim.ui.open(url)
  if err then
    phab_notify("Could not open the revision: " .. tostring(err))
  end
end

local function phab_run(argv, root, callback)
  local ok = pcall(
    vim.system,
    argv,
    { cwd = root, text = true, timeout = 30000 },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        phab_notify(argv[1] .. " failed (exit " .. result.code .. "). Run the command in a terminal for details.")
        return
      end
      callback(result.stdout or "")
    end)
  )
  if not ok then
    phab_notify("Could not start " .. argv[1] .. ". Check that it is installed and on PATH.")
  end
end

vim.api.nvim_create_user_command("Phab", function(args)
  local action = args.fargs[1] or "list"
  local revision = args.fargs[2]
  if
    (action ~= "list" and action ~= "current" and action ~= "open")
    or (action == "open" and (not revision or not revision:match("^D[1-9]%d*$")))
    or (action ~= "open" and revision)
    or #args.fargs > 2
  then
    phab_notify("Use :Phab list, :Phab current, or :Phab open D123")
    return
  end
  local root = vim.fs.root(0, "mach") or vim.fs.root(vim.fn.getcwd(), "mach")
  if not root then
    phab_notify("Run Phab from a Firefox checkout (mach was not found).")
    return
  end
  -- Read the server from the checkout, as moz-phab does.
  local ok, arcconfig = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(root .. "/.arcconfig"), "\n"))
  end)
  local phab_url = ok and type(arcconfig) == "table" and arcconfig["phabricator.uri"]
  if type(phab_url) ~= "string" or not phab_url:match("^https://.+/$") then
    phab_notify("Could not read phabricator.uri from the checkout's .arcconfig.")
    return
  end
  if action == "open" then
    phab_open(phab_url .. revision)
  elseif action == "current" then
    phab_run({ "git", "log", "-1", "--format=%B" }, root, function(body)
      for line in body:gmatch("[^\r\n]+") do
        local id = line:match("^Differential Revision:%s+" .. vim.pesc(phab_url) .. "(D[1-9]%d*)/?%s*$")
        if id then
          phab_open(phab_url .. id)
          return
        end
      end
      phab_notify("HEAD has no Mozilla Differential Revision footer.")
    end)
  else
    phab_run({ "moz-phab", "list", "--format", "json" }, root, function(stdout)
      local ok, revisions = pcall(vim.json.decode, stdout)
      if not ok or type(revisions) ~= "table" or not vim.islist(revisions) then
        phab_notify("moz-phab returned an invalid revision list.")
        return
      end
      for _, item in ipairs(revisions) do
        if
          type(item) ~= "table"
          or not tostring(item.id):match("^[1-9]%d*$")
          or type(item.title) ~= "string"
          or type(item.status) ~= "string"
          or item.uri ~= phab_url .. "D" .. tostring(item.id)
        then
          phab_notify("moz-phab returned an unexpected revision format.")
          return
        end
      end
      if #revisions == 0 then
        phab_notify("No in-flight revisions found.", vim.log.levels.INFO)
        return
      end
      vim.ui.select(revisions, {
        prompt = "My Phabricator revisions",
        format_item = function(item)
          return ("D%s [%s] %s"):format(item.id, item.status, item.title)
        end,
      }, function(item)
        if item then
          phab_open(item.uri)
        end
      end)
    end)
  end
end, {
  nargs = "*",
  desc = "Browse Mozilla Phabricator revisions",
  complete = function(_, line)
    return #vim.split(line, "%s+") <= 2 and { "list", "current", "open" } or {}
  end,
})

return {
  {
    "LazyVim/LazyVim",
    keys = {
      { "<leader>rp", "<cmd>Phab list<cr>", desc = "My Phabricator revisions" },
      { "<leader>ro", "<cmd>Phab current<cr>", desc = "Open HEAD on Phabricator" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          root_dir = function(bufnr, on_dir)
            local name = vim.fs.basename(vim.api.nvim_buf_get_name(bufnr))
            -- mach injects globals into these DSL files. Keep Ruff and other
            -- diagnostics available without attaching Python's type checker.
            if name == "moz.build" or name == "moz.configure" or name:match("%.mozbuild$") then
              return
            end
            on_dir(vim.fs.root(bufnr, vim.lsp.config.pyright.root_markers))
          end,
          before_init = function(_, config)
            if config.root_dir and vim.fs.root(config.root_dir, "mach") then
              local analysis = config.settings.python.analysis
              -- Explicit excludes replace Pyright's defaults; retain those
              -- while pruning generated Firefox build trees before enumeration.
              analysis.exclude = vim.list_extend(
                vim.deepcopy(analysis.exclude or { "**/node_modules", "**/__pycache__", "**/.*" }),
                { "**/obj-*" }
              )
            end
          end,
        },
      },
    },
  },
}
