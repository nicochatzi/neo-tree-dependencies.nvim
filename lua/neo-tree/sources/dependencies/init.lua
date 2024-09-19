local vim = vim
local Path = require("plenary.path")
local utils = require("neo-tree.utils")
local renderer = require("neo-tree.ui.renderer")
local manager = require("neo-tree.sources.manager")
local events = require("neo-tree.events")
local log = require("neo-tree.log")

local suppliers = {
  cargo = require('neo-tree.sources.dependencies.suppliers.cargo'),
  -- python = require('neo-tree.sources.dependencies.suppliers.python'),
}

local M = {
  name = "dependencies",
  display_name = " Dependencies"
}

local Path = require("plenary.path") -- Assuming you are using Plenary for path management

---@param path string
local function build_file_tree(path)
  local items = {}
  local dir = vim.loop.fs_scandir(path)

  if not dir then
    return items
  end

  while true do
    local entry = vim.loop.fs_scandir_next(dir)
    if not entry then
      break
    end

    local full_path = Path:new(path):joinpath(entry):absolute()

    local node_type = vim.fn.isdirectory(full_path) == 1 and "directory" or "file"

    local node = {
      id = full_path,
      name = entry,
      type = node_type,
      path = full_path,
    }

    if node_type == "directory" then
      node.children = build_file_tree(full_path)
    end

    table.insert(items, node)
  end

  return items
end

local function update_view(dependencies, state)
  local items = {}

  for lang, deps in pairs(dependencies) do
    if #deps == 0 then
      goto continue
    end

    local lang_deps = {
      id = lang,
      name = lang,
      type = "directory",
      children = {}
    }

    for _, dep in ipairs(deps) do
      table.insert(lang_deps.children, {
        id = dep.path,
        name = dep.name .. " (" .. dep.version .. ")",
        type = "directory",
        children = build_file_tree(dep.path),
      })
    end

    table.insert(items, lang_deps)

    ::continue::
  end

  renderer.show_nodes(items, state)
end

---Navigate to the given path.
---@param path string Path to navigate to.
M.navigate = function(state, path)
  if path == nil then
    path = vim.fn.getcwd()
  end
  state.path = path

  local dependencies = {}
  for _name, supplier in pairs(suppliers) do
    supplier.find_async(vim.fn.getcwd(), function(deps)
      dependencies[supplier.get_name()] = deps
      vim.schedule(function()
        update_view(dependencies, state)
      end)
    end)
  end
end


---@class Config
--- @field follow_current_file boolean
---
---@param config Config
---
M.setup = function(config, global_config)
  -- if config.follow_current_file then
  --   manager.subscribe(M.name, {
  --     event = events.VIM_BUFFER_ENTER,
  --     handler = M.follow,
  --   })
  -- end
end

return M
