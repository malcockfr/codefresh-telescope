local codefresh_builds = require 'telescope._extensions.codefresh_builds'

return require 'telescope'.register_extension {
  exports = {
    codefresh_builds = codefresh_builds.codefresh_builds
  },
}
