local has_telescope, telescope = pcall(require, 'telescope')
local main = require("codefresh.main")

if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end

return telescope.register_extension {
  exports = {
    builds = main.builds
  },
}
