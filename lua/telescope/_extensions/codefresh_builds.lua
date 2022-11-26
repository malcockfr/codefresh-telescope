local ok, telescope = pcall(require, 'telescope')

if not ok then
  error "it's broken'"
end

return telescope.register_extension {
  setup = function(ext_config, config)
  end,
  exports = {
    codefresh_builds = require("telescope._extensions.codefresh_builds").codefresh_builds
  },
}
