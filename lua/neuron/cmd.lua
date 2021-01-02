local api = vim.api
local utils = require("neuron/utils")
local Job = require("plenary/job")

local M = {}

function M.neuron(opts)
  Job:new {
    command = "neuron",
    args = opts.args,
    cwd = opts.neuron_dir,
    on_stderr = utils.on_stderr_factory(opts.name or "neuron"),
    on_stdout = vim.schedule_wrap(M.json_stdout_wrap(opts.callback))
  }:start()
end

function M.query(arg_opts, neuron_dir, json_fn)
  M.neuron {
    args = M.query_arg_maker(arg_opts),
    cwd = neuron_dir,
    name = "neuron query",
    callback = json_fn,
  }
end

--- 
function M.query_arg_maker(opts)
  local args = {"query"}

  if opts.up then
    table.insert(args, "--uplinks-of")
  else
    table.insert(args, "--backlinks-of")
  end

  if opts.cached == false then
    table.insert(args, "--cached")
  end

  return args
end

function M.query_id(id, neuron_dir, json_fn)
  M.neuron {
    args = {"query", "--cached", "--id", id},
    cwd = neuron_dir,
    name = "neuron query --id",
    callback = json_fn,
  }
end

--- json_fn takes a json table
function M.json_stdout_wrap(json_fn)
  return function(e, data)
    assert(not e, e)

    json_fn(vim.fn.json_decode(data))
  end
end

return M