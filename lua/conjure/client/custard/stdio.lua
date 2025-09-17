local _2afile_2a = "fnl/conjure/client/custard/stdio.fnl"
local _local_1_ = require("conjure.nfnl.module")
local autoload = _local_1_["autoload"]
local define = _local_1_["define"]
local a = autoload("conjure.aniseed.core")
local client = autoload("conjure.client")
local config = autoload("conjure.config")
local log = autoload("conjure.log")
local mapping = autoload("conjure.mapping")
local nvim = autoload("conjure.aniseed.nvim")
local stdio = autoload("conjure.remote.stdio")
local str = autoload("conjure.nfnl.string")
local text = autoload("conjure.text")
local ts = autoload("conjure.tree-sitter")
local M = define("conjure.client.custard.stdio")
config.merge({client = {custard = {stdio = {mapping = {start = "cs", stop = "cS", interrupt = "ei"}, command = "npx custard repl", prompt_pattern = "\n?[-_%w.[]/()]+:%d+:[.>][.>][.>] "}}}})
if config["get-in"]({"mapping", "enable_defaults"}) then
  config.merge({client = {racket = {stdio = {mapping = {start = "cs", stop = "cS", interrupt = "ei"}}}}})
else
end
local cfg = config["get-in-fn"]({"client", "custard", "stdio"})
local state
local function _3_()
  return {repl = nil}
end
state = client["new-state"](_3_)
M["buf-suffix"] = ".cstd"
M["comment-prefix"] = ""
local function with_repl_or_warn(f, opts)
  local repl = state("repl")
  if repl then
    return f(repl)
  else
    return log.append({(M["comment-prefix"] .. "No REPL running")})
  end
end
local function format_message(msg)
  return str.split((msg.out or msg.err), "\n")
end
local function display_result(msg)
  local function _5_(_241)
    return not ("" == _241)
  end
  return log.append(a.filter(_5_, format_message(msg)))
end
M["eval-str"] = function(opts)
  local function _6_(repl)
    local function _7_(msgs)
      if ((1 == a.count(msgs)) and ("" == a["get-in"](msgs, {1, "out"}))) then
        a["assoc-in"](msgs, {1, "out"}, (M["comment-prefix"] .. "Empty result."))
      else
      end
      opts["on-result"](str.join("\n", a.mapcat(format_message, msgs)))
      return a["run!"](display_result, msgs)
    end
    return repl.send(opts.code, _7_, {["batch?"] = true})
  end
  return with_repl_or_warn(_6_)
end
M.interrupt = function()
  local function _9_(repl)
    log.append({(M["comment-prefix"] .. " Sending interrupt signal.")}, {["break?"] = true})
    return repl["send-signal"]("sigint")
  end
  return with_repl_or_warn(_9_)
end
M["doc-str"] = function(opts)
  local function _10_(_241)
    return (",doc " .. _241)
  end
  return M["eval-str"](a.update(opts, "code", _10_))
end
local function display_repl_status(status)
  local repl = state("repl")
  if repl then
    return log.append({(M["comment-prefix"] .. a["pr-str"](a["get-in"](repl, {"opts", "cmd"})) .. " (" .. status .. ")")}, {["break?"] = true})
  else
    return nil
  end
end
M.stop = function()
  local repl = state("repl")
  if repl then
    repl.destroy()
    display_repl_status("stopped")
    return a.assoc(state(), "repl", nil)
  else
    return nil
  end
end
M.enter = function()
  local repl = state("repl")
  local path = nvim.fn.expand("%:p")
  if (repl and not log["log-buf?"](path)) then
    local function _13_()
    end
    return repl.send((":load " .. path), _13_)
  else
    return nil
  end
end
M.start = function()
  if state("repl") then
    return log.append({"; Can't start, REPL is already running.", ("; Stop the REPL with " .. config["get-in"]({"mapping", "prefix"}) .. cfg({"mapping", "stop"}))}, {["break?"] = true})
  else
    local function _15_()
      display_repl_status("started")
      return enter()
    end
    local function _16_(err)
      return display_repl_status(err)
    end
    local function _17_(code, signal)
      if (("number" == type(code)) and (code > 0)) then
        log.append({(M["comment-prefix"] .. "process exited with code " .. code)})
      else
      end
      if (("number" == type(signal)) and (signal > 0)) then
        log.append({(M["comment-prefix"] .. "process exited with signal " .. signal)})
      else
      end
      return stop()
    end
    local function _20_(msg)
      return display_result(msg)
    end
    return a.assoc(state(), "repl", stdio.start({["prompt-pattern"] = cfg({"prompt_pattern"}), cmd = cfg({"command"}), ["on-success"] = _15_, ["on-error"] = _16_, ["on-exit"] = _17_, ["on-stray-output"] = _20_}))
  end
end
M["on-load"] = function()
  return start()
end
M["on-filetype"] = function()
  mapping.buf("CustardStart", cfg({"mapping", "start"}), M.start, {desc = "Start the REPL"})
  mapping.buf("CustardStop", cfg({"mapping", "stop"}), M.stop, {desc = "Stop the REPL"})
  return mapping.buf("CustardInterrupt", cfg({"mapping", "interrupt"}), M.interrupt, {desc = "Interrupt the current evaluation"})
end
M["on-exit"] = function()
  return stop()
end
return M