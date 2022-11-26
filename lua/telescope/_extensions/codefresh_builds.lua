local ok, telescope = pcall(require, 'telescope')

if not ok then
  error "it's broken'"
end

local get_for_current_branch = require 'telescope._extensions.codefresh_builds.get_for_current_branch'

local default_opts = {}
local opts = default_opts

return telescope.register_extension {
  exports = {
    get_for_current_branch = function(_) get_for_current_branch(opts) end,
  },
}
