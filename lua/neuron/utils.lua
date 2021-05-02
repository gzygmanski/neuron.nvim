local api = vim.api
local uv = vim.loop
local Job = require("plenary/job")

local M = {}

function M.path_from_id(id, neuron_dir, callback)
  assert(id, "the id should not be nil")

  Job:new {
    command = "neuron",
    args = {"query", "--id", id, "--cached"},
    cwd = neuron_dir,
    on_stderr = M.on_stderr_factory("neuron query --id"),
    on_stdout = vim.schedule_wrap(function(error, data)
      assert(not error, error)

      local path = vim.fn.json_decode(data).result.zettelPath
      callback(path)
    end)
  }:start()
end

function M.on_stderr_factory(name)
  return vim.schedule_wrap(function(error, data)
    assert(not error, error)
    vim.cmd(string.format("echoerr 'An error occured from running %s: %s'", name, data))
  end)
end

function M.on_exit_factory(name)
  return vim.schedule_wrap(function(self, code, _signal)
    if code ~= 0 then
      error(string.format("The job %s exited with a non-zero code: %s", name, code))
    end
  end)
end

function M.feedkeys(string, mode)
  api.nvim_feedkeys(api.nvim_replace_termcodes(string, true, true, true), mode, true)
end

function M.feedraw(s)
  api.nvim_feedkeys(s, 'n', false)
end

local LINK_CHECK = "%[%[%[?[A-Za-z0-9._%+-]+%]%]%]?"
local LINK = "[A-Za-z0-9._%+-]+"

function M.match_link(s)
  if s:match(LINK_CHECK) then return s:match(LINK_CHECK):match(LINK) end
end

function M.find_link(s)
  if s:match(LINK_CHECK) then return s:find(LINK_CHECK) end
end

-- deletes a range of extmarks line wise, zero based index
function M.delete_range_extmark(buf, namespace, start, finish)
  local extmarks = api.nvim_buf_get_extmarks(buf, namespace, {start, 0}, {finish, 0}, {})
  for _, v in ipairs(extmarks) do
    api.nvim_buf_del_extmark(buf, namespace, v[1])
  end
end

function M.os_open(path)
  local os = uv.os_uname().sysname

  local open_cmd
  if os == "Linux" then
    open_cmd = "xdg-open"
  elseif os == "Windows" then
    open_cmd = "start"
  elseif os == "Darwin" then
    open_cmd = "open"
  end

  Job:new {
    command = open_cmd,
    args = {path},
    on_stderr = M.on_stderr_factory(open_cmd),
  }:start()
end

function M.get_localhost_address(s)
  return s:gsub('.+(:%d+)', 'localhost%1')
end

function M.get_current_id()
  return vim.fn.expand("%:t:r")
end

function M.start_insert_header()
  M.feedkeys("Go<CR>#<space>", 'n')
end

return M
