# Telescope_codefresh

Simple Telescope extension to view Codefresh builds for you current Git branch.

## Install

### Lunarvim

Add the extensions top your list of plugins:
```
lvim.plugins = {
  ...
  { "malcockfr/telescope_codefresh",
    requires = { "tyru/open-browser.vim" },
  }
} 
```

Then run `:PackerSync` to install it.

## Setup

Tell Telescope to load the extension
```
lvim.builtin.telescope.on_config_done = function(telescope)
  telescope.load_extension "codefresh"
end
```

## Using it :)

To view builds for your current Git branch simply run
```
:Telescope codefresh builds
```

The default action (enter) will open the build in the Codefresh UI.


## TODO
* Fix timeout issue with the codefresh command
* Add more actions to terminate, restart a buiid
* Add new picker to list pipelines and start builds
* Add previwer to show build logs
