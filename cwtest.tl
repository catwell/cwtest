local VERSION = "3.0"

--- logic adapted from Penlight

local deepcompare: function(any, any): boolean

local function deepcompare_tables(t1: {any:any}, t2: {any:any}): boolean
    -- tables which have the metamethod __eq can be directly compared
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

deepcompare = function(t1: any, t2: any): boolean
    local ty1 = type(t1)
    local ty2 = type(t2)
    if ty1 ~= ty2 then return false end
    -- non-table types can be directly compared
    if ty1 ~= "table" then return t1 == t2 end
    return deepcompare_tables(t1 as {any:any}, t2 as {any:any})
end

local function compare_no_order_tables(
    t1: {any}, t2: {any}, cmp: function(any, any):(boolean)
): boolean
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
    t1: any, t2: any, cmp?: function(any, any):(boolean)
): boolean
    cmp = cmp or deepcompare
    -- non-table types are considered *never* equal here
    if (type(t1) ~= "table") or (type(t2) ~= "table") then return false end
    return compare_no_order_tables(t1 as {any}, t2 as {any}, cmp)
end

--- end of code from Penlight

local function pretty_write(t: any): string
    local function quote(s: any): string
        if type(s) == "string" then
            return string.format("%q", tostring(s))
        else
            return tostring(s)
        end
    end
    if type(t) == "table" then
        local r = {"{"}
        for k, v in pairs(t as {any: any}) do
            r[#r+1] = "["
            r[#r+1] = quote(k)
            r[#r+1] = "]="
            r[#r+1] = pretty_write(v)
            r[#r+1] = ","
        end
        r[#r+1] = "}"
        return table.concat(r)
    else
        return quote(t)
    end
end

local function printf(p: string, ...: any): nil
    io.stdout:write(string.format(p, ...)); io.stdout:flush()
end

local function eprintf(p: string, ...: any): nil
    io.stderr:write(string.format(p, ...))
end

local record Tap
    plan: integer | nil
    started: integer | nil
end

local record Suite
    name: string
    plan: integer | nil
end

local interface Tester
    _successes: {string} | nil
    _failures: {string} | nil
    _suite: Suite | nil
    tap: Tap | nil
    tainted: boolean
    verbosity: integer
    printf: function(string, any...):()
    eprintf: function(string, any...):()
    start: function(Tester, string, ? integer):()
    done: function(Tester):(boolean)
    running: function(Tester):(boolean)
    successes: function(Tester):({string})
    failures: function(Tester):({string})
    suite: function(Tester):(Suite)
    eq: function(Tester, any, any):(boolean)
    neq: function(Tester, any, any):(boolean)
    seq: function(Tester, any, any):(boolean)
    yes: function(Tester, any, any...):(boolean)
    no: function(Tester, any, any...):(boolean)
    err: function(Tester, function():(any...), ? (string | ErrMatch)): boolean
    exit: function(Tester):()
    elapsed: function(Tester):(integer)
    log_success: function(Tester, string, any...):()
    log_failure: function(Tester, string, any...):()
    pass_eq: function(Tester, any, any):(boolean)
    fail_eq: function(Tester, any, any):(boolean)
    pass_assertion: function(Tester):(boolean)
    fail_assertion: function(Tester):(boolean)
    pass_tpl: function(Tester, string, any...): boolean
    fail_tpl: function(Tester, string, any...): boolean
end

local function running(self: Tester): boolean
    return not not self._suite
end

local function m_successes(self: Tester): {string}
    assert(self:running(), "tester must be running")
    assert(self._successes)
    return self._successes
end

local function m_failures(self: Tester): {string}
    assert(self:running(), "tester must be running")
    assert(self._failures)
    return self._failures
end

local function m_suite(self: Tester): Suite
    assert(self:running(), "tester must be running")
    assert(self._suite)
    return self._suite
end

local function elapsed(self: Tester): integer
    return #self:successes() + #self:failures()
end

local function log_success(self: Tester, tpl: string, ...: any): nil
    assert(type(tpl) == "string")
    local s = (select('#', ...) == 0) and tpl or string.format(tpl, ...)
    local successes = self:successes()
    successes[#successes+1] = s
    if self.tap then
        self.printf(
            "    ok %d - %s %d\n",
            self:elapsed(), self:suite().name, self:elapsed()
        )
    elseif self.verbosity == 2 then
        self.printf("\n%s\n", s)
    else
        self.printf(".")
    end
end

local function log_failure(self: Tester, tpl: string, ...: any): nil
    assert(type(tpl) == "string")
    local s = (select('#', ...) == 0) and tpl or string.format(tpl, ...)
    local failures = self:failures()
    failures[#failures+1] = s
    if self.tap then
        self.printf(
            "    not ok %d - %s %d\n",
            self:elapsed(), self:suite().name, self:elapsed()
        )
    elseif self.verbosity > 0 then
        self.eprintf("\n%s\n", s)
    else
        self.printf("x")
    end
end

local function pass_tpl(self: Tester, tpl: string, ...: any): boolean
    assert(type(tpl) == "string")
    local info = debug.getinfo(3)
    self:log_success(
        "[OK] %s line %d%s",
        info.short_src,
        info.currentline,
        (select('#', ...) == 0) and tpl or string.format(tpl, ...)
    )
    return true
end

local function fail_tpl(self: Tester, tpl: string, ...: any): boolean
    assert(type(tpl) == "string")
    local info = debug.getinfo(3)
    self:log_failure(
        "[KO] %s line %d%s",
        info.short_src,
        info.currentline,
        (select('#', ...) == 0) and tpl or string.format(tpl, ...)
    )
    return false
end

local function pass_assertion(self: Tester): boolean
    local info = debug.getinfo(3)
    self:log_success(
        "[OK] %s line %d (assertion)",
        info.short_src,
        info.currentline
    )
    return true
end

local function fail_assertion(self: Tester): boolean
    local info = debug.getinfo(3)
    self:log_failure(
        "[KO] %s line %d (assertion)",
        info.short_src,
        info.currentline
    )
    return false
end

local function pass_eq(self: Tester, x: any, y: any): boolean
    local info = debug.getinfo(3)
    self:log_success(
        "[OK] %s line %d\n  expected: %s\n       got: %s",
        info.short_src,
        info.currentline,
        pretty_write(y),
        pretty_write(x)
    )
    return true
end

local function fail_eq(self: Tester, x: any, y: any): boolean
    local info = debug.getinfo(3)
    self:log_failure(
        "[KO] %s line %d\n  expected: %s\n       got: %s",
        info.short_src,
        info.currentline,
        pretty_write(y),
        pretty_write(x)
    )
    return false
end

local function start(self: Tester, s: string, n?: integer): nil
    assert((not (self._failures or self._successes)), "test already started")
    assert(s, "no name given to test suite")
    local suite: Suite = {name = s}
    if type(n) == "number" then suite.plan = n end
    self._suite, self._failures, self._successes = suite, {}, {}
    if self.tap then
        local tap = self.tap as Tap
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

local function done(self: Tester): boolean
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
        local started = (self.tap as Tap).started
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
            for i=1, #f do self.eprintf("\n%s\n", f[i]) end
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

local function eq(self: Tester, x: any, y: any): boolean
    local ok = (x == y) or deepcompare(x, y)
    local r = (ok and pass_eq or fail_eq)(self, x, y)
    return r
end

local function neq(self: Tester, x: any, y: any): boolean
    local sx, sy = pretty_write(x), pretty_write(y)
    local r: boolean
    if deepcompare(x, y) then
        r = fail_tpl(self, " (%s == %s)", sx, sy)
    else
        r = pass_tpl(self, " (%s != %s)", sx, sy)
    end
    return r
end

local function seq(self: Tester, x: any, y: any): boolean -- list-sets
    local ok = compare_no_order(x, y)
    local r = (ok and pass_eq or fail_eq)(self, x, y)
    return r
end

local function _assert_fun(x: any, ...: any): function(Tester, ...: any):(boolean)
    if (select('#', ...) == 0) then
        return (x and pass_assertion or fail_assertion)
    else
        return (x and pass_tpl or fail_tpl)
    end
end

local function is_true(self: Tester, x: any, ...: any): boolean
    local r = _assert_fun(x, ...)(self, ...)
    return r -- do not tail call (important)
end

local function is_false(self: Tester, x: any, ...: any): boolean
    local r = _assert_fun((not x), ...)(self, ...)
    return r -- do not tail call (important)
end

local record ErrMatch
    matching: string
end

local function err(self: Tester, f: function():(any...), e?: string | ErrMatch): boolean
    local r = { pcall(f) }

    -- This intermediate value is important! We must not e.g. return pass_tpl(...).
    -- The reason is if we tail call the source location will not be where fail_tpl
    -- expects it in the stack.
    local res = false

    if e == nil then
        if r[1] then
            table.remove(r, 1)
            res = fail_tpl(
                self,
                ": expected error, got %s",
                pretty_write(r)
            )
        else
            res = pass_tpl(self, ": error caught")
        end
    elseif type(e) == "string" then
        if r[1] then
            table.remove(r, 1)
            res = fail_tpl(
                self,
                "\n  expected error: %s\n             got: %s",
                e, pretty_write(r)
            )
        elseif r[2] ~= e then
            res = fail_tpl(
                self,
                "\n  expected error: %s\n       got error: %s",
                e, r[2]
            )
        else
            res = pass_tpl(self, ": error [[%s]] caught", e)
        end
    else
        assert(type(e) == "table")
        local pattern = (e as ErrMatch).matching
        assert(type(pattern) == "string")
        if r[1] then
            table.remove(r, 1)
            res = fail_tpl(
                self,
                "\n  expected error, got: %s",
                e, pretty_write(r)
            )
        else
            assert(type(r[2]) == "string")
            if not (r[2] as string):match(pattern) then
                res = fail_tpl(
                    self,
                    "\n  expected error matching: %q\n       got error: %s",
                    pattern, r[2]
                )
            else
                res = pass_tpl(self, ": error [[%s]] caught", e)
            end
        end
    end
    return res
end

local function exit(self: Tester): nil
    if self.tap then
        local tap = self.tap as Tap
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
    -- below: only to build custom tests
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

local record NewArgs
    tap: Tap | integer | nil
    verbosity: integer
    env: string | boolean | nil
end

local function new(args?: NewArgs): Tester

    -- backward compat
    if not args then args = {} end

    -- do not modify input
    args = {verbosity = args.verbosity, tap = args.tap, env = args.env}

    -- environment override
    if args.env ~= false then
        local _p: string = type(args.env) == "string" and (args.env as string) or "CWTEST_"
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
        (args.verbosity >= 0) and (args.verbosity < 3)
    )

    if args.tap then
        if type(args.tap) == "number" then
            args.tap = { plan = args.tap as integer }
        elseif type(args.tap) ~= "table" then
            args.tap = {}
        end
    end

    local r = {
        verbosity = args.verbosity,
        tap = args.tap as Tap | nil,
        printf = printf,
        eprintf = eprintf,
        tainted = false,
    }

    return setmetatable(r, {__index = methods})
end

return {
    new = new,
    pretty_write = pretty_write,
    deepcompare = deepcompare,
    compare_no_order = compare_no_order,
    Tester = Tester,
    _VERSION = VERSION,
}
