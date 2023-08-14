import unittest

import cflags

import sequtils # for toSeq

import std/setutils # for fullSet

type Toppings = enum
    Cheese = 1,
    Pepperoni = 2,
    Onion = 4,
    Peppers = 8,

test "holeyItems":
    doAssert Toppings.fullSet().holeyItems().toSeq() == @[Cheese, Pepperoni, Onion, Peppers]

# a supreme pizza represented as a set[Toppings]
let supreme_set = {Cheese, Pepperoni, Onion, Peppers}

# a supreme pizza represented as a Flags[uint32, Toppings]
let supreme = supreme_set.toFlags(uint32) # uint32 is the backing type for Flags

test "Flags basic properties":
    doAssert supreme is Flags[uint32, Toppings]

    doAssert sizeof(supreme) == sizeof(uint32)

    doAssert supreme.uint32 == 15

    doAssert supreme.toSeq() == @[Cheese, Pepperoni, Onion, Peppers]

const vegetarian = [Cheese, Onion, Peppers].toFlags(uint32) # toFlags(openArray[E]) can be called at comptime, toFlags(set[E]) can't
    # can also be called as [Cheese, Onion, Peppers].toFlags[uint32, Toppings]()

const classic = makeFlags(uint32, Cheese, Pepperoni) # can also be called at comptime

test "Flags.contains":
    doAssert vegetarian in supreme

    doAssert supreme notin vegetarian

    doAssert Cheese in vegetarian

test "Flags.`==`":
    doAssert classic == {Cheese, Pepperoni}

    doAssert classic == [Cheese, Pepperoni]

    doAssert supreme != classic

test "Flags.subsetOf/supersetOf":
    doAssert not supreme.subsetOf(supreme)

    doAssert classic.subsetOf(supreme)

    doAssert supreme.supersetOf(classic)

test "Flags set theory operators":
    doAssert vegetarian + classic == makeFlags(uint32, Cheese, Pepperoni, Onion, Peppers)

    doAssert supreme - classic == makeFlags(uint32, Onion, Peppers)

    doAssert classic * vegetarian == makeFlags(uint32, Cheese)

test "Flags.card":
    doAssert vegetarian.card == 3

    doAssert supreme.card == 4
