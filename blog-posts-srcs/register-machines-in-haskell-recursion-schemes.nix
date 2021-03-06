{
    title = "Register Machines, Part 4 - Nondeterminism, Rose Trees, and Data as Computation";
    author = "Dylan Thinnes";
    description = "In this post, we go over how we can add nondeterminism to our machines using rose trees and a bit of thinking.";
    time = "1629728156";
    content = ''

It's more common than you'd think.

A non-deterministic machine, put simply, can be characterized as one that takes
multiple routes *simultaneously*, rather than picking one route or another.
Such a machine can fork into two or more different states any number of times,
and those states run alongside one another. The machine doesn't halt until
*all* active states have halted.

## Example

That might be a bit of a mind-bending trick, so let's start by going through an
example.

### The BOTH Instruction

So far, all of our instructions were deterministic: they all have one outcome
given a state. To have a nondeterministic machine, we'll need a
nondeterministic instruction.

Let's create a nondeterministic `BOTH` instruction - it takes two labels as
arguments, and "forks" the machine, producing one state in which the program
counter has jumped to the first label, and another state where it jumped to the
second label.

### Simulation

Much like in Part 1, we'll step through an actual program, marking the current
instruction counter. However, since we can have multiple states, we'll mark
each state's program counter with a number, rather than a star, using a
"comment" at the end of each line.

<h4>Step 1</h4>

The following is our source code, it has two labels, `A` and `B`, and a bunch
of increments besides. The first line is marked with `-- #1` to indicate that
currently the only active state is #1, and that it is on the first instruction.

```hs
-- State #1: Register 0 = 0
    INC 0    -- #1
    BOTH a b
    INC 0
a:  INC 1
    INC 1
b:  INC 2
    INC 2
```

The first simulation step is simple: we increment the 0th register in state #1,
and step forward by one. For the time being, there is only one state. We
progress to the `BOTH` instruction with 

<h4>Step 2</h4>

```hs
-- State #1: Register 0 = 1
    INC 0
    BOTH a b -- #1
    INC 0
a:  INC 1
    INC 1
b:  INC 2
    INC 2
```

This line is now going to initiate a "fork", and create two new states: one at
label `a` and another at label `b`. Both states will otherwise inherit
everything, including register state.

<h4>Step 3</h4>

```hs
-- State #2: Register 0 = 1
-- State #3: Register 0 = 1
    INC 0
    BOTH a b
    INC 0
a:  INC 1    -- #2
    INC 1
b:  INC 2    -- #3
    INC 2
```

Now that we've executed the `BOTH` instruction, states #2 and #3 have been
initialized and state #1 has disappeared. The comments show us their current
register values are copied from state #1 and identical, but their positions
differ.

<h4>Step 4</h4>

Now let's step forward - remember, both states will step forward
simultaneously!

```hs
-- State #2: Register 0 = 1
--           Register 1 = 1
-- State #3: Register 0 = 1
--           Register 2 = 1
    INC 0
    BOTH a b
    INC 0
a:  INC 1
    INC 1    -- #2
b:  INC 2
    INC 2    -- #3
```

Notice how when both counters moved forward, the two states each executed different increment instructions:
- State #2 ran `INC 1`, and thus incremented register 1
- State #3 ran `INC 2`, and thus incremented register 2

Now execution is relatively straightforward: we keep stepping forward until
both state #2 and state #3 reach the end of the program.

<h4>Step 5</h4>

```hs
-- State #2: Register 0 = 1
--           Register 1 = 2
-- State #3: Register 0 = 1
--           Register 2 = 2
    INC 0
    BOTH a b
    INC 0
a:  INC 1
    INC 1
b:  INC 2    -- #2
    INC 2
             -- #3 (HALTED)
```

This is the point of true divergence.

State #2 and state #3 executed `INC 1` and `INC 2` respectively, so their
states now reflect that in their registers.

Notice, however, that state #3 has reached the end and halted, but state #2
still has space to progress forward, reaching label `b`. 

We'll finish the next two steps of simulation in one section.

<h4>Step 6</h4>

```hs
-- State #2: Register 0 = 1
--           Register 1 = 2
--           Register 2 = 1
-- State #3: Register 0 = 1
--           Register 2 = 2
    INC 0
    BOTH a b
    INC 0
a:  INC 1
    INC 1
b:  INC 2
    INC 2    -- #2
             -- #3 (HALTED)
```

Now while state #3 is halted, state #2 continues, executes `INC 2`, and adds 1
to register 2.

<h4>Step 7</h4>

```hs
-- State #2: Register 0 = 1
--           Register 1 = 2
--           Register 2 = 2
-- State #3: Register 0 = 1
--           Register 2 = 2
    INC 0
    BOTH a b
    INC 0
a:  INC 1
    INC 1
b:  INC 2
    INC 2
             -- #2 (HALTED)
             -- #3 (HALTED)
```

Finally, state #2 finishes, executing `INC 2` in the process, and since all
states have halted, our nondeterministic machine halts.

In 7 steps, we've executed one machine and ended up with two different states.

## Why have nondeterminism?

Some among you may be wondering, why do we need this? After all, it would be
possible to write a simulator inside of a deterministic register machine, and
simulate multiple register machines that way. That would mean that anything a
nondeterministic machine can do, a deterministic machine can do too.

Well, not exactly. While both kinds of machine can solve the exact same set of
problems, they are not the same in the amount of steps ("time") taken to solve
their respective problems, because in a nondeterministic machine, all states
step forward at the same time, counting for a single step in which a
potentially huge number of instructions are run simultaneously. 

# Defining Nondetermistic Instructions

Now that you understand nondeterministic machines, and the relative importance
of studying them, let's extend our register machine simulator to run
nondeterministic machines and instructions!

## Adapting our Types

As usual, let's begin with adapting our types for this new feature.

The simplest way to adapt our machine to express nondeterminism would be to
have an `interpret` function that can return more than one new machine state
for a given instruction.

Our old deterministic machine's `interpret` function looked something like:

```hs
interpret :: Instruction (Either label Position) -> State label -> State label
```

Our new, nondeterministic machine state would have an `interpret` function more
like the following:

```hs
interpret :: Instruction (Either label Position) -> State label -> [State label]
```

This way, one instruction can produce multiple new `State label` results, which
represents the "branching" behaviour that nondeterministic machines have.

### Determinism is a Special Case of Nondeterminism

Deterministic instructions still work in this model - they need only return a
singleton list, with one state. However, there is a problem: Remember from Part
3, our `interpret` function is now implemented using `interpretInstr`, which
belongs to the `IsInstruction` typeclass.

If we change the type of `interpretInstr`, we would then need to go through
every instruction make a small tweak to return a singleton list. However, that
would obscure a lot of info! We want it to be clear when a deterministic
instruction actually is, and only upgrade it to return a singleton list when
running it in a nondeterministic machine.

### A New Typeclass

This is where typeclasses can come to the rescue, by creating a new typeclass,
`IsNondetInstruction`, and then adding an implication that turns all
`IsInstruction` instances to `IsNondetInstruction` instances
automatically.

We'll start by just defining our new typeclass, using the new type for an
`interpret` function that we will call `interpretNondetInstr`. We'll lift
deterministic instructions to it later.

```hs
-- Existing definition of IsInstruction:
class IsInstruction instr where
    interpretInstr :: instr (Either label Position)
                   -> State label -> State label

-- New definition of IsNondetInstruction:
class IsNondetInstruction instr where
    interpretNondetInstr :: instr (Either label Position)
                         -> State label -> [State label]
```

Now we have the basis for our `IsNondetInstruction` typeclass. Let's implement
our `BOTH` instruction with it!

## Implementing BOTH

To start in our implementation of `BOTH`, we first need a data type to express
it. That should be trivial, we just need a constructor that can hold two
labels.

```hs
{-# LANGUAGE DeriveFunctor #-}
data Both label = Both label label
    deriving (Show, Eq, Ord, Functor)
```

We've derived the functor instance for our labels, and can now move to
implementing `IsNondetInstruction` for it.

```hs
instance IsNondetInstruction Both where
    interpretNondetInstr :: Both (Either label Position)
                         -> State label -> [State label]
    interpretNondetInstr (Both labelA labelB) oldState = undefined -- ?
```

We start by unpacking the constructor to retrieve a `labelA` and a `labelB`.
Now we just need to return two new states: one with the program counter set to
`labelA`, and another with the program counter set to `labelB`.

We can set the label to anything we like with `setCounter`, a helper we wrote
back in Part 1 and updated in Part 2. I've replicated it here for our sake:

```hs
updateCounter :: (Either label Position -> Either label Position) -> State label -> State label
updateCounter f state@(State {..}) = state { counter = f counter }

setCounter :: Either label Position -> State label -> State label
setCounter pos = updateCounter (const pos)
```

Using this helper, implementing `Both` is extremely mechanical:

```hs
instance IsNondetInstruction Both where
    interpretNondetInstr :: Both (Either label Position)
                         -> State label -> [State label]
    interpretNondetInstr (Both labelA labelB) oldState =
        [ setCounter (Right labelA) oldState
        , setCounter (Right labelB) oldState
        ]
```

For those that are slightly confused that we are using `labelA` as a
`Position`, remember that this is because our code from Part 2 will replace any
labels in our instructions with resolved `Position`s before the simulator runs.

## Lifting Determinism to Nondeterminism

As I promised earlier, since all deterministic instructions can run in a
nondeterministic machine, we can write an implication that derives an
`IsNondetInstruction` instance for all deterministic instructions.

```hs
instance (IsInstruction instr) => IsNondetInstruction instr where
    interpretNondetInstr instruction state = [interpretInstr instruction state]
```

That's a relatively simple implication, but it works - additionally, it means
that we can't explicitly define an instruction as both deterministic and
nondeterministic. That means, as long as our nondeterministic interpreter is
well-written, our deterministic programs will run identically on both the
deterministic and nondeterministic interpreter.

## Handling Sums, Too

Finally, we need to replicate the code that turns a `Sum` of
`IsNondetInstruction` instances into an instance of `IsNondetInstruction`. This
is a very mechanical process - written out below is the definition for
`IsInstruction (Sum f g)` from Part 3 and the new altered version for
`IsNondetInstruction (Sum f g)`.

```hs
-- Part 3 definition
instance (IsInstruction f, IsInstruction g) => IsInstruction (Sum f g) where
    interpretInstr (L f) state = interpretInstr f state
    interpretInstr (R g) state = interpretInstr g state

-- New definition for IsNondetInstruction
instance (IsNondetInstruction f, IsNondetInstruction g) => IsNondetInstruction (Sum f g) where
    interpretNondetInstr (L f) state = interpretNondetInstr f state
    interpretNondetInstr (R g) state = interpretNondetInstr g state
```

As you can see, all we needed to do was insert `Nondet` in the appropriate
places.

# Running Nondeterministically

Now that we have a good set of typeclasses to represent any nondeterministic
instructions, will all of the benefits we've added in Parts 1, 2, and 3, we
need to write a step function that can handle nondeterminism.

Our previous approach, iterating until reaching an end state, is no longer
appropriate, since at any point we may branch multiple ways.

```
-- Deterministic
initial state -> state1 -> state2 -> ... -> terminal state

-- Nondeterministic
initial state -> state1 -> state3 -> ...
                        -> state4 -> ...
              -> state2 -> state5 -> ... -> terminal states
                        -> state6 -> ...
                        -> state7 -> ...
```

## Suppose Roses

It turns out that the branching structure is pretty easily represented using a
common data structure, the "rose tree", which is just a branching tree like
structure where every node contains a value of type `a`, and zero or more
children which are themselves nodes.

A rose tree is easily (and na??vely) defined like this:

```hs
data Rose a = Node a [Rose a]
```

For our purposes, we won't have a `Nil` or `Leaf a` node, since we can
guarantee that any tree of machine states always starts with at least one root
state, and terminal nodes can be shown by having an empty list, no children.

We could express a pretty standard progression of nodes like this:

```hs
Node (state1)              -- Initial state
    [ Node (state2) []     -- Terminal state
    , Node (state3)        -- Interim state
        [ Node (state5) [] -- Terminal state
        , Node (state6) [] -- Terminal state
        ]
    , Node (state4) []     -- Terminal state
    ]
```

## Writing the Runner

Armed with our new data structure, and the `interpretNondetInstr` function, we
can finally write our nondeterministic `run`ner, which we can call
`runNondet`. As is our maxim, we start with types:

```hs
-- Old deterministic runner function type:
run :: (IsInstruction instr) => Machine instr label -> Machine instr label

-- New nondeterministic runner function type:
runNondet :: (IsNondetInstruction instr) => Machine instr label -> Rose (Machine instr label)
```

This will be fundamentally quite different from our old `run` function -
whereas the old `run` function took a starting state and produced a single
ending state, our `runNondet` function will produce a rose tree.

This rose tree will contain the start state and all intermediate states in a
large branching tree, whose leaves are the different final "halting" states.

We will go over how this "data-structure" approach is advantageous later.

### Types into Code

Now that we have the basic starting point in our types, let's write some code!

First, look at the source code for `run`, which will offer a very good starting
point:

```hs
run :: IsInstruction instr => Machine instr label -> Machine instr label
run machine@(Machine {..})
    = case currInstruction machine of
        -- If there is no instruction, assume the machine has halted and return it
        Nothing -> machine
        -- If there is an instruction, transform the state using it, and run
        -- the interpreter again on that new machine
        Just instruction -> run
                          $ machine { state = interpret instruction state }
```

Let's copy the body of `run` up until the case statement.

```hs
runNondet :: IsNondetInstruction instr
          => Machine instr label -> Rose (Machine instr label)
runNondet machine@(Machine {..})
    = case currInstruction machine of
        Nothing -> undefined
        Just instruction -> undefined
```

We now need to handle each case: if the node's current instruction is
`Nothing`, clearly we are at a terminal node, and can return a Rose tree node
with no children.

```hs
runNondet :: IsNondetInstruction instr
          => Machine instr label -> Rose (Machine instr label)
runNondet machine@(Machine {..})
    = case currInstruction machine of
        -- At a terminal node, return a node with no children
        Nothing -> Node machine []
        Just instruction -> undefined
```

If the node's current instruction is `Just <instruction>`, then clearly we need
to run that instruction on the current machine state using
`interpretNondetInstr`. Since the instruction is nondeterministic, we may get
multiple new states in a list - naturally, we store that as the children!

```hs
runNondet :: IsNondetInstruction instr
          => Machine instr label -> Rose (Machine instr label)
runNondet machine@(Machine {..})
    = case currInstruction machine of
        -- At a terminal node, return a node with no children
        Nothing -> Node machine []
        Just instruction -> Node machine
                            $ interpretNondetInstr instruction machine
```

Unfortunately, this won't typecheck! 

- The states that we store, produced by `interpretNondetInstr machine`, are of
  type `[Machine instr label]`. 
- What we need is a value of type `[Rose (Machine instr label)]`.
- Luckily, we already have a function that can turn any `Machine instr label`
  into a `Rose`: `runNondet` itself!

By mapping `runNondet` on every child machine state, we will turn `[Machine
instr label]` to `[Rose (Machine instr label)]`, which we can use as children,
completing our recursive call.

```hs
runNondet :: IsNondetInstruction instr
          => Machine instr label -> Rose (Machine instr label)
runNondet machine@(Machine {..})
    = case currInstruction machine of
        -- At a terminal node, return a node with no children
        Nothing -> Node machine []
        Just instruction
        -> let childStates = interpretNondetInstr instruction machine
               childNodes = map runNondet childStates
            in Node machine childNodes
```

And there we have it: a runner for machines with nondeterministic instructions!

# Modelling Computation with Data

Now that we have a data structure representing the computation steps of a
machine, it is easy to write generic functions over those trees to query a
machine's behaviours.

Let's start with a simple one: we only want all of the end states of our
machine, and don't care how we got there. Such a function would need to collect
the leaves of our data structure.

```hs
leaves :: Rose a -> [a]
leaves (Rose x []) = [x]
leaves (Rose _ xs) = concat $ map leaves xs
```

Thus, `leaves . runNondet` is the end-states-only function we're looking for.

```hs
getAllEndStates :: Machine instr label -> [Machine instr label]
getAllEndStates = leaves . runNondet
```

> Note: This implementation is actually quite inefficient - a better choice of
> type signature for `leaves`, using a monoid, and then instantiating that
> monoid to a different list implementation, would give us more flexibility and
> speed.

Another, more interesting function would be `path`; it lets us extract a
specific path from a rose tree using a function on the current node, until
there are no children left to run on.

```hs
path :: (a -> [Rose a] -> Rose a) -> Rose a -> [a]
path f (Rose x []) = [x]
path f (Rose x xs) = x : f x xs
```

Using the `path` function, for example, we could get the "firstmost" branch in
the entire tree and return that as a path of states, from initial to final.

```hs
path (\_ children -> children !! 0) -- Always takes the firstmost branch
```

The path function essentially gives us the ability to turn our nondeterministic
functions into deterministic ones again.

## The Advantage of Computation as Data

This is an advantage of expressing our computation's results in terms of data
structures - it allows us to use common query functions on those data
structures to implement complex functionality that would otherwise need an
error-prone custom function.

This is a version of a more general concept that ends up being very valuable in
the long run: use data structures to model the general form of your
computation, and then populate that data structure with the results and
intermediary values of your computation. This makes it easy to halt, inspect,
transform, and enhance your computation using functions for those data
structures, rather than having to write a custom function for each operation.

## Determinism's Data

So, since we've seen the advantages of using data structures to store our
computation process, can we take what we've done for nondeterminism and apply
it to determinism?

The answer, of course, is yes! In fact, you may have an inkling of a data
structure that is appropriate for modelling our deterministic machines: a list!

```hs
[initial_state, state1, state2, ..., final_state]
```

Let's call the runner that returns a list of states `runDet`. Its type will be:

```hs
runDet :: IsInstruction instr => Machine instr label -> [Machine instr label]
```

How would we define such a function? We'll start with copying `run`, stubbing
out the branches of the case statement.

```hs
runDet :: IsInstruction instr
       => Machine instr label -> [Machine instr label]
runDet machine@(Machine {..})
    = case currInstruction machine of
        -- At a terminal node...
        Nothing -> undefined
        -- When there are instructions left to execute...
        Just instruction -> undefined
```

### The Nothing / Base Case

The `Nothing` or "base" case is self-evident - when there is no current
instruction under the program counter, that means our machine has halted, so we
return a list with the machine state in it.

```hs
runDet :: IsInstruction instr
       => Machine instr label -> [Machine instr label]
runDet machine@(Machine {..})
    = case currInstruction machine of
        -- At a terminal node... return the final state
        Nothing -> [machine]
        -- When there are instructions left to execute...
        Just instruction -> undefined
```

### The Just / Recursive Case

The `Just` branch, as usual, is our point of recursion. Here, we get the
remaining list of states using a recursive call, and then prepend the current
machine state to it.

```hs
runDet :: IsInstruction instr
       => Machine instr label -> [Machine instr label]
runDet machine@(Machine {..})
    = case currInstruction machine of
        -- At a terminal node... return the final state
        Nothing -> [machine]
        -- When there are instructions left to execute... make recursive call
        Just instruction -> machine : runDet (interpretInstr instruction machine)
```

Success!

### Inspecting Deterministic Computation

Now, we can inspect the computation of our deterministic machine using standard
list manipulators. Some examples:

```
last . runDet       -- See only final state - equivalent to `run`
\m -> runDet m !! 3 -- See third computation step (errors if none!)
reverse . runDet    -- Inspect computation flowing backwards
```

As you can see, what previously would've needed higher-order functions, can now
be accessed using utilities that everyone is familiar with from their first day
in Haskell, or indeed any language.

## Final Thoughts

Some of you may have noticed the very similar structure of our two interpret
functions: both functions pattern match on the current instruction. If the
instruction is `Nothing`, halt on a "base case" of the structure. If it is
`Just`, continue by embedding the state in the node, and make recursive calls
on the children of the structure.

It turns out, finding these similarities between structures and their children,
and growing them from a "step" function, is a subject well-worth reading about
called recursion schemes. If you've never heard of recursion schemes I can
wholeheartedly recommend [Patrick Thompson's 6 part series on the
subject](https://blog.sumtypeofway.com/posts/introduction-to-recursion-schemes.html).

My existing implementation on Github uses these recursion schemes, which lets
us simplify our `run` functions to work for any adequately defined data
structure. Please feel free to look in the repo, linked below, to get an idea
of how this all works.

# Adios for Now

In Part 1, we covered the basics of building a Register Machine simulator in
Haskell. In Part 2, we added the nice-to-have that is labels, while
demonstrating the guarantees and simple refactoring that typing gives us. In
Part 3, we implemented custom instructions that can transcend module and
compilation boundaries, while still being type-safe.

In this section, we extended our system to handle nondeterminism, also covering
the importance of encoding our computation as data where available.

Here is what remains from the list of TODOs we covered at the end of Part 1:

- Parser to read in RM pseudo-source-code like in section 1 and run it.
- "Macros", so we can write and insert subprograms.

However, this series has gone on long enough, and I worry that if I let myself
continue I'll never run out of things to write about.

These and more *may* be covered in future blog posts! If you can't wait, you
can look at the [final implementation at my
repository.](https://github.com/dylan-thinnes/register-machine)
    '';
}
