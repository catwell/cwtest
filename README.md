# cwtest

[![Build Status](https://travis-ci.org/catwell/cwtest.png?branch=master)](https://travis-ci.org/catwell/cwtest)

## Presentation

This is a small Lua test helper with no hard dependency (but that works better with
[Penlight](http://stevedonovan.github.com/Penlight/) installed).

## Alternatives

- [busted](http://olivinelabs.com/busted/)
- [lua-TestMore](http://fperrad.github.com/lua-TestMore/)
- [Unit Testing](http://lua-users.org/wiki/UnitTesting) page on the Lua Users' Wiki

## Basic usage

```lua
local cwtest = require "cwtest"

local T = cwtest.new() -- instantiate a test

T:start("Multiplication"); do -- start a test
  T:eq( 2*3, 6 ) -- test equality
  T:eq( 3*3*3, 27 )
  T:eq( 3*4, 13 ) -- uh?
  T:eq( 7*7, 49 )
end; T:done() -- end a test

T:start("Squares"); do -- you can re-use T once done
  for i=1,10 do
    local x = 0
    for j=1,i do x = x+i end
    T:eq( i*i, x )
  end
end; T:done()

T:exit()
```

Output:

```
Multiplication ...x. FAILED (3 OK, 1 KO)

[FAIL] my.test.lua line 8
  expected: 13
       got: 12

Squares .......... OK (10 OK, 0 KO)
```

## Details

### do/end block

Wrapping tests in a `do/end` block is not mandatory. You could simply write this:

```lua
T:start("stuff")
T:eq( 6*7, 42 )
T:done()
```

That being said, the `do/end` blocks with indentation help to separate your tests visually and keep your variables local, so this style is a good practice.

### Return value of done()

`done()` returns `true` if all tests have succeeded, `false` otherwise. Among other things this allows you to abort after a failed test suite:

```lua
T:start("stuff"); do
  T:eq(continue, true)
end
if not T:done() then T:exit() end
```

### exit()

`exit()` leaves the interpreter, returning an error code of 1 if any call to `done()`  has failed, 0 otherwise. You do not have to call `exit()`, but doing so makes cwtest work with CI software.

### Other tests

- `eq` called on tables uses deep comparison.
- `neq` is the opposite of `eq`.
- `yes` and `no` test boolean propositions.
- `seq` can be used to compare two lists without considering order.
- `err` tests that an error is raised by a function.

### Planning

If you pass a number as the second argument of `start()`, it will be taken as the number of tests in the test suite. If a different number of tests is run before `done()` is called, the test suite will fail.

### Arguments of new()

You can pass an arguments table to `new()`. It supports the following keys:

#### verbosity

If you set `verbosity`, it must be an integer between 0 and 2, the default is 0.

Verbosity level 1 will print errors inline as soon as they happen, which may be useful to debug an error that makes your tests crash later on.

Verbosity level 2 will print successes in full form as well as errors. You probably do not need this.

#### tap

You can set `tap` to `true` to switch the output format to [TAP](https://testanything.org). The format used is actually nested tap: test suites are top level tests, and individual assertions are nested one level. For instance, the example from [Basic usage](#basic-usage) would result in:

        ok 1 - Multiplication 1
        ok 2 - Multiplication 2
        not ok 3 - Multiplication 3
        ok 4 - Multiplication 4
        1..4
    not ok 1 - Multiplication (3 OK, 1 KO)
        ok 1 - Squares 1
        ok 2 - Squares 2
        ok 3 - Squares 3
        ok 4 - Squares 4
        ok 5 - Squares 5
        ok 6 - Squares 6
        ok 7 - Squares 7
        ok 8 - Squares 8
        ok 9 - Squares 9
        ok 10 - Squares 10
        1..10
    ok 2 - Squares (10 OK, 0 KO)
    1..2

You can also pass a number to plan how many test suites will be run. TAP will also leverage [planning](#planning). If you do both, planning 2 test suites with respectively 4 and 10 tests, the output will become:

    1..2
        1..4
        ok 1 - Multiplication 1
        ok 2 - Multiplication 2
        not ok 3 - Multiplication 3
        ok 4 - Multiplication 4
    not ok 1 - Multiplication (3 OK, 1 KO, 4 total)
        1..10
        ok 1 - Squares 1
        ok 2 - Squares 2
        ok 3 - Squares 3
        ok 4 - Squares 4
        ok 5 - Squares 5
        ok 6 - Squares 6
        ok 7 - Squares 7
        ok 8 - Squares 8
        ok 9 - Squares 9
        ok 10 - Squares 10
    ok 2 - Squares (10 OK, 0 KO, 10 total)

#### env

You can override the previous settings using environment variables `CWTEST_VERBOSITY` and `CWTEST_TAP`. If you want to disable this, set `env` to `false`. You can also set `env` to any string, which will then be used as the prefix instead of `CWTEST_`.

### Custom tests

You can define your own tests by adding methods to `T` and calling
`pass_` and `fail_` methods.
You can find an example of this
[in fakeredis](https://github.com/catwell/cw-lua/blob/0503a0cbda94ac006485eb16daf55ceb030408da/fakeredis/fakeredis.test.lua#L7) and another one [in cwtest's meta-tests](https://github.com/catwell/cwtest/blob/727e8b0bb0058916966e4b7f14c37dc7779eb0c9/cwtest.test.lua#L26).

## Copyright

- Copyright (c) 2012-2013 Moodstocks SAS
- Copyright (c) 2014-2016 Pierre Chapuis
