## A C-compatible bitmask flags interface, with a subset of nim set functionality

import std/setutils
from typetraits import HoleyEnum

iterator holeyItems*[T: HoleyEnum](a: set[T]): T {.inline.} =
  ## Iterates over each element of `a`. `items` iterates only over the
  ## elements that are really in the set (and not over the ones the set is
  ## able to hold).
  ##
  ## uses a cast expression instead of a normal cast to allow handling enums with holes without `HoleyEnumConv` warnings
  ##
  ## cannot be called at compiletime because the VM doesn't support tyIntX to tyEnum casts
  var i = low(T).int
  while i <= high(T).int:
    if cast[T](i) in a: yield cast[T](i)
    inc(i)

type Flags*[T: SomeInteger, E: enum] = distinct T ## \
## A C-compatible bitmask-set interface
## 
## this exists because nim sets aren't compatible with C bitmasks
##
## `T: SomeInteger` is the backing type for the flags type and determines the base type and size
##
## `E: enum` is the enum type containing the range of values that the set is meant to represent,
## be careful not to accidentally overlap the bits in the values
##
## Overlapping enum values in bitfields is sometimes done on purpose, 
## but note that when stringized, only the basic values will be shown, not overlapping values

func makeFlags*[T, E](BackingType: typedesc[T], varflags: varargs[E]): Flags[T, E] =
    ## make a `Flags`_ type from variadic arguments\
    ## 
    ## `BackingType` is used to streamline generic type substitution
    ##
    ## can be called at comptime, use this or `toFlags*[T, E](arrflags: openArray[E], BackingType: typedesc[T])`_ if you need a flag compiletime constant
    var raw_flags: T

    for flag in varflags:
        raw_flags = raw_flags or T(flag) # set the corresponding bits
    
    return Flags[T, E](raw_flags)

func toFlags*[T, E](setflags: set[E], BackingType: typedesc[T]): Flags[T, E] =
    ## convert a nim set into a flags value
    ##
    ## BackingType is used to streamline generic type substitution
    ##
    ## cannot be called at compiletime due to `tyIntX to tyEnum cast`in the holeyItems iterator
    var raw_flags: T

    for flag in setflags.holeyItems():
        raw_flags = raw_flags or T(flag) # set the corresponding bits
    
    return Flags[T, E](raw_flags)

func toFlags*[T, E](setflags: set[E]): Flags[T, E] = toFlags[T, E](setflags, T)

func toFlags*[T, E](arrflags: openArray[E], BackingType: typedesc[T]): Flags[T, E] =
    ## convert a nim set into a flags value
    ##
    ## BackingType is used to streamline generic type substitution
    ##
    ## can be called at comptime, use this or `makeFlags`_ if you need a flag compiletime constant
    var raw_flags: T

    for flag in arrflags:
        raw_flags = raw_flags or T(flag) # set the corresponding bits
    
    return Flags[T, E](raw_flags)

func toFlags*[T, E](arrflags: openArray[E]): Flags[T, E] = toFlags[T, E](arrflags, T)

func set*[T, E](flags: var Flags[T, E], flag: E) =
    ## set a flag value in flags
    flags = Flags[T, E](cast[T](flags) or cast[T](flag))

func unset*[T, E](flags: var Flags[T, E], flag: E) =
    ## unset a flag value in flags
    flags = Flags[T, E](cast[T](flags) and (not cast[T](flag)))

iterator items*[T, E](flags: Flags[T, E]): E {.inline.} =
    ## iterator over flags contained in flags
    ##
    ## not callable at compiletime
    var flags = flags

    for flag in fullset(E).holeyItems():
        if flag in flags:
            flags.unset(flag) # flag erased to prevent duplicate matches in the case of overlapping E values
            yield flag

func toSet*[T, E](flags: Flags[T, E]): set[E] =
    var flags = flags

    for flag in fullset(E).holeyItems():
        if flag in flags:
            flags.unset(flag) # flag erased to prevent duplicate matches in the case of overlapping E values
            result.incl(flag)

proc `$`*[T, E](flags: Flags[T, E]): string {.noSideEffect.} = # must be a proc or is not called implicitly for some reason
    ## stringize a flags type in a format similar to a set    
    result = "{" & $T & " | "
    var flags = flags

    var firstElement = true
    for flag in fullset(E).holeyItems():
        if flag in flags:
            flags.unset(flag) # flag erased to prevent duplicate matches in the case of overlapping E values
            if not firstElement:
                result.add(", ")
            firstElement = false
            result.add($flag)
    result.add "}"

proc contains*[T, E](flags: Flags[T, E], flag: E): bool {.noSideEffect.} =
    ## check if flag is contained in flags
    (T(flags) and T(flag)) == T(flag)

proc contains*[T, E](flags: Flags[T, E], setflags: set[E]): bool {.noSideEffect.} =
    ## check if `setflags` is a subset or identity of `flags`
    ##
    ## cannot be called at compiletime
    let setflags = toFlags[T, E](setflags)

    return  (T(flags) and T(setflags)) == T(setflags)

proc contains*[T, E](flags: Flags[T, E], arrflags: openArray[E]): bool {.noSideEffect.} =
    ## check if `setflags` is a subset or identity of `flags`
    ##
    ## can be called at compiletime
    let arrflags = toFlags[T, E](arrflags)

    return  (T(flags) and T(arrflags)) == T(arrflags)

proc contains*[T, E](flags, subflags: Flags[T, E]): bool {.noSideEffect.} =
    ## check if `subflags` is a subset or identity of `flags`
    ##
    ## can be called at compiletime
    return (T(flags) and T(subflags)) == T(subflags)

func subsetOf*[T, E](flags, superflags: Flags[T, E]): bool =
    ## check if `flags` is a subset of `superflags` (but not an identity of)
    return flags in superflags and flags != superflags

func supersetOf*[T, E](flags, subflags: Flags[T, E]): bool =
    ## check if `flags` is a superset of `subflags` (but not an identity of)
    return subflags in flags and subflags != flags

proc `==`*[T, E](flags: Flags[T, E], setflags: set[E]): bool {.noSideEffect.} =
    ## check if `setflags` is an identity of `flags`
    ##
    ## cannot be called at compiletime
    return T(flags) == T(toFlags[T, E](setflags))

proc `==`*[T, E](flags: Flags[T, E], arrflags: openArray[E]): bool {.noSideEffect.} =
    ## check if `setflags` is an identity of `flags`
    ##
    ## can be called at compiletime
    return T(flags) == T(toFlags[T, E](arrflags))

proc `==`*[T, E](flags1, flags2: Flags[T, E]): bool {.noSideEffect.} =
    ## check if `setflags` is an identity of `flags`
    ##
    ## can be called at compiletime
    return T(flags1) == T(flags2)

proc `+`*[T, E](flags1, flags2: Flags[T, E]): Flags[T, E] {.noSideEffect.} =
    ## union of `flags1` and `flags2`
    ##
    ## can be called at compiletime
    return Flags[T, E](T(flags1) or T(flags2))

proc `*`*[T, E](flags1, flags2: Flags[T, E]): Flags[T, E] {.noSideEffect.} =
    ## intersect of `flags1` and `flags2`
    ##
    ## can be called at compiletime
    return Flags[T, E](T(flags1) and T(flags2))

proc `-`*[T, E](flags1, flags2: Flags[T, E]): Flags[T, E] {.noSideEffect.} =
    ## difference of `flags1` and `flags2`
    ##
    ## can be called at compiletime
    return Flags[T, E](T(flags1) and (not T(flags2)))

func card*[T, E](flags: Flags[T, E]): int =
    ## returns number of set flags in `flags`
    ##
    ## cannot be called at compiletime
    var flags = flags

    for flag in fullset(E).holeyItems():
        if flag in flags:
            flags.unset(flag) # flag erased to prevent duplicate matches in the case of overlapping E values
            result += 1
