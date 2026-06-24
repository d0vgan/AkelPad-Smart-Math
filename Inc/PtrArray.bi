#ifndef __PTRARRAY_BI__
#define __PTRARRAY_BI__

const PTR_ARRAY_CHUNK as Integer = 16

type PtrDeleterType as sub(byval as Any Ptr)
type PtrMatcherType as function(byval as Any Ptr, byval as Any Ptr) as Boolean

type PtrArray
  declare constructor()
  declare constructor(byval customDeleter as PtrDeleterType, byval customMatcher as PtrMatcherType)
  declare constructor(byref rhs as PtrArray, byval customDeleter as PtrDeleterType, byval customMatcher as PtrMatcherType)
  declare destructor()
  declare operator let(byref rhs as PtrArray)
  declare operator [](byval index as Integer) as Any Ptr
  declare sub Clear()
  declare sub Append(byval p as Any Ptr)
  declare function Find(byval p as Any Ptr) as Integer
  declare sub RemoveAt(byval index as Integer)

  items(any) as Any Ptr
  count as Integer
  capacity as Integer
  deleter as PtrDeleterType
  matcher as PtrMatcherType
end type

constructor PtrArray()
  count = 0
  capacity = PTR_ARRAY_CHUNK
  deleter = 0
  matcher = 0
  redim items(0 to capacity - 1)
end constructor

constructor PtrArray(byval customDeleter as PtrDeleterType, byval customMatcher as PtrMatcherType)
  count = 0
  capacity = PTR_ARRAY_CHUNK
  deleter = customDeleter
  matcher = customMatcher
  redim items(0 to capacity - 1)
end constructor

constructor PtrArray(byref rhs as PtrArray, byval customDeleter as PtrDeleterType, byval customMatcher as PtrMatcherType)
  count = rhs.count
  capacity = rhs.capacity
  deleter = customDeleter
  matcher = customMatcher

  if capacity > 0 then
    redim items(0 to capacity - 1)

    for i as Integer = 0 to count - 1
      items(i) = rhs.items(i)
    next
  end if
end constructor

destructor PtrArray()
  Clear()
  erase items
  capacity = 0
end destructor

operator PtrArray.let(byref rhs as PtrArray)
  if @This = @rhs then exit operator

  Clear()
  erase items
  count = rhs.count
  capacity = rhs.capacity
  deleter = rhs.deleter
  matcher = rhs.matcher

  if capacity > 0 then
    redim items(0 to capacity - 1)

    for i as Integer = 0 to count - 1
      items(i) = rhs.items(i)
    next
  end if
end operator

operator PtrArray.[](byval index as Integer) as Any Ptr
  if index < 0 orelse index >= count then return 0
  return items(index)
end operator

sub PtrArray.Clear()
  if deleter <> 0 then
    for i as Integer = 0 to count - 1
      deleter(items(i))
      items(i) = 0
    next
  end if
  count = 0
end sub

sub PtrArray.Append(byval p as Any Ptr)
  if capacity = 0 then
    capacity = PTR_ARRAY_CHUNK
    redim items(0 to capacity - 1)
  elseif count >= capacity then
    capacity += PTR_ARRAY_CHUNK
    redim preserve items(0 to capacity - 1)
  end if

  items(count) = p
  count += 1
end sub

function PtrArray.Find(byval p as Any Ptr) as Integer
  for i as Integer = 0 to count - 1
    if matcher <> 0 then
      if matcher(items(i), p) then return i
    else
      if items(i) = p then return i
    end if
  next

  return -1 ' not found
end function

sub PtrArray.RemoveAt(byval index as Integer)
  if index < 0 orelse index >= count then exit sub

  dim pRemoved as Any Ptr = items(index)

  for i as Integer = index to count - 2
    items(i) = items(i + 1)
  next

  count -= 1
  items(count) = 0

  if deleter <> 0 then deleter(pRemoved)
end sub

#endif
