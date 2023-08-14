# cflags
An implementation of c bitmask flags for nim

```nim
import cflags # for Flags[T: SomeInteger, E: enum], toFlags, iterator holeyItems(set[E: HoleyEnum])

import sequtils # for toSeq

import sugar # for dump

import std/setutils # for fullSet

type Toppings = enum
    Cheese = 1,
    Pepperoni = 2,
    Onion = 4,
    Peppers = 8,

dump Toppings.fullSet().holeyItems().toSeq()

# a supreme pizza represented as a set[Toppings]
let supreme_set = {Cheese, Pepperoni, Onion, Peppers}

dump typeof(supreme_set)

dump sizeof(supreme_set)

dump cast[uint8](supreme_set)

# causes a bunch of HoleyEnumConv warnings that requires
# disabling the warning in every calling file to get rid of because of `iterator items(set[E])`
#echo supreme_set

# can use holeyItems with any set[E: HoleyEnum] and no warnings occur (just can't call at comptime)
dump supreme_set.holeyItems().toSeq()

echo()

# a supreme pizza represented as a Flags[uint32, Toppings]
let supreme = supreme_set.toFlags(uint32) # uint32 is the backing type for Flags

dump typeof(supreme)

dump sizeof(supreme)

dump supreme.uint32

dump supreme.toSeq()

dump supreme

echo()

const vegetarian = [Cheese, Onion, Peppers].toFlags(uint32) # toFlags(openArray[E]) can be called at comptime, toFlags(set[E]) can't
# can also be called as [Cheese, Onion, Peppers].toFlags[uint32, Toppings]()

dump vegetarian

const classic = makeFlags(uint32, Cheese, Pepperoni) # can also be called at comptime

dump classic

echo()

dump vegetarian in supreme

dump supreme in vegetarian

dump Cheese in vegetarian

dump classic == {Cheese, Pepperoni}

dump classic == [Cheese, Pepperoni]

echo()

dump supreme.subsetOf(supreme)

dump classic.subsetOf(supreme)

dump supreme.supersetOf(classic)

dump vegetarian + classic

dump supreme - classic

dump classic * vegetarian

dump vegetarian.card

dump supreme.card
```
