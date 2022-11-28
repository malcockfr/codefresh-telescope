local has_telescope, telescope = pcall(require, 'telescope')

if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end

local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local utils = require("telescope.utils")
local sorters = require("telescope.sorters")

M = {}

local function branch_name()
  local branch = vim.fn.system("git branch --show-current 2> /dev/null | tr -d '\n'")
  if branch ~= "" then
    return branch
  else
    return ""
  end
end

local build_state = {
  running = "🚧",
  success = "✅",
  error = "❌",
  terminated = "☠️",
  terminating = "☠️",
  delayed = "✋",
  pending = "🚧",
  elected = "🗳️",
}

M.builds = function(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.fn.getcwd()

  local results = utils.get_os_command_output({
    "codefresh", "get", "builds", "--select-columns", "id,pipeline-name,status,started", "--branch",
    branch_name()
  }, opts.cwd)

  local entries = {}
  for _, build in ipairs(results) do
    local id, pipeline, status, started = string.match(build,
      "(%w+)%s*([%w%p]+)%s*([%w]+)%s*([%w%s%p]+)")
    if id ~= "ID" then
      table.insert(entries, { id, pipeline, status, started })
    end
  end

  pickers.new(opts, {
    prompt_title = string.format("Codefresh Builds for %s", branch_name()),
    finder = finders.new_table {
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry[1],
          display = string.format("%s - %s - %s", build_state[entry[3]], entry[4], entry[2]),
          ordinal = entry[3],
        }
      end
    },
    sorter = sorters.get_generic_fuzzy_sorter(),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.api.nvim_command("OpenBrowser https://g.codefresh.io/build/" .. selection.value)
      end)

      return true
    end,
  }):find()
end

-- M.builds()

return telescope.register_extension {
  exports = {
    codefresh = M.builds,
  },
}
