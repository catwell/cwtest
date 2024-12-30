local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local debug = _tl_compat and _tl_compat.debug or debug; local io = _tl_compat and _tl_compat.io or io; local math = _tl_compat and _tl_compat.math or math; local os = _tl_compat and _tl_compat.os or os; local pairs = _tl_compat and _tl_compat.pairs or pairs; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local VERSION = "3.0"



local deepcompare

local function deepcompare_tables(t1, t2)

   local mt = getmetatable(t1)
   if mt and mt.__eq then return t1 == t2 end
   for k1 in pairs(t1) do
      if t2[k1] == nil then return false end
   end
   for k2 in pairs(t2) do
      if t1[k2] == nil then return false end
   end
   for k1, v1 in pairs(t1) do
      local v2 = t2[k1]
      if not deepcompare(v1, v2) then return false end
   end
   return true
end

deepcompare = function(t1, t2)
   local ty1 = type(t1)
   local ty2 = type(t2)
   if ty1 ~= ty2 then return false end

   if ty1 ~= "table" then return t1 == t2 end
   return deepcompare_tables(t1, t2)
end

local function compare_no_order_tables(
   t1, t2, cmp)

   if #t1 ~= #t2 then return false end
   local visited = {}
   for i = 1, #t1 do
      local val = t1[i]
      local gotcha = 0
      for j = 1, #t2 do
         if not visited[j] then
            if cmp(val, t2[j]) then
               gotcha = j
               break
            end
         end
      end
      if not gotcha then return false end
      visited[gotcha] = true
   end
   return true
end

local function compare_no_order(
   t1, t2, cmp)

   cmp = cmp or deepcompare

   if (type(t1) ~= "table") or (type(t2) ~= "table") then return false end
   return compare_no_order_tables(t1, t2, cmp)
end



local function pretty_write(t)
   local function quote(s)
      if type(s) == "string" then
         return string.format("%q", tostring(s))
      else
         return tostring(s)
      end
   end
   if type(t) == "table" then
      local r = { "{" }
      for k, v in pairs(t) do
         r[#r + 1] = "["
         r[#r + 1] = quote(k)
         r[#r + 1] = "]="
         r[#r + 1] = pretty_write(v)
         r[#r + 1] = ","
      end
      r[#r + 1] = "}"
      return table.concat(r)
   else
      return quote(t)
   end
end

local function printf(p, ...)
   io.stdout:write(string.format(p, ...)); io.stdout:flush()
end

local function eprintf(p, ...)
   io.stderr:write(string.format(p, ...))
end












































local function running(self)
   return not not self._suite
end

local function m_successes(self)
   assert(self:running(), "tester must be running")
   assert(self._successes)
   return self._successes
end

local function m_failures(self)
   assert(self:running(), "tester must be running")
   assert(self._failures)
   return self._failures
end

local function m_suite(self)
   assert(self:running(), "tester must be running")
   assert(self._suite)
   return self._suite
end

local function elapsed(self)
   return #self:successes() + #self:failures()
end

local function log_success(self, tpl, ...)
   assert(type(tpl) == "string")
   local s = (select('#', ...) == 0) and tpl or string.format(tpl, ...)
   local successes = self:successes()
   successes[#successes + 1] = s
   if self.tap then
      self.printf(
      "    ok %d - %s %d\n",
      self:elapsed(), self:suite().name, self:elapsed())

   elseif self.verbosity == 2 then
      self.printf("\n%s\n", s)
   else
      self.printf(".")
   end
end

local function log_failure(self, tpl, ...)
   assert(type(tpl) == "string")
   local s = (select('#', ...) == 0) and tpl or string.format(tpl, ...)
   local failures = self:failures()
   failures[#failures + 1] = s
   if self.tap then
      self.printf(
      "    not ok %d - %s %d\n",
      self:elapsed(), self:suite().name, self:elapsed())

   elseif self.verbosity > 0 then
      self.eprintf("\n%s\n", s)
   else
      self.printf("x")
   end
end

local function pass_tpl(self, tpl, ...)
   assert(type(tpl) == "string")
   local info = debug.getinfo(3)
   self:log_success(
   "[OK] %s line %d%s",
   info.short_src,
   info.currentline,
   (select('#', ...) == 0) and tpl or string.format(tpl, ...))

   return true
end

local function fail_tpl(self, tpl, ...)
   assert(type(tpl) == "string")
   local info = debug.getinfo(3)
   self:log_failure(
   "[KO] %s line %d%s",
   info.short_src,
   info.currentline,
   (select('#', ...) == 0) and tpl or string.format(tpl, ...))

   return false
end

local function pass_assertion(self)
   local info = debug.getinfo(3)
   self:log_success(
   "[OK] %s line %d (assertion)",
   info.short_src,
   info.currentline)

   return true
end

local function fail_assertion(self)
   local info = debug.getinfo(3)
   self:log_failure(
   "[KO] %s line %d (assertion)",
   info.short_src,
   info.currentline)

   return false
end

local function pass_eq(self, x, y)
   local info = debug.getinfo(3)
   self:log_success(
   "[OK] %s line %d\n  expected: %s\n       got: %s",
   info.short_src,
   info.currentline,
   pretty_write(y),
   pretty_write(x))

   return true
end

local function fail_eq(self, x, y)
   local info = debug.getinfo(3)
   self:log_failure(
   "[KO] %s line %d\n  expected: %s\n       got: %s",
   info.short_src,
   info.currentline,
   pretty_write(y),
   pretty_write(x))

   return false
end

local function start(self, s, n)
   assert((not (self._failures or self._successes)), "test already started")
   assert(s, "no name given to test suite")
   local suite = { name = s }
   if type(n) == "number" then suite.plan = n end
   self._suite, self._failures, self._successes = suite, {}, {}
   if self.tap then
      local tap = self.tap
      if not tap.started then
         tap.started = 0
         if tap.plan then
            self.printf("1..%d\n", tap.plan)
         end
      end
      tap.started = tap.started + 1
      if suite.plan then
         self.printf("    1..%d\n", suite.plan)
      end
   elseif self.verbosity > 0 then
      self.printf("\n=== %s ===\n", s)
   else
      self.printf("%s ", s)
   end
end

local function done(self)
   local f, s = self:failures(), self:successes()
   assert((f and s), "call start before done")
   local suite = self:suite()
   local bad_plan = suite.plan and (suite.plan ~= self:elapsed())
   local failed = #f > 0 or bad_plan
   local plan = string.format("%d OK, %d KO", #s, #f)
   if suite.plan then
      plan = string.format("%s, %d total", plan, suite.plan)
   end
   if self.tap then
      local started = (self.tap).started
      if not suite.plan then
         self.printf("    1..%d\n", #f + #s)
      end
      if failed then
         self.printf("not ok %d - %s (%s)\n", started, suite.name, plan)
      else
         self.printf("ok %d - %s (%s)\n", started, suite.name, plan)
      end
   elseif failed then
      if self.verbosity > 0 then
         self.printf("\n=== FAILED (%s) ===\n", plan)
      else
         self.printf(" FAILED (%s)\n", plan)
         for i = 1, #f do self.eprintf("\n%s\n", f[i]) end
         self.printf("\n")
      end
   else
      if self.verbosity > 0 then
         self.printf("\n=== OK (%s) ===\n", plan)
      else
         self.printf(" OK (%s)\n", plan)
      end
   end
   self._failures, self._successes, self._suite = nil, nil, nil
   if failed then self.tainted = true end
   return (not failed)
end

local function eq(self, x, y)
   local ok = (x == y) or deepcompare(x, y)
   local r = (ok and pass_eq or fail_eq)(self, x, y)
   return r
end

local function neq(self, x, y)
   local sx, sy = pretty_write(x), pretty_write(y)
   local r
   if deepcompare(x, y) then
      r = fail_tpl(self, " (%s == %s)", sx, sy)
   else
      r = pass_tpl(self, " (%s != %s)", sx, sy)
   end
   return r
end

local function seq(self, x, y)
   local ok = compare_no_order(x, y)
   local r = (ok and pass_eq or fail_eq)(self, x, y)
   return r
end

local function _assert_fun(x, ...)
   if (select('#', ...) == 0) then
      return (x and pass_assertion or fail_assertion)
   else
      return (x and pass_tpl or fail_tpl)
   end
end

local function is_true(self, x, ...)
   local r = _assert_fun(x, ...)(self, ...)
   return r
end

local function is_false(self, x, ...)
   local r = _assert_fun((not x), ...)(self, ...)
   return r
end





local function err(self, f, e)
   local r = { pcall(f) }




   local res = false

   if e == nil then
      if r[1] then
         table.remove(r, 1)
         res = fail_tpl(
         self,
         ": expected error, got %s",
         pretty_write(r))

      else
         res = pass_tpl(self, ": error caught")
      end
   elseif type(e) == "string" then
      if r[1] then
         table.remove(r, 1)
         res = fail_tpl(
         self,
         "\n  expected error: %s\n             got: %s",
         e, pretty_write(r))

      elseif r[2] ~= e then
         res = fail_tpl(
         self,
         "\n  expected error: %s\n       got error: %s",
         e, r[2])

      else
         res = pass_tpl(self, ": error [[%s]] caught", e)
      end
   else
      assert(type(e) == "table")
      local pattern = (e).matching
      assert(type(pattern) == "string")
      if r[1] then
         table.remove(r, 1)
         res = fail_tpl(
         self,
         "\n  expected error, got: %s",
         e, pretty_write(r))

      else
         assert(type(r[2]) == "string")
         if not (r[2]):match(pattern) then
            res = fail_tpl(
            self,
            "\n  expected error matching: %q\n       got error: %s",
            pattern, r[2])

         else
            res = pass_tpl(self, ": error [[%s]] caught", e)
         end
      end
   end
   return res
end

local function exit(self)
   if self.tap then
      local tap = self.tap
      if tap.started and not tap.plan then
         self.printf("1..%d\n", tap.started)
      end
   end
   os.exit(self.tainted and 1 or 0)
end

local methods = {
   running = running,
   successes = m_successes,
   failures = m_failures,
   suite = m_suite,
   start = start,
   done = done,
   eq = eq,
   neq = neq,
   seq = seq,
   yes = is_true,
   no = is_false,
   err = err,
   exit = exit,

   elapsed = elapsed,
   log_success = log_success,
   log_failure = log_failure,
   pass_eq = pass_eq,
   fail_eq = fail_eq,
   pass_assertion = pass_assertion,
   fail_assertion = fail_assertion,
   pass_tpl = pass_tpl,
   fail_tpl = fail_tpl,
}







local function new(args)


   if not args then args = {} end


   args = { verbosity = args.verbosity, tap = args.tap, env = args.env }


   if args.env ~= false then
      local _p = type(args.env) == "string" and (args.env) or "CWTEST_"
      local v = math.tointeger(os.getenv(_p .. "VERBOSITY"))
      if v then args.verbosity = v end
      local v2 = os.getenv(_p .. "TAP")
      if v2 == "" then
         args.tap = nil
      elseif v2 then
         args.tap = math.tointeger(v2) or {}
      end
   end

   if not (args.verbosity) then args.verbosity = 0 end
   if type(args.verbosity) ~= "number" then args.verbosity = 1 end
   assert(
   (math.floor(args.verbosity) == args.verbosity) and
   (args.verbosity >= 0) and (args.verbosity < 3))


   if args.tap then
      if type(args.tap) == "number" then
         args.tap = { plan = args.tap }
      elseif type(args.tap) ~= "table" then
         args.tap = {}
      end
   end

   local r = {
      verbosity = args.verbosity,
      tap = args.tap,
      printf = printf,
      eprintf = eprintf,
      tainted = false,
   }

   return setmetatable(r, { __index = methods })
end

return {
   new = new,
   pretty_write = pretty_write,
   deepcompare = deepcompare,
   compare_no_order = compare_no_order,
   Tester = Tester,
   _VERSION = VERSION,
}
