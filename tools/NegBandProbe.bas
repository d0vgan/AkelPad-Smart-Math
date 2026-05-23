#include once "..\Inc\MathParser.bi"

function main() as Integer
  dim expr as String = command(1)
  if len(expr) = 0 then return 1
  if lcase(command(0)) = "--complex" then
    Parser_SetSupportComplexNumbers(TRUE)
    if len(command(2)) > 0 then expr = command(2)
  end if
  dim r as Double
  dim rt as String
  dim ia as Boolean
  if Parser_TryEvaluateEx(expr, r, rt, ia) then
    print rt
    return 0
  end if
  print "ERROR:"; Parser_GetLastError()
  return 1
end function
