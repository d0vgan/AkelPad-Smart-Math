#ifndef __MATHPARSER_RAWRESULT_BI__
#define __MATHPARSER_RAWRESULT_BI__

enum RawResultKind
  RRK_NONE = 0
  RRK_SCALAR = 1
  RRK_ARRAY = 2
end enum

enum RawScalarKind
  RSK_FLOATING = 0
  RSK_INT64 = 1
  RSK_UINT64 = 2
  RSK_RATIONAL = 3
  RSK_COMPLEX = 4
  RSK_TIME = 5
end enum

type RawCartesianScalar
  kind as RawScalarKind
  floatValue as Double
  intValue as LongInt
  uintValue as ULongInt
  ratNum as LongInt
  ratDen as ULongInt
end type

'' Non-complex payload lives in real; imag is zero for pure real. kind = RSK_COMPLEX when imag is active.
type RawScalar
  kind as RawScalarKind
  real as RawCartesianScalar
  imag as RawCartesianScalar
  '' Non-decimal display from parser (hex/oct/bin); 0 = decimal.
  renderBase as UInteger
  renderUnsigned as Boolean
end type

type RawResult
  kind as RawResultKind
  scalar as RawScalar
  arr(any) as RawScalar
end type

declare sub RawCartesianScalarClear(byref c as RawCartesianScalar)
declare sub RawResultClear(byref r as RawResult)
declare function RawResultHasValue(byref r as RawResult) as Boolean
declare function RawScalarIsComplex(byref s as RawScalar) as Boolean
declare function RawScalarIsRational(byref s as RawScalar) as Boolean
declare function RawCartesianIsRational(byref c as RawCartesianScalar) as Boolean
declare function RawCartesianIsZero(byref c as RawCartesianScalar) as Boolean

#endif
