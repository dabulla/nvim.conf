-- overseer_ant.lua
-- Runs `ant build -Dtarget=<proj> -Dconfig=<cfg>` from nearest "cn1"
-- LazyVim: require("custom.overseer_ant") after overseer.setup{}

local overseer = require("overseer")

-- ───── helpers ──────────────────────────────────────────────────────
local function walk_up(start, pred)
  local dir = vim.fn.fnamemodify(start, ":p")
  local count = 25
  while dir ~= "" and dir ~= "/" and count > 0 do
	count = count - 1
	if vim.fn.isdirectory(dir .. "/cn1")==1 then
	  if pred(dir .. "/cn1") then
	    return dir .. "/cn1"
	  end
	end
	if pred(dir) then
	  return dir
	end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
end
local function nearest_vcxproj(dir)
  local folder = walk_up(dir, function(d)
    return not vim.tbl_isempty(vim.fn.globpath(d, "*.vcxproj", false, true))
  end)
  if folder then
    return vim.fn.globpath(folder, "*.vcxproj", false, true)[1]
  end
end
local function nearest_cn1(dir)
  return walk_up(dir, function(d) return vim.fn.isdirectory(d .. "/cn1")==1 end)
end

-- ───── builder ──────────────────────────────────────────────────────
local function ant_builder(p)
  local file_dir = vim.fn.expand("%:p:h")
  local cwd = (nearest_cn1(file_dir) or vim.fn.getcwd()) .. "/cn1"

  local target = p.target
  if not target or target == "" then
    local proj = nearest_vcxproj(file_dir)
    target = proj and vim.fn.fnamemodify(proj, ":t:r") or "MyTest"
  end
  local config = p.config and p.config ~= "" and p.config or "Debug"

  return {
    name = ("ant build (%s | %s)"):format(target, config),
    cmd  = "ant",
    args = { "build", "-Dtarget=" .. target, "-Dconfig=" .. config },
    cwd  = cwd,
    components = {
      { "on_output_quickfix", open = not vim.api.nvim_get_option_value("diff", {}) },
      "default",
    },
  }
end

local param_schema = {
  target = { type = "string", optional = true,
             desc = "Project/target name (default = nearest .vcxproj or MyTest)" },
  config = { type = "enum",   default  = "Debug",
             choices = { "Debug", "Release" },
             desc = "Build configuration" },
}

-- ───── template 1: current buffer ───────────────────────────────────
overseer.register_template({
  name      = "Build Current (ant)",
  priority  = 60,
  condition = { filetype = { "c","cpp","objc","objcpp","cs","h","hpp" } },
  builder   = ant_builder,
  params    = param_schema,
})

-- ───── template 2: choose from solution ─────────────────────────────
overseer.register_template({
  name      = "Build Project (choose from solution)",
  priority  = 50,
  builder   = ant_builder,     -- each generated entry uses this
  params    = param_schema,    -- 🔑 add schema so defaults are valid
  condition = {
    callback = function()
      return walk_up(vim.fn.expand("%:p:h"), function(d)
        return not vim.tbl_isempty(vim.fn.globpath(d, "*.sln", false, true))
      end) ~= nil
    end,
  },
  generator = function(_, cb)
    local sln_dir = walk_up(vim.fn.expand("%:p:h"), function(d)
      return not vim.tbl_isempty(vim.fn.globpath(d, "*.sln", false, true))
    end)
    if not sln_dir then return cb(nil) end
    local sln = vim.fn.globpath(sln_dir, "*.sln", true, true)[1]

    local projects = {}
    for line in io.lines(sln) do
      local n,pth = line:match('Project%([^=]+=%s+"([^"]+)"%s*,%s*"([^"]+)"')
      if n and pth and pth:match("%.vcxproj$") then table.insert(projects, n) end
    end
    if vim.tbl_isempty(projects) then return cb(nil) end

    local out = {}
    for _,name in ipairs(projects) do
      table.insert(out, {
        name    = ("Build %s (ant)"):format(name),
        builder = ant_builder,
        params  = {
          target = { type = "string", optional = false,
                     default = name,
                     value = name,
                     desc = "Project/target name (default = nearest .vcxproj or MyTest)" },
          config = { type = "enum",   default  = "Debug",
                     choices = { "Debug", "Release" },
                     desc = "Build configuration" },
        },
      })
    end
    cb(out)
  end,
})

return {}
