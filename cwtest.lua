require "pl.strict" -- enforced, on purpose ;)
local tablex = require "pl.tablex"
local pretty = require "pl.pretty"

local printf = function(p,...)
  io.stdout:write(string.format(p,...)); io.stdout:flush()
end

local fail_eq = function(self,x,y)
  printf("x")
  local info = debug.getinfo(3)
  self.failures[#self.failures+1] = string.format(
    "\n[FAIL] %s line %d\n  expected: %s\n       got: %s\n",
    info.short_src,
    info.currentline,
    pretty.write(y,""),
    pretty.write(x,"")
  )
end

local start = function(self,s)
  assert((not self.failures),"test already started")
  self.failures = {}
  printf("%s ",s)
end

local done = function(self)
  local f = self.failures
  assert(f,"call start before done")
  if #f > 0 then
    print(" FAILED")
    for i=1,#f do io.stderr:write(f[i]) end
    print()
  else print(" OK") end
  self.failures = nil
end

local eq = function(self,x,y)
  printf(".")
  if not ((x == y) or tablex.deepcompare(x,y)) then
    fail_eq(self,x,y)
  end
end

local seq = function(self,x,y) -- list-sets
  printf(".")
  if not tablex.compare_no_order(x,y) then
    fail_eq(self,x,y)
  end
end

local methods = {
  fail_eq = fail_eq,
  start = start,
  done = done,
  eq = eq,
  seq = seq,
}

local new = function()
  return setmetatable({},{__index = methods})
end

return {
  new = new
}
