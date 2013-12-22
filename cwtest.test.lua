local cwtest = require "cwtest"

local T = cwtest.new()

local C = cwtest.new() -- tested instance
C.printf = function(...) end
C.eprintf = function(...) end

local short_src = debug.getinfo(1).short_src
local exp_got_tpl = "\n  expected: %s\n       got: %s"
local pw = assert(cwtest.pretty_write)

local _line = function(status,before,tpl,...)
  assert(
    (type(status) == "string") and
    (type(before) == "number") and
    (type(tpl) == "string")
  )
  local s = (select('#',...) == 0) and tpl or string.format(tpl,...)
  return string.format(
    "[%s] %s line %s%s",status,short_src,
    (debug.getinfo(3).currentline - before),s
  )
end

T.last_success = function(self,tpl,...)
  local l = _line("OK",1,tpl,...)
  local s = C.successes[#C.successes]
  local r
  if s == l then
    r = self.pass_tpl(self,exp_got_tpl,l,s)
  else
    r = self.fail_tpl(self,exp_got_tpl,l,s)
  end
  return r
end

T.last_failure = function(self,tpl,...)
  local l = _line("KO",1,tpl,...)
  local s = C.failures[#C.failures]
  local r
  if s == l then
    r = self.pass_tpl(self,exp_got_tpl,l,s)
  else
    r = self.fail_tpl(self,exp_got_tpl,l,s)
  end
  return r
end

T:start("successes"); do
  C:start("successes")
  T:eq( C.successes, {} )
  T:eq( C.failures, {} )
  T:yes(C:yes( 0 ))
  T:last_success( " (assertion)" )
  T:yes(C:yes( true," foo" ))
  T:last_success( " foo" )
  T:yes(C:yes( true," %s","foo" ))
  T:last_success( " foo" )
  T:yes(C:no( nil ))
  T:last_success( " (assertion)" )
  T:yes(C:no( false," %s bar %d","foo",42 ))
  T:last_success( " foo bar 42" )
  T:yes(C:eq( 3*2, 6 ))
  T:last_success( exp_got_tpl,6,6 )
  local _i,_o = {1,2,a={b=42}},{[2]=2,a={b=42},[1]=1}
  T:yes(C:eq( _i, _o ))
  T:last_success( exp_got_tpl,pw(_o),pw(_i) )
  _i,_o = {2,{x=2.5},3},{3,2,{x=2.5}}
  T:yes(C:neq( _i, _o ))
  T:last_success( " (%s != %s)",pw(_i),pw(_o) )
  T:yes(C:seq( _i, _o ))
  T:last_success( exp_got_tpl,pw(_o),pw(_i) )
  T:yes(C:err( function() error("foo",0) end, "foo" ))
  T:last_success( ": error [[foo]] caught" )
  T:yes(C:err( function() error("foo",0) end ))
  T:last_success( ": error caught" )
  T:eq( C.failures, {} )
  C:done()
end; T:done()

T:start("failures"); do
  C:start("failures")
  T:eq( C.successes, {} )
  T:eq( C.failures, {} )
  T:no(C:yes( false ))
  T:last_failure( " (assertion)" )
  T:no(C:yes( nil," foo" ))
  T:last_failure( " foo" )
  T:no(C:yes( false," %s bar %d","foo",42 ))
  T:last_failure( " foo bar 42" )
  T:no(C:no( "" ))
  T:last_failure( " (assertion)" )
  T:no(C:no( {s="e"}," %d",6*7 ))
  T:last_failure( " 42" )
  local _i,_o = {2,{x=2.5},3},{3,2,{x=2.5}}
  T:no(C:eq( _i, _o ))
  T:last_failure( exp_got_tpl,pw(_o),pw(_i) )
  _i,_o = {1},{nil,1}
  T:no(C:eq( _i, _o ))
  T:last_failure( exp_got_tpl,pw(_o),pw(_i) )
  T:no(C:seq( _i, _o ))
  T:last_failure( exp_got_tpl,pw(_o),pw(_i) )
  T:no(C:neq( {nil,nil,nil}, {} ))
  T:last_failure( " ({} == {})" )
  T:no(C:err( function() error("foo",0) end, "bar" ))
  T:last_failure( "\n  expected error: bar\n       got error: foo" )
  T:no(C:err( function() return 42 end, "foo" ))
  T:last_failure( "\n  expected error: foo\n             got: %s",pw({42}) )
  T:no(C:err( function() return 42 end ))
  T:last_failure( ": expected error, got %s",pw({42}) )
  T:eq( C.successes, {} )
  C:done()
end; T:done()
