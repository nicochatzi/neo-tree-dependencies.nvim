local Job = require("plenary.job")
local Path = require("plenary.path")

local M = {}

M.get_name = function()
  return " rust crates"
end

--- Asynchronously fetch Rust dependencies
---@param root_dir string
---@param on_done function
M.find_async = function(root_dir, on_done)
  if not Path:new(root_dir):joinpath("Cargo.toml"):exists() then
    on_done({})
    return
  end

  Job:new({
    command = "cargo",
    args = { "metadata", "--format-version", "1" },
    cwd = root_dir,
    on_exit = function(j, return_val)
      if return_val ~= 0 then
        on_done({})
        return
      end

      local result = table.concat(j:result(), "\n")

      local decoded = vim.json.decode(result)
      if not decoded or not decoded.packages then
        on_done({})
        return
      end

      local packages = {}

      for _, package in ipairs(decoded.packages) do
        table.insert(packages, {
          name = package.name,
          version = package.version,
          path = package.manifest_path:gsub("/Cargo.toml$", ""),
        })
      end

      on_done(packages)
    end,
  }):start()
end

return M
