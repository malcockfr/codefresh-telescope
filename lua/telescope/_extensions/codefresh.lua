return require("telescope").register_extension {
  exports = {
    builds = require("codefresh.builds").get
  },
}
