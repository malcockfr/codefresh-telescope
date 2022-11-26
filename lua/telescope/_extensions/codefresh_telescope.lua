local codefresh_telescope = require 'telescope._extensions.codefresh_telescope'

return require 'telescope'.register_extension {
  exports = {
    builds = codefresh_telescope.builds
  },
}
