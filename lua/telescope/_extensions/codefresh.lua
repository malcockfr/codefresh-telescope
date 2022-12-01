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

local M = {}

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

local restartable = {
  terminating = true,
  terminated = true,
  error = true,
  success = true,
}

local check_y_or_n = function(prompt, yes_func)
  vim.ui.select({ 'Yes', 'No' }, {
    prompt = prompt,
  }, function(choice)
    if choice == 'Yes' then
      yes_func()
    else
      print("Backing away slowly!!")
    end
  end)
end

local terminate_build = function(id)
  check_y_or_n(
    string.format("Are you sure you want to terminate build ID %s? (y/N) ", id),
    function()
      local cwd = vim.fn.getcwd()
      utils.get_os_command_output({ "codefresh", "terminate", id }, cwd)
      print(vim.fn.printf("Terminating build ID %s", id))
    end)
end

local restart_build = function(entry)
  if not restartable[entry.state] then
    print(string.format("Build %s is not restartable", entry.value))
    return
  end
  check_y_or_n(
    string.format("Are you sure you want to restart build ID %s? (y/N) ", entry.value),
    function()
      local cwd = vim.fn.getcwd()
      utils.get_os_command_output({ "codefresh", "restart", entry }, cwd)
      print(vim.fn.printf("Restarting build ID %s", entry.value))
    end)
end

local get_builds = function()
  local cwd = vim.fn.getcwd()
  local results = utils.get_os_command_output({
    "codefresh", "get", "builds", "--select-columns", "id,status,started,pipeline-name", "--branch",
    branch_name()
  }, cwd)

  local entries = {}
  for _, build in ipairs(results) do
    local id, pipeline, status, started = string.match(build,
      "(%w+)%s*(%w+)%s*(%d+-%d+-%d+,%s%d+:%d+:%d+)%s*([%w%p]+)")
    if id ~= "ID" then
      table.insert(entries, { id, pipeline, status, started })
    end
  end
  return entries
end

local get_pipelines = function()
  local cwd = vim.fn.getcwd()
  local results = utils.get_os_command_output({
    "codefresh", "get", "pipelines", "--all", "--select-columns", "name"
  }, cwd)

  local entries = {}
  for _, pipeline in ipairs(results) do
    local project, name = string.match(pipeline, "([%w%p]+)/([%w%p]+)")
    if not string.match(pipeline, "NAME") then
      table.insert(entries, { project, name })
    end
  end
  return entries
end

local refresh_finder = function(prompt_bufnr, finder)
  vim.notify("Refreshing...")
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  current_picker:refresh(finder, {})
end

M.get_builds = function(opts)
  local results = M.build_finder()
  pickers.new(opts, {
    prompt_title = string.format("Codefresh Builds for %s", branch_name()),
    sorter = sorters.get_generic_fuzzy_sorter(),
    finder = finders.new_table {
      results = results,
      entry_maker = function(entry)
        return {
          value = entry[1],
          display = string.format("%s - %s - %s", build_state[entry[2]], entry[3], entry[4]),
          ordinal = entry[4],
          state = entry[2],
        }
      end
    },
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.api.nvim_command("OpenBrowser https://g.codefresh.io/build/" .. selection.value)
      end)
      actions.terminate = function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        terminate_build(selection.value)
      end
      actions.restart = function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        restart_build(selection)
      end
      actions.logs = function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.cmd(string.format("9TermExec cmd='codefresh logs -f %s'", selection.value))
      end

      map('n', 'x', actions.terminate)
      map('n', 'r', actions.restart)
      map('n', 'l', actions.logs)
      map('n', 'R', refresh_finder(prompt_bufnr, get_builds))

      return true
    end,
  }):find()
end

M.get_pipelines = function(opts)
  pickers.new(opts, {
    prompt_title = string.format("Codefresh Pipelines"),
    finder = finders.new_table {
      results = get_pipelines(),
      entry_maker = function(entry)
        return {
          value = string.format("%s/%s", entry[1], entry[2]),
          display = string.format("%s/%s", entry[1], entry[2]),
          ordinal = entry[2],
          project = entry[1],
          name = entry[2],
        }
      end
    },
    sorter = sorters.get_generic_fuzzy_sorter(),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.api.nvim_command(string.format("OpenBrowser https://g.codefresh.io/pipelines/all/?filter=pageSize:10;field:name~Name;order:asc~Asc;search:%s;projects:%s"
          , selection.name, selection.project))
      end)
      return true
    end,
  }):find()
end

return telescope.register_extension {
  exports = {
    codefresh = M.get_builds,
    builds = M.get_builds,
    pipelines = M.get_pipelines,
  },
}
