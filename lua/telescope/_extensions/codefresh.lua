return require("telescope").register_extension {
  exports = {
    builds = require("codefresh_telescope").builds
  },
}
