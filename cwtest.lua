require "pl.strict" -- enforced, on purpose ;)
local tablex = require "pl.tablex"
local pretty = require "pl.pretty"

local printf = function(p,...)
  io.stdout:write(string.format(p,...)); io.stdout:flush()
end

local pass_assertion = function(self)
  printf(".")
  local info = debug.getinfo(3)
  self.successes[#self.successes+1] = string.format(
    "\n[OK] %s line %d (assertion)\n",
    info.short_src,
    info.currentline
  )
  return true
end

local fail_assertion = function(self)
  printf("x")
  local info = debug.getinfo(3)
  self.failures[#self.failures+1] = string.format(
    "\n[KO] %s line %d (assertion)\n",
    info.short_src,
    info.currentline
  )
  return false
end

local pass_eq = function(self,x,y)
  printf(".")
  local info = debug.getinfo(3)
  self.successes[#self.successes+1] = string.format(
    "\n[OK] %s line %d\n  expected: %s\n       got: %s\n",
    info.short_src,
    info.currentline,
    pretty.write(y,""),
    pretty.write(x,"")
  )
  return true
end

local fail_eq = function(self,x,y)
  printf("x")
  local info = debug.getinfo(3)
  self.failures[#self.failures+1] = string.format(
    "\n[KO] %s line %d\n  expected: %s\n       got: %s\n",
    info.short_src,
    info.currentline,
    pretty.write(y,""),
    pretty.write(x,"")
  )
  return false
end

local start = function(self,s)
  assert((not (self.failures or self.successes)),"test already started")
  self.failures,self.successes = {},{}
  printf("%s ",s)
end

local done = function(self)
  local f,s = self.failures,self.successes
  assert((f and s),"call start before done")
  if #f > 0 then
    print(" FAILED")
    for i=1,#f do io.stderr:write(f[i]) end
    print()
  else print(" OK") end
  if self.verbose and (#s > 0) then
    for i=1,#s do io.stderr:write(s[i]) end
    print()
  end
  self.failures,self.successes = nil,nil
end

local eq = function(self,x,y)
  local ok = (x == y) or tablex.deepcompare(x,y)
  return (ok and pass_eq or fail_eq)(self,x,y)
end

local seq = function(self,x,y) -- list-sets
  local ok = tablex.compare_no_order(x,y)
  return (ok and pass_eq or fail_eq)(self,x,y)
end

local is_true = function(self,x)
  return (x and pass_assertion or fail_assertion)(self)
end

local is_false = function(self,x)
  return (x and fail_assertion or pass_assertion)(self)
end

local methods = {
  fail_eq = fail_eq,
  start = start,
  done = done,
  eq = eq,
  seq = seq,
  yes = is_true,
  no = is_false,
}

local new = function(verbose)
  return setmetatable({verbose = verbose or false},{__index = methods})
end

return {
  new = new
}
