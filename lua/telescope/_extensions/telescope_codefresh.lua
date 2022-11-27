local has_telescope, telescope = pcall(require, 'telescope')
local cf = require("codefresh.codefresh")

if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end

return telescope.register_extension {
  exports = {
    builds = cf.builds
  },
}
