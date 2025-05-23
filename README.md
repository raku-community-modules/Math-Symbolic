[![Actions Status](https://github.com/raku-community-modules/Math-Symbolic/actions/workflows/linux.yml/badge.svg)](https://github.com/raku-community-modules/Math-Symbolic/actions) [![Actions Status](https://github.com/raku-community-modules/Math-Symbolic/actions/workflows/macos.yml/badge.svg)](https://github.com/raku-community-modules/Math-Symbolic/actions) [![Actions Status](https://github.com/raku-community-modules/Math-Symbolic/actions/workflows/windows.yml/badge.svg)](https://github.com/raku-community-modules/Math-Symbolic/actions)

NAME
====

Math::Symbolic - Symbolic math for Raku

SYNOPSIS
========

Either of

    symbolic --m=1 --b=0 'y=m*x+b' x

on the command line, or

```raku
say Math::Symbolic.new("y=m*x+b").isolate("x").evaluate(:m(1), :b(0));
```

in Raku code, will print

    x=y

DESCRIPTION
===========

This is a Raku symbolic math module. It parses, manipulates, evaluates, and outputs mathematical expressions and relations. This module is PRE-ALPHA quality.

USAGE
=====

Command line
------------

A basic command line program named 'symbolic' is provided.

It takes at least one positional argument: the relation or expression to work with. If a second positional is passed, it is the name of the variable to isolate in the given relation (non-relation expressions are unsupported for isolation). If "0" is passed instead of a variable name, the relation is arranged with 0 on the right side and terms grouped by variable (when possible) on the left side.

If any named args are passed, they are substituted into the expression for the variables they name. Each named argument's value is parsed as an expression itself, so it doesn't just have to be a numeric value to give the variable.

The resulting expression will be printed after applying all requested transformations, and attempting to simplify.

API
---

At the time of this writing, most of the API is too unstable to document yet. To minimize exposure to the internal chaos and to provide a starting point for thinking about what functionality needs to exist in a more formal future API, a minimal temporary public interface is implemented as a small collection of simple methods in the main `Math::Symbolic` class. Note that where the actual signatures differ from what is documented here, the undocumented differences are considered "private", and may not do what is expected.

METHODS
=======

.new(Str:D $expression)
-----------------------

Creates a new `Math::Symbolic` object, initialized with the tree resulting from a parse of $expression (which may also be a relation; currently only "=" equality is supported for relations).

.clone()
--------

Returns a clone of the object with an independent copy of the tree structure. This is important because all manipulations (below) are done in place, and cloning avoids the parsing overhead of .new().

.isolate(Str:D $var)
--------------------

Arranges a relation with $var on the left and everything else on the right. Or attempts to. It supports simple operation inversion when only one instance of a variable exists, as well as attempting to combine instances via distributive property and/or factoring of polynomial expressions, if necessary. Calling `.isolate` on a non-relation expression is not supported.

.evaluate(\*%values)
--------------------

Replaces all instances of variables named by the keys of the hash, with the expressions in the values of the hash, and simplifies the result as much as possible (see `.simplify`). If the resulting expression has no variables, this means it can be fully evaluated down to a single value.

Note that fully evaluating an equation with valid values would result in something mostly unhelpful like "0=0" if the simplifier is smart enough. Though in the future, when such a relation can be evaluated for truth, that will become useful.

.simplify()
-----------

Makes a childish attempt to reduce the complexity of the expression by evaluating operations on constants, removing operations on identity values (and eventually other special cases like 0, inverse identity, etc). Also already does a very small number of rearrangements of combinations of operations, like transforming a+-b into a-b.

`.simplify` is sometimes called after certain manipulations like `.isolate` and `.poly` which might otherwise leave messy expressions e.g. operations with identity values and awkward forms of negation and inversion. It is also called at the end of the command line tool for output of the final result.

.poly(Str $var?)
----------------

Attempts to arrange the equation/expression in polynomial form. If $var is given, terms are grouped for that specific variable. Otherwise terms are grouped separately according to the set of all variables in a term. For example "x²+x²\*y" will be unchanged by `.poly()`, but `.poly('x')` will rearrange it to something like "x²\*(1+y)". Unlike the formal definition of a polynomial, this function may accept and return any expression for coefficients, and allows for exponents of any constant value.

If `.poly` is called on a relation, it is first arranged so that the right side is equal to zero, before grouping terms on the left. An attempt is made to guess which side should be subtracted from the other to avoid ending up with an excessive amount of negation.

.expression(Str:D $var)
-----------------------

Creates a new `Math::Symbolic` object from the expression on the right-hand side of a relation after isolating $var on the left. Note that unlike the above transformations, no changes are made to the original object.

.compile($positional = False, $defaults?)
-----------------------------------------

Returns a Raku subroutine which is mathematically equivalent to the `Math::Symbolic` expression. Not all operations are currently supported. Compiling relations is also undefined behavior at this time.

All arguments are named by default. If $positional is True, all arguments are positional instead, sorted in default Raku sort order. If $positional is itself a Positional class then only the listed variables will be taken positionally, in the specified order.

All arguments are also required by default. If $defaults is an Associative object, it is taken as a map of variable names to default values, and the listed variables will be optional. If $defaults is any other defined value, that value is taken as the default for all arguments.

.routine($positional = False, $defaults?)
-----------------------------------------

Identical to `.compile (above)`, but returns the code as a string without compiling via `EVAL`, for instance to embed the code into another module or script.

.count()
--------

Returns the number of nodes in the expression's tree. This could be useful to determine if an expression has been fully evaluated, or used as a crude complexity metric.

.dump_tree()
------------

Prints out the tree structure of the expression. This really should return the string instead, and perhaps be renamed.

.Str()
------

Returns the expression re-assembled into a string by the same syntactic constructs which govern parsing. As with all Raku objects, this is also the method which gets called when the object is coerced to a string by other means, e.g. interpolation, context, or the ~ prefix. The `.gist` method is also handled by this routine, for easy printing of a readable result.

Passing the result of `.Str` back in to `.new` should always yield a mathematically equivalent structure (exact representation may vary by some auto-simplification), giving the same type of round-trip characteristics to expressions that `.raku` and `EVAL()` provide for Raku objects. This allows a user to, for instance, isolate a variable in an equation, then plug the result in to `.evaluate` for that variable in a different equation, all with the simplicity of strings; no additional classes or APIs for the user to worry about (albeit at a steep performance penalty).

.Numeric()
----------

Returns the expression coerced first to a string (see above), then to a number. This will fail if the expression hasn't already been evaluated or simplified (see further above) to a single constant value. As with all Raku objects, this is also the method which gets called when the object is coerced to a number by other means, e.g. context or the + prefix.

SYNTAX AND OPERATIONS
=====================

All whitespace is optional. Implicit operations, e.g. multiplication by putting two variables in a row with no infix operator, are not supported, and likely never will be. It leads to far too many consequences, compromises, complexities and non-determinisms.

The available operations and syntax in order of precedence are currently:

    * Terms
        * Variables
            * valid characters for variable names are alphanumerics and underscore
            * first character must not be a number, mainly to avoid collisions with
            E notation (see below)
        * Values
            * optional sign (only "-" for now)
            * E notation supported
                * case insensitive
                * no restriction on value of exponent, with sign and decimal
                * subexpressions not supported (e is numeric syntax, not an op)
            * leading zeros before decimals not required
            * imaginary, complex, quaternion, etc NYI
            * vector, matrix, set, etc NYI
    * Circumfix
        * () Grouping Parens
        * || Absolute Value
            * cannot invert this op for solving/manipulating, ± NYI
    * Postfix
        * ! Factorial
            * syntax only, no functional implementation
        * ² Square (same as ^ 2)
    * Prefix
        * - Negate (same as * -1)
        * √ Square Root (same as ^ .5)
    * Infix Operation
        * Power
            * ^ Exponentiation, like raku's **
                * mathematical convention dictates that this operation be chained
                right-to-left, which is NYI
            * √ Root, n√x is the same as x^(1/n)
                * evaluates to positive only (± NYI)
                * imaginary numbers NYI
                * ^/ is a Texan variant of √ with the operands reversed
                    * x^/n is the same as x^(1/n) or n√x
            * Logarithms are NYI, so no solving for variables in exponents yet
        * Scale
            * * Multiplication
            * / Division
        * Shift
            * + Addition
            * - Subtraction
    * Infix Relation
        * = Equality is currently the only relation supported
            * this is really because proper relations are more-or-less NYI
        * note that relations are optional in the input string, it automatically
        detects whether it is working with an expression or a relation
            * really it just breaks if you call 'solve' on an expression ATM

## BUGS

Many, in all likelihood. Patches graciously accepted.

AUTHOR
======

raydiak

COPYRIGHT AND LICENSE
=====================

Copyright 2014 - 2021 raydiak

Copyright 2025 Raku Community

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

