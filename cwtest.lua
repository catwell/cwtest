local has_strict = pcall(require,"pl.strict")
local has_pretty,pretty = pcall(require,"pl.pretty")
if not has_strict then
  print("WARNING: pl.strict not found, strictness not enforced.")
end
if not has_pretty then
  pretty = nil
  print("WARNING: pl.pretty not found, using alternate formatter.")
end

--- logic borrowed to Penlight

local deepcompare
deepcompare = function(t1,t2)
  local ty1 = type(t1)
  local ty2 = type(t2)
  if ty1 ~= ty2 then return false end
  -- non-table types can be directly compared
  if ty1 ~= "table" then return t1 == t2 end
  -- as well as tables which have the metamethod __eq
  local mt = getmetatable(t1)
  if mt and mt.__eq then return t1 == t2 end
  for k1 in pairs(t1) do
    if t2[k1]==nil then return false end
  end
  for k2 in pairs(t2) do
    if t1[k2]==nil then return false end
  end
  for k1,v1 in pairs(t1) do
    local v2 = t2[k1]
    if not deepcompare(v1,v2) then return false end
  end
  return true
end

local compare_no_order = function(t1,t2)
  -- non-table types are considered *never* equal here
  if (type(t1) ~= "table") or (type(t2) ~= "table") then return false end
  if #t1 ~= #t2 then return false end
  local visited = {}
  for i = 1,#t1 do
    local val = t1[i]
    local gotcha
    for j = 1,#t2 do if not visited[j] then
      if deepcompare(val,t2[j]) then
        gotcha = j
        break
      end
    end end
    if not gotcha then return false end
    visited[gotcha] = true
  end
  return true
end

--- basic pretty.write fallback

local less_pretty_write
less_pretty_write = function(t)
  local quote = function(s)
    if type(s) == "string" then
      return string.format("%q",tostring(s))
    else return tostring(s) end
  end
  if type(t) == "table" then
    local r = {"{"}
    for k,v in pairs(t) do
      if type(k) ~= "number" then k = quote(k) end
      r[#r+1] = "["
      r[#r+1] = k
      r[#r+1] = "]="
      r[#r+1] = less_pretty_write(v)
      r[#r+1] = ","
    end
    r[#r+1] = "}"
    return table.concat(r)
  else return quote(t) end
end

--- end of Penlight fallbacks

local pretty_write
if pretty then
  pretty_write = function(x) return pretty.write(x,"") end
else
  pretty_write = less_pretty_write
end

local printf = function(p,...)
  io.stdout:write(string.format(p,...)); io.stdout:flush()
end

local pass_tpl = function(self,tpl,...)
  assert(type(tpl) == "string")
  printf(".")
  local info = debug.getinfo(3)
  self.successes[#self.successes+1] = string.format(
    "\n[OK] %s line %d%s\n",
    info.short_src,
    info.currentline,
    (select('#',...) == 0) and tpl or string.format(tpl,...)
  )
  return true
end

local fail_tpl = function(self,tpl,...)
  assert(type(tpl) == "string")
  printf("x")
  local info = debug.getinfo(3)
  self.failures[#self.failures+1] = string.format(
    "\n[KO] %s line %d%s\n",
    info.short_src,
    info.currentline,
    (select('#',...) == 0) and tpl or string.format(tpl,...)
  )
  return false
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
    pretty_write(y),
    pretty_write(x)
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
    pretty_write(y),
    pretty_write(x)
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
  local failed = (#f > 0)
  if failed then
    print(" FAILED")
    for i=1,#f do io.stderr:write(f[i]) end
    print()
  else print(" OK") end
  if self.verbose and (#s > 0) then
    for i=1,#s do io.stderr:write(s[i]) end
    print()
  end
  self.failures,self.successes = nil,nil
  return (not failed)
end

local eq = function(self,x,y)
  local ok = (x == y) or deepcompare(x,y)
  local r = (ok and pass_eq or fail_eq)(self,x,y)
  return r
end

local neq = function(self,x,y)
  local sx,sy = pretty_write(x),pretty_write(y)
  local r
  if deepcompare(x,y) then
    r = fail_tpl(self," (%s == %s)",sx,sy)
  else
    r = pass_tpl(self," (%s != %s)",sx,sy)
  end
  return r
end

local seq = function(self,x,y) -- list-sets
  local ok = compare_no_order(x,y,deepcompare)
  local r = (ok and pass_eq or fail_eq)(self,x,y)
  return r
end

local is_true = function(self,x)
  local r = (x and pass_assertion or fail_assertion)(self)
  return r
end

local is_false = function(self,x)
  local r = (x and fail_assertion or pass_assertion)(self)
  return r
end

local methods = {
  start = start,
  done = done,
  eq = eq,
  neq = neq,
  seq = seq,
  yes = is_true,
  no = is_false,
  -- below: only to build custom tests
  pass_eq = pass_eq,
  fail_eq = fail_eq,
  pass_assertion = pass_assertion,
  fail_assertion = fail_assertion,
  pass_tpl = pass_tpl,
  fail_tpl = fail_tpl,
}

local new = function(verbose)
  return setmetatable({verbose = verbose or false},{__index = methods})
end

return {
  new = new
}
