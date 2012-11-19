# cwtest

## Presentation

This is a very small Lua test helper that fits my needs and probably not yours.
It depends on [Penlight](http://stevedonovan.github.com/Penlight/).

If you need something more powerful, see
[busted](http://olivinelabs.com/busted/) or
[lua-TestMore](http://fperrad.github.com/lua-TestMore/).

## Usage

### Basic

```lua
local cwtest = require "cwtest"

local T = cwtest.new() -- instantiate a test

T:start("Multiplication") -- start a test
T:eq( 2*3, 6 ) -- test equality
T:eq( 3*3*3, 27 )
T:eq( 3*4, 13 ) -- uh?
T:eq( 7*7, 49 )
T:done() -- end a test

T:start("Squares") -- you can re-use T once done
for i=1,10 do
  local x = 0
  for j=1,i do x = x+i end
  T:eq( i*i, x )
end
T:done()
```

Output:

```
Multiplication ...x.FAILED

[FAIL] my.test.lua line 8
  expected: 13
       got: 12

Squares .......... OK
```

### Advanced

- `eq` called on tables uses deep comparison.
- `seq` can be used to compare two lists without considering order.
- You can easily define your own comparisons by adding methods to `T`
and calling `fail_eq` to report errors.

## Copyright

Copyright (c) 2012 Moodstocks SAS
