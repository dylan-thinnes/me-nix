{
    title = "A Short Introduction to GNU dc";
    author = "Dylan Thinnes";
    description = "Looking at how to use GNU dc, an arbitrary precision calculator, as a proper programming language w/ for & while loops.";
    time = "1565470468";
    content = ''
## What is GNU `dc`?

`dc` is a stack-based reverse polish notation calculator on the shell, with
registers & some nice macro capabilities. The macros also make it Turing
complete.

It comes prepackaged in most distributions of Linux, as well as MacOS.
Implementations exist for Windows.

A little manual by Ken Pizzini & Stallman is available
[here](https://www.gnu.org/software/bc/manual/dc-1.05/html_mono/dc.html).

## Basic Language
`dc` is very basic - at its core, it has a global stack onto which we can push
values, and a few basic operators (e.g. +, -) with which we can pop items from
the stack, and push the result back on to the stack.

For example:

```dc-repl
> 6     # Push 6 onto the top of the stack
> 3     # Push 3 onto the top of the stack
> 2     # Push 2 onto the top of the stack
> f     # Print the entire global stack using 'f'
2
3
6

> +     # Pop 3 and 2, add them, and push the result back
> f     # Print the stack
5
6

> *     # Pop 5 and 6, multiply, and push the result back
> f     # Print the stack
30
```

`dc` also comes with a few small convenience functions to manipulate the stack.
You've already seen the `f` function, which prints out the whole stack without
changing it. There are a couple of additional operators that every aspiring
`dc` hacker must know:

### Stack Manipulation

- `c`  
  Clear the entire stack.
- `d`  
  Duplicates the value on the top of the stack. A simple example below:
  ```dc-repl
  > 5   # Push 5 onto the top of stack
  > 1   # Push 1 onto the top of stack
  > f   # Print the stack
  1
  5
  > d   # Duplicate the top of the stack
  > f   # Print the new stack
  1     # There are now two copies of the "1", here
  1     # and here
  5
  ```
- `r`  
  Reverse the two items on the top of the stack. Another example:
  ```dc-repl
  > 6
  > 5
  > 1   # Push 6, then 5, then 1 onto the stack
  > f   # Print the current stack
  1
  5
  6
  > r   # Reverse the two items
  > f   # Print the new stack
  5
  1
  6
  ```

### Printing
- `f`  
  Print the entire stack without changing it.
  ```dc-repl
  > 5   # Push 5 onto the top of stack
  > 1   # Push 1 onto the top of stack
  > f   # Print the stack
  1
  5
  ```
- `p`  
  Print the item on the top of the stack without changing it.
  ```dc-repl
  > 5   # Push 5 onto the top of stack
  > 1   # Push 1 onto the top of stack
  > p   # Print the top of stack
  1
  ```
- `n`  
  Same as `p`, but pops the item on the stack & does not print a trailing
  newline

### Note on Whitespace

`dc` generally ignores all whitespace between commands. The only situations in which whitespace is important is:

- **To separate numbers.**  
  `82` means "push 82 to the stack", whereas `8 2` means "push 8 then push 2 to
  the stack".
- **Comments**  
  A `#` means `dc` will skip all remaining text until the next newline.
- **Register Operators**  
  Some operators, such as store and load (covered later), expect a single
  register name immediately afterwards. In these cases, a space following the
  operator will denote the register named ' '.

This means actions such as

```dc-repl
> 8
> 2     # Push 8, then 2
> +     # Add together
> f     # Print
10
```

can be written as

```dc-repl
> 8 2 + f
10
```

or as

```dc-repl
> 8 2+f
```

but not as

```dc-repl
> 82+f
```

## Registers

While all built-in operators use the global stack, there are named registers,
each a single character, which themselves can behave like stacks, from which we
can load (read) and to which we can store (write). 

These commands take the following formats: 

- `s{register}`  
  Store-as-value, overwriting anything in the register
- `S{register}`  
  Store-as-stack, pushing the new value onto the register's stack and
  pushing down the rest of the values
- `l{register}`  
  Copy-load, copy what's in the top of the register onto the global stack
- `L{register}`  
  Pop-load, remove what's in the top of the register and put it onto the
  global stack. This either empties the register, or makes the second-to-top
  value in the register available.

Here are a few examples in action:

```dc-repl
> 3     # Push 3 onto stack
> Sa    # Pop 3 from global, store it into top of register 'a'
> 2     # Push 2 onto stack
> Sa    # Pop 2 from global, store it into top of register 'a'
        # This pushes 3 down

> la    # Copy the top of register 'a' into the global stack
> La    # Pop the top of register 'a' into the global stack
> La    # Pop the top of register 'a' into the global stack

> f     # Print the entire global stack using 'f'
3       # The 2nd val in 'a', popped in the second call to 'La'
2       # The 1st val in 'a', popped in the first call to 'La'
2       # The 1st val in 'a', copied in the call to 'la'
```

### Note on Register Names

Each register is a single character, and can be pretty much anything printable,
however I recommend the following basic defaults, many of which are lifted from
[Wikipedia's entry on variables in mathematics](https://en.wikipedia.org/wiki/Variable_(mathematics)).

- Use upper case for permanent macros (explained in next section), and lower
  case for everything else (concrete values, temporary macros)  
  e.g. F for Fibonacci function, f for fibonacci sequence
- a, b, c, and d (sometimes extended to e and f) often represent parameters or
  coefficients.
- i, j, and k are often used to denote varying integers or indices in an
  indexed family. 

Later in this article, you will learn some small tips to avoid exhausting your
variables.

## Macros

Interestingly, numbers aren't the only values we can store in registers or in
the global `dc` stack. We can store strings, which are declared using `[` and
`]`, like so:

```dc-repl
> 3                 # Push "3" onto stack
> [hello there!]    # Push string onto stack
> f                 # Print stack
hello there!
3
```

These strings can then be executed by using the `x` operator, as if they were
code entered directly at the command line.

```dc-repl
> 5         # Push 5 onto stack
> [3 +]     # Store string on stack
> x         # Pop [3 +] from stack & execute it
> f
8
```

Of course, we can store strings in registers too, and then load them onto the
global stack to execute. Building on the previous example:

```dc-repl
> [3 +] sa  # Store [3 +] into register "a"
> 5         # Push 5 onto global stack
> la        # Copy [3 +] from register "a" onto global stack
> x         # Execute [3 +]
> f
8           # New value is 8, since we added 3 to it

> lax       # Copy & run [3 +] again
> lax       # And again...
> f
14          # New value is 14, since we added 3 twice
```

Most importantly, macros can call other macros too, or even themselves!

```dc-repl
> [2 *] sa
# Macro "b" will execute macro "a" four times
> [lax lax lax lax] sb

> 1         # Push 1 onto stack
> lb x      # Load macro from b, execute
> f
16          # New value is 16, since we doubled four times
```

Using macros, we can implement common programming language features such as
loops, as well as general subroutines.

## Flow Control

`dc` comes with a few switches that compare two values, and
conditionally execute a macro in a given register.

They take the following forms:

- `>{register}`  
  Pops the top value of the stack & second-to-top value of the stack.
  If the top is greater than the second-to-top, execute the macro in register.
- `<{register}`  
  Pops the top value of the stack & second-to-top value of the stack.
  If the top is less than the second-to-top, execute the macro in register.
- `={register}`  
  Pops the top value of the stack & second-to-top value of the stack.
  If the top is equal to the second-to-top, execute the macro in register.

Each switch can be negated by prepending the operator with `!`, e.g.
`!>{register}`.

Let's walk through an example.

```dc-repl
# The following macro, if executed, 
# will print "NUMBER IS GREATER"
> [[NUMBER IS GREATER]p]

> sa        # Store macro in register "a"

> 5 0 <a    # Since 5 is greater than 0, 
            # macro "a" is executed
NUMBER IS GREATER

> 0 5 <a    # Since 0 is not greater than 5,
            # macro "a" is not executed
```

## Looping Constructs

Now we can progress to building arbitrary looping constructs. We'll start with a simple version, criticize it and improve gradually.

This is the simplest loop in `dc`, it decrements the value in register "i",
runs the macro in register "x", and calls itself as long as i is greater than
zero.

```dc
[
    li1-si
    lxx
    li 0 <L
]sL
```

To run this loop, we put a number in i, a loop body in x, then run the macro by
loading L & executing it.

```dc-repl
> [lin] sx      # Load and print the loop index,
                # every time loop happens
> 4si           # Run the loop 4 times
> lLx           # Execute loop
3
2
1
0
```

**Note**: because we're decrementing the loop counter i until 0, unlike in most
languages we will loop through values i-1 to 0.

While this loop is very simple to write and understand, there are more than a
few problems with it. Let's begin with...

### Problem: Loops at least once

This should be the first and most obvious bug to tackle. Even if the loop
counter is already at 0 or below, the loop will still decrement & run at least
once.

```dc-repl
> [
>   lin     # Load the current loop index...
>   p       # Print it...
>   s_      # Store it in "_", the garbage register
> ] sx      # Store that as the execution macro
> 0 1 - si  # Store -1 in the index

> lLx       # Run the loop
-1          # Even though the loop counter is negative,
            # we still iterate once
```

To solve this, we'll introduce the concept of an internal submacro.

```dc
[
    [
        li1-si
        lxx
        li 0 <X # Store the original macro 
                # behaviour in new register X
    ]sX

    # Run submacro X only if register "i" is 
    # already greater than 0
    li 0 <X
]sL
```

By using register "X" for our submacro, we can avoid running it unless the
index is already greater than 0 from the get go.

If the index is already zero or negative, just abort without doing any looping.

### Problem: Remembering argument names

We've reserved the x and i registers for key behaviour. Code that wants to use
the loop needs to remember our naming convention.

It would be much better to be able to pass the macro and loop counter directly
to the stack and have the loop take it from there.

We can solve this by having an "initialization step" which puts our global
stack variables into appropriate registers for us.

```dc
[
    # Store i & x directly from global stack,
    # to use them during the execution of the loop
    si
    sx

    [
        li1-si
        lxx
        li 0 <X
    ]sX

    # Run submacro X
    li 0 <X
]sL
```

We've reserved a new register, "X", which serves as the tight inner loop that
run after macro in "L" has pulled our macro & loop count directly from the
stack.

```dc-repl
> [
>   [hello]ps_
> ]
> 4
> lLx
hello
hello
hello
hello
```

Now outside code can call our loop macro directly w/o having to remember any
argument names. Everything is positional, as it should be with stacks.

However, we still have quite a few problems. The next is:

### Problem: Nested loops

Every time a loop is started, it overwrites the internal x, i, and X registers.
While X may be the same for all loops, the contents of x and i will vary from
loop to loop.

This means that if we try to run a second loop inside our first loop, the inner
loop will overwrite the outer loop's counter, and the outer loop will exit
early or run the wrong code entirely.

The solution to this is to remember that our registers are themselves stacks we
store more and more nested loop counters & loop bodies by pushing those them to
stacks in our registers and popping off when we're done, rather than
overwriting the register entirely.

We can do this outside of the submacro.

```dc
[
    # Store directly from global onto i & x,
    # pushing on rather than overwriting
    Si
    Sx

    # Register X remains the same
    [
        li1-si
        lxx
        li 0 <X
    ]sX

    # Run submacro X
    li 0 <X

    # Post-initialization
    # Remove the values of x & i and bin them,
    # before leaving this loop
    Lis_
    Lxs_
]sL
```

By using `Sx` instead of `sx`, we push to a stack of macros to execute, and
then pop afterwards. Once we've left the loop, any calling context that was
using "x" previously can retrieve the old value that was there before entering
the loop.

Now we can do such things as nested loops:

```dc-repl
> [
>     [
>         # Print the current index without a newline
>         lin
>     ]
>     # Get the index of the outer loop, increment by 1, 
>     # run above macro that many times
>     li1+
>     lLx

>     # Print a newline
>     []ps_
> ]
> 4
> lLx
3210
210
10
0
```

## Variable Management

You'll notice using registers as stacks has another positive effect on our
loop: it makes it transparent to external code.

Because registers x and i are used as stacks and restored in postprocessing /
teardown, once the loop exits they are guaranteed to be the same as they were
before we started the loop (as long as the body we execute doesn't mess with
them).

This is why setup and teardown become so common in `dc`; restoring registers to
their original state is absolutely key to making reusable code that cooperates
well with other pieces of code.

What follows is the final application of that philosophy to our loop - by
changing our use of the "X" register from "s" and "l" to "S" and "L", we can
restore it at the end of our loop and make our loop completely reusable as far
as outside code is concerned.

```dc
[
    Si
    Sx

    # Register X remains the same
    [
        li1-si
        lxx
        li 0 <X
    ]SX     # Push to X as a stack

    # Run submacro X
    li 0 <X

    Lis_
    Lxs_
    LXs_    # Scrap top of X
]sL
```

## Better Loops & `dc` Patterns

Our current loop seems to be quite a big deal! We've solved all of the glaring
issues with the original loop.

Now, the question is how to improve our loops to maybe provide some finer
control to the user. The next few sections will tackle common use cases and how
we could adapt our loop for that.

Remember, however, that flexibility is **not** the key to everything. As John Carmack once said:

> *If you???re willing to restrict the flexibility of your approach, you can almost always do something better.*

The key is to remove flexibility in certain parts of your solution and add it
in other places, to properly fit your use cases.

### Postconditions

Take the following task: you have a stack of values in register "a", and you
need to sequentially print its top 4 elements, without actually changing the
register.

A quick and dirty solution using our previous loop:
```dc-repl
# Initialize register "a" to have string values A to E
> [E]Sa [D]Sa [C]Sa [B]Sa [A]Sa

# Iterate down & print
> [
>     La  # Load from register "a", store in global stack
>     p   # Print it
> ] 4 lLx # Do this 4 times
A
B
C
D

# Iterate back up & restore register "a"
> [
      Sa  # Store from the stack back into register "a"
  ] 4 lLx # Do this 4 times
```

Wouldn't it be nice to have the set-up & clean-up all in one loop? This is,
after all, a very common pattern in a language like `dc`: setup and teardown.

Having a dedicated clean-up routine could keep our code a lot clearer on what
is cleaning up and where.

It turns out, setting up a postcondition is easy when using a recursive
implementation of a loop:

```dc
[
    Si
    Sc # New register "c" for clean-up
    Sx

    [
        li1-si
        lxx
        li 0 <X
        lcx     # Run clean-up after recursion
                # has been fully explored
        li1+si  # Increment i as we bubble 
                # back up the loop stack
    ]SX

    # Run submacro X
    li 0 <X

    Lis_
    Lcs_ # Pop off of register "c" to keep transparency
    Lxs_
    LXs_
]sL
```

Now we can shorten our previous call to the much clearer:
```dc-repl
> [E]Sa [D]Sa [C]Sa [B]Sa [A]Sa # Initialize register "a"
> [Lap]     # Main loop body, runs i times 
> [Sa]      # Runs i times after main loop body is done running
> 4 lLx     # Run loop to 4 times
A
B
C
D
```

### Stack Traversal Patterns

It would be fairly simple to create a special loop for going through a stack,
but because loads and stores require a hard-coded register name, we could only
generalize it for a specific register, say register "a".

It is much simpler and versatile to learn the following three stack traversal
patterns for our loop construct:

#### Load and Store

This is the simpler pattern - it is best used for just reading out a list and
processing pieces of it and writing them somewhere else.

The main body must contain a `L{register}` at its end, and the cleanup body
must contain a `S{register}` at the start. In visual terms:

```dc
# Custom main logic goes before "L{register}"
[
    {custom main logic}
    L{register}
]
# Custom cleanup logic goes after "S{register}"
[
    S{register}
    {custom cleanup logic}
]
{loop counter} 
lLx
```

This guarantees one thing above all: as long as your loop counter does not
exceed the depth of the stack, there will be at least one value on the stack,
with the top value being the value for that iteration of the loop.

For example, the following macro iterates through the first four elements of
register "a" and adds all of the even ones to register "t":

```dc-repl
> [
>     # If the top of register "a" is even, store in t
>     [
>         la # Copy off the top of register "a"
>         St # Push it to register "t"
>     ]Sx
>     la2% 0 =x
>     Lxs_
>
>     # Finish w/ La, as is normal for this pattern
>     La
> ]
> [Sa] # Cleanup w/ Sa
> 4
> lLx
```

#### Load, Modify, then Store

Whereas the previous pattern was only interested in reading & copying, this
pattern allows editing in-place of the stack. In short, it's an in-place map.

The main body must contain a `L{register}` at its **start**, or the cleanup
body must contain a `S{register}` at the **end**. In visual terms:

```dc
# Mapping logic can either go after La,
[
    La 
    {mapping logic}
]
# or before Sa
[
    {mapping logic}
    Sa
]
{loop counter}
lLx
```

Whatever mapping logic you use will have access to all the previous elements in
the register. Use this wisely - you should only modify the topmost value!

This way, when the `Sa` operation comes round to collect the old list values, you'll have changed them on the stack ahead of time.

For example, this sample will add 1 to the first four values of the register
"a".

```dc-repl
> [
>     La    # Start w/ La, as is for pattern
>     1+    # Increment top of stack by 1
> ]
> [Sa]      # Finish w/ Sa
> 4
> lLx
```

#### Folding

For those of us who aren't functional programmers or just haven't used a reduce
recently, a fold is a gradual traversal through a stack, while keeping track of
an accumulator value to store the result.

Unlike using a dedicated register, this has the advantage of living entirely on
the top of the stack, which makes passing things around a bit simpler.

The main body must contain a `L{register} r` at its end, and the cleanup body
must contain a `r S{register}` at the start.

Also, before passing arguments to our loop, we must make sure to push an
initial accumulator to the global stack. In visual terms:

```dc
{original accumulator}
# Custom main logic goes before "L{register} r"
[
    {custom main logic}
    L{register}
    r
]
# Custom cleanup logic goes after "S{register}"
[
    r
    S{register}
    {custom cleanup logic}
]
{loop counter} 
lLx
```

There isn't much to say on this subject - the `r` after `La` does an important
job of keeping the accumulator on the top of the stack while we traverse down,
and the `r` before the `Sa` pushes the accumulator down and brings the current
stack value up, just before we push it back to the stack.

Let's look at an example - this takes the product of top first four elements of
stack "a".

```dc-repl
> # Initialize stack "a" w/ values 7,5,3,2
> 2Sa 3Sa 5Sa 7Sa

> 1
> [la* La r]  # Copy the top of the stack, 
>             # multiply it by the accumulator
> [rSa]       # Close up the pattern
> 4
> lLx
> p           # Print the final accumulator value
210           # == 7 * 5 * 3 * 2
```

### Iterating Upwards

Interestingly, because our clean-up runs as the "i" register gets reincremented
to its original value, logic placed in the clean-up will experience "i"
progressing from 0 to n-1, instead of n-1 to 0.

```dc-repl
> [] [lips_] 4 lLx # Load & print i for each clean-up
0
1
2
3

# Compare this behaviour to normal recursive step:
> [lips_] [] 4 lLx # Load & print i for each step
3
2
1
0
```

### While Loops

Finally we come upon the while loop, that most versatile of loops, but to be
used judiciously, lest you find yourself back at an error-prone version of a
for-loop.

- Predicate  
  For our while loop, we will need a predicate macro. When run, the macro will
  leave a value on the top of the stack. If that value is 0 or negative, we
  halt the recursion. Otherwise, continue recursing.

- Arguments  
  As with the for loop, we will still pass in a main body and clean-up body,
  but instead of a number for the third argument, we will pass the predicate
  macro, like so.

- Different Name  
  Also, rather than use the "L" register for our construct, let's use the new W
  for while.

```dc
{main body} {clean-up} {predicate} lWx
```

Internally, we can use the "b" register (chosen for **b**oolean) to store the
macro. The implementation is actual quite trivial to extend from that of our
existing loop.

```dc
[
    Sb # Replace "i" w/ "b" for predicate macro
    Sc
    Sx

    [
        lxx
        lbx 0 <X # As long as the predicate macro returns
                 # a positive value, keep recursing
        lcx
    ]SX

    # Change condition down here too
    lbx 0 <X

    Lbs_ # As always, pop off "b" to keep transparency
    Lcs_
    Lxs_
    LXs_
]sW
```

Let's go for a classic example: find the largest factorial under a given
maximum.

```dc-repl
> 0si           # Use i as running counter
> 1st           # Use t as total
> 100000000sm   # Use m for maximum
>               # Find factorial under 100 million
> [
      li1+si    # Increment i
      ltli*st   # Multiply t by i
  ]
  []
  [
      lmlt-     # As long as total is less than maximum, 
                # the resulting value will be greater 
                # than 0 and looping will continue
  ]
  lWx
> ltli/         # Undo final multiply step
> p             # Print factorial number
39916800
> li1-p         # Print what nth factorial number it is
11
```

And with that you're done!

## Finishing Up

That's all for now folks! Hopefully you found this little intro to powerful `dc`
useful! Admittedly, I haven't gotten up to anything particularly clever w/ `dc`
yet, though I do experiment from time to time. Maybe I'll make a part two
sometime when I've got some more pretty things to show off. Until then, adieu!
    '';
}
