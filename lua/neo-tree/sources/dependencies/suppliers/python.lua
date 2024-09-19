local Job = require("plenary.job")

local M = {}

M.get_name = function()
  return " python packages"
end

---@param root_dir string
---@param on_done function
M.find_async = function(root_dir, on_done)
  local has_python_files = vim.fn.system("find " .. root_dir .. " -name '*.py' | head -n 1") ~= ""
  if not has_python_files then
    return {}
  end

  Job:new({
    command = "bash",
    args = { "-c", "pip freeze | cut -d'=' -f1 | xargs -I {} pip show {}" },
    on_exit = function(show_job, show_return_val)
      if show_return_val ~= 0 then
        on_done({})
        return
      end

      local result = {}
      local output = table.concat(show_job:result(), "\n")

      for package_info in output:gmatch("(Name:[^\n]+.-\nLocation:[^\n]+)") do
        local name = package_info:match("Name:%s*(%S+)")
        local version = package_info:match("Version:%s*(%S+)")
        local location = package_info:match("Location:%s*(%S+)")

        if name and version and location then
          table.insert(result, {
            name = name,
            version = version,
            path = location .. "/" .. name,
          })
        end
      end

      on_done(result)
    end,
    stdout_buffered = true,
    stderr_buffered = true,
  }):start()
end

return M
