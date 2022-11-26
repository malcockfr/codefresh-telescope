local codefresh_telescope = require 'telescope._extensions.codefresh_telescope'

return require 'telescope'.register_extension {
  exports = {
    codefresh_telescope = codefresh_telescope.builds
  },
}
