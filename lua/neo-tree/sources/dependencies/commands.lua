local cc = require("neo-tree.sources.common.commands")
local dependencies = require("neo-tree.sources.dependencies")
local manager = require("neo-tree.sources.manager")
local utils = require("neo-tree.utils")

local vim = vim

local M = {}

M.refresh = utils.wrap(manager.refresh, dependencies.name)
M.redraw = utils.wrap(manager.redraw, dependencies.name)

M.show_debug_info = function(state)
  print(vim.inspect(state))
end

cc._add_common_commands(M)
return M
