{
    title = "Register Machines, Part 2 - Freeform Labels";
    author = "Dylan Thinnes";
    description = "In this post, we continue onwards to explore how our register machines can be liberated to have freeform labels.";
    time = "1587229374";
    content = ''
# Defining Flexible Labels

***This is the second post in a series on implementing register machines in Haskell. If you haven't read Part 1, I'd recommend you [go back to read it](/blog/register-machines-in-haskell).***

So what exactly are "flexible" labels? What aspect of our existing labels makes
them "inflexible"?

Let's take a look at the sample program we wrote in the previous post. I've marked the labels in decjz instructions with brackets.

```
 1: inc 0
 2: decjz 0 [7]
 3: inc 1
 4: inc 2
 5: inc 3
 6: decjz 3 [2]
 7: inc 4
```

There are three obvious problems with this labelling system, and a clear
solution to each one.

1.  **Problem:** Every time a new line needs to be inserted for new
    functionality, we need to change all gotos for lines after the new line,
    and keep the ones before.

    **Solution:** Each label point should be independent, rather than ordered.
    This way changing one label affects none of the other labels.

2.  **Problem:** Line numbers contain no information as to the role of that
    specific jump point in the program. A string such as "loop1" would be far
    more useful.

    **Solution:** Labels should be strings or something that can carry a name,
    so that the reader can identify what each label does.

3.  **Problem:** Every line needs to be numbered - as the reader, we can't
    ignore lines that are never used as jump points, since every line has an
    associated label.

    **Solution:** Allow some lines to have no label at all.

Ideally, our program above could be written as something more like the
following:

```
        inc 0
loop:   decjz 0 exit
        inc 1
        inc 2
        inc 3
        decjz 3 loop
exit:   inc 4
```

Isn't that a lot cleaner and easier to [grok](https://en.wikipedia.org/wiki/Grok)?

# Implementing Our Solution

So, to summarise our solution, we need a system where:

- Labels don't need to be ordered.
- Labels can take on any typed value with reasonable meaning to the programmer.
- Some lines can have no label at all.

As usual, we will start with the types and work our way forwards to the code.

## Start with Program source code

Since we're making changes to how source code is represented before being run,
let's begin by adapting the type signature of `Program`.

Since our `Instruction`s still have a clear ordering, we will still need a
linked list, but we will also need to annotate them with information, so we can
use a simple list of tuples.

```hs
type Program = [(?, Instruction)] -- What do we store in the "?"
```

Since we want to be able to have any label type, lets paramaterize the
`Program` by `label`.

```hs
type Program label = [(label, Instruction)]
```

However, we also need to be able to have no annotation, so wrapping in a Maybe
is a quick and decent choice.

```hs
type Program label = [(Maybe label, Instruction)]
```

## Adapting Instructions to Flexible Labels

However, now that our labels could be anything, the `Label` type used
internally by `Instruction` can only point to `Integer`s. Let's fix that by
making the `Instruction` also paramaterizable by label.

```hs
{-# LANGUAGE DeriveFunctor #-}
data Instruction label = Inc Register | Decjz Register label
    deriving (Show, Eq, Functor)

-- We can now pass our label to the instruction and be sure that it agrees.
type Program label = [(Maybe label, Instruction label)]
```

Great, we have a type signature to represent our code internally! Let's take
this for a spin and write some Haskell code that would represent our program:

```hs
myProgram :: Program String
myProgram =
    [ (Nothing,     Inc 0)              --            inc 0
    , (Just "loop", Decjz 0 "exit")     --    loop:   decjz 0 exit
    , (Nothing    , Inc 1)              --            inc 1
    , (Nothing    , Inc 2)              --            inc 2
    , (Nothing    , Inc 3)              --            inc 3
    , (Nothing    , Decjz 4 "loop")     --            decjz 3 loop
    , (Just "exit", Inc 4)              --    exit:   inc 4
    ]
```

If you squint, you can see just how our original simplified source code on the
right became the Haskell encoding on the left.

## Introducing "Assembled"

Unfortunately, our old stepping code won't work very well with this "list"
approach. What we need is an `Assembled` version of a `Program`, where all
instructions are assigned an Integer and all labels are resolved to an Integer,
so that our old stepping code can be run with the bare minimum of
modifications.

As usual, let's begin by deriving the type of Assembled code. Since
instructions now contain free labels, we'll want to resolve them to Integers.
Thus, maybe an `Array` sending `Position`s to `Instruction`s would be best for
Assembled?

```hs
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
import Data.Array

newtype Position = Position Integer
    deriving (Show, Eq, Ord, Enum, Num)

type Assembled = Array Position (Instruction Position)
```

However, some labels pointed to in instructions will not resolve to any label
in the program. In that case, we want to preserve the `Instruction`s prexisting
label. Thus, a better choice of argument to `Instruction` is `Either label
Position`.

```hs
type Assembled label = Array Position (Instruction (Either label Position))
```

### A Moment for Reflection

There, we now have a rational definition for `Assembled label`. Now: notice how
our definition for a `Program` has progressed from the type we had in our
previous blog post.

```hs
-- PREVIOUS VERSION
type Program = Map Label Instruction

-- NEW VERSION
type Program label = [(Maybe label, Instruction label)]
type Assembled label = Array Position (Instruction (Either label Position))
```

The previous definition of `Program` did two separate jobs, code representation
and code interpretation. We have now split that into two more purpose-built
types which perform each job better.

### Converting Program to Assembled

Now, we need a function which takes our original `Program` with `label` and,
regardless of the `label`, associates a `Position` with each `Instruction` and
resolves every `label` to its appropriate `Position`, *if* it exists.

We'll start with some helper functions for querying `Program`s. The first is
`labelsPositions`, which will return a map of `label`s to `Position`s in the
code, given a `Program` definition.

```hs
{-# LANGUAGE TupleSections #-}
import Data.Maybe (catMaybes)
import Data.Map (Map)
import qualified Data.Map

-- Get all of the labels out of a Program, with their positions attached
labelsPositions :: (Ord label) => Program label -> Map label Position
labelsPositions program = Data.Map.fromList
                        $ catMaybes
                        $ zipWith extractLabelPos program [0..]
    where
    -- Given a Maybe label and an instruction and a position, join the position
    -- with the instruction only if it exists
    extractLabelPos (maybeLabel, _) pos = fmap (,pos) maybeLabel
```

This will be useful to convert `label`s into `Position`s inside of each
`Instruction label` we encounter.

Next, we define a simple helper, `mayToErr`, which will apply a partial
function `f :: (a -> Maybe b)` on a value `x :: a`, returning `Right result`
if the function returns `Just result` and returning `Left x` otherwise.

```hs
mayToErr :: (a -> Maybe b) -> a -> Either a b
mayToErr f a = case f a of
    Just b  -> Right b
    Nothing -> Left a
```

Using this, partial functions can keep the old information that they fail with.

We will also need another simple helper: it turns a list into an array, indexed
by some `Num`. Though it is not an important function to understand, I define
it here so you, dear reader, can define it while following along in a REPL or
program.

```hs
listToArray :: (Num i, Ix i) => [a] -> Array i a
listToArray list = listArray (0, fromIntegral $ length list - 1) list
```

Now, we can define our assembler, which uses these two helper functions to
quickly turn all `label`s into `Position`s, using the `Functor` instance of
`Instruction`, and then attaches a `Position` to each `Instruction` in
sequence.

```hs
{-# LANGUAGE ScopedTypeVariables #-}
import Data.Map ((!?))

assemble :: forall label. (Ord label) => Program label -> Assembled label
assemble program = assembled
    where
    -- First, get labels with positions
    lpos = labelsPositions program
    -- Define a function which will "assemble" a given label to a Position, if
    -- it exists
    assembleLabel :: label -> Either label Position
    assembleLabel label = mayToErr (lpos !?) label
    -- Get all instructions, and "assemble" their labels, using fmap
    instrs :: [Instruction (Either label Position)]
    instrs = map (fmap assembleLabel) (map snd program)
    -- Zip together positions and instrs, and turn that into an Array
    assembled = listToArray instrs
```

As you can see, we start by finding `Position`s, then `fmap` over each
`Instruction label` to turn those instructions to using `Position`s. Finally,
we assemble that all into an `Array` that fits the definition of `Assembled`.

## Building Machines with our Assembled

Now, we need a machine to contain our `Assembled` and then functions to
interpret that machine. Because we did the work of defining appropriate types
up front, our types differ only slightly from our last post, and the code can
be minimally adapted.

### Start With Data Types

Let's start with the data types & functions to define & construct machines:

```hs
-- Allow State's counter to provide a label or a Position
data State label = State
    { counter :: Either label Position
    , registers :: Map Register Integer
    }

-- Replace the `Program` with `Assembled label`, parametrize by label
data Machine label = Machine
    { assembled :: Assembled label
    , state :: State label
    }

-- Parametrize `Interpreter` over `Either label Position`
type Interpreter label = Instruction (Either label Position) -> State label -> State label
```

As you can see, the changes were:

- We changed `Program` to `Assembled`.
- Allowed `counter` to be either a `label` or `Position`.
- Parametrized all three main types over `label`.

In order to build machines more easily, let's build a `toMachine` helper which
combines the assembling and machining steps.

```hs
-- Turn any `Program label` to a ready-to-run `Machine label`
toMachine :: (Ord label) => Program label -> Machine label
toMachine program = Machine (assemble program) (State (Right 0) Data.Map.empty)
```

That's all of our core data types, and their constructors, done.

### Adapting Our Code: The Counter

Now that we've changed our types, we'll need to go through the code we wrote
previously for `interpret`ing expressions, and adapt it accordingly.

First, let's adapt our `counter` functions. Since they all derive from
`updateCounter`, let's adapt that first, and the other two functions
(`setCounter` and `stepCounter`) will follow.

```hs
-- The original `updateCounter` function:
updateCounter :: (Label -> Label) -> State label -> State label
updateCounter f state@(State {..}) = state { counter = f counter }
```

Since our new counter has only changed type, `updateCounter` actually only
needs a new type signature! The code itself can remain unchanged.

```hs
updateCounter :: (Either label Position -> Either label Position) -> State label -> State label
updateCounter f state@(State {..}) = state { counter = f counter }
```

The `set` and `step` functions continue from this easily:

```hs
setCounter :: Either label Position -> State label -> State label
setCounter pos = updateCounter (const pos)

stepCounter :: State label -> State label
stepCounter = updateCounter (fmap succ)
```

In `setCounter`, nothing needs to be changed except the type again. In
`stepCounter`, we use `fmap` to only increment `Right` values.

### Adapting Our Code: The Registers

(Not so) surprisingly, in the case of our register functions (`getReg`,
`setReg`, `updateReg`), only the types need a slight change!

```hs
{-# LANGUAGE RecordWildCards #-}
import Data.Maybe (fromMaybe)

-- The original register functions, but with updated types
getReg :: Register -> State label -> Integer
getReg target (State {..})
    = fromMaybe 0 $ Data.Map.lookup target registers

setReg :: Register -> Integer -> State label -> State label
setReg target val state@(State {..})
    = state { registers = Data.Map.insert target val registers }

updateReg :: Register -> (Integer -> Integer) -> State label -> State label
updateReg target f state = setReg target (f $ getReg target state) state
```

### Adapting Our Code: The Interpreter

What about the interpreter? It turns out that this code, too, can be copied
wholesale with no changes and only a new type-signature, and it will run just
fine!

```hs
-- The original `interpret` function
interpret :: Instruction (Either label Position) -> State label -> State label
interpret (Inc register) state = stepCounter $ updateReg register succ state
interpret (Decjz register label) state
    | getReg register state == 0 = setCounter label state
    | otherwise                  = stepCounter $ updateReg register pred state
```

## Running the Machine

Finally, our `run` function needs to be adapted to take the machine
from newly-revamped data type to working system.

As before, our `run` function will use a `currInstruction` function. Let's
adapt that first:

```hs
-- Retrieve the instruction pointed at by the counter, if any
import Data.Array ((!))

currInstruction :: Machine -> Maybe Instruction
currInstruction (Machine {..})
  = case counter state of
      Left  label -> Nothing
      Right pos   -> program ! pos
```

As you can see, we've had to handle the fact that the position might be `Left
label` with a case expression. Otherwise, everything proceeds as usual.

Here's the kicker: that's all that needed to change. Our run function stays
identical to what it was before.

```hs
-- Same as "run :: (Instruction -> State -> State) -> Machine -> Machine"
run :: Interpreter -> Machine -> Machine
run interpret machine@(Machine {..})
    = case currInstruction machine of
        -- If there is no instruction, assume the machine has halted and return it
        Nothing -> machine
        -- If there is an instruction, transform the state using it, and run
        -- the interpreter again on that new machine
        Just instruction -> run interpret
                          $ machine { state = interpret instruction state }
```

## Takeaways on Types

You'll have noticed throughout the course of this post, a huge amount of the
code we had to adapt was mechanical or didn't need adapting at all, but we
still got all of the guarantees that strong typing provides us about the
operations of our register machines.

This is one of the core strengths of starting with types and breaking down
functionality into small units on the instruction of those types: when you want
to extend your system, all you need to do is adapt the types and then adapt the
functions that use them, often in extremely straightforward and mechanical
ways.

This approach is not exclusive to Haskell nor is it exclusive to FP - it
applies to any programming language or paradigm you may choose to use with a
modicum of typing.

## What's Next?

In Part 1, we covered the basics of building a Register Machine simulator in
Haskell. This time, we added the nice-to-have that is labels, while
demonstrating the guarantees and simple refactoring that typing gives us. Here
is what remains from the list of TODOs we covered at the end of Part 1:

- Parser to read in RM pseudo-source-code like in section 1 and run it.
- "Macros", so we can write and insert subprograms.
- Ability to add & interpret more instructions dynamically.
- Non-deterministic & probabilistic machines.

These and more will be covered in future blog posts! Or, if you can't wait, you
can look at the [final implementation at my
repository.](https://github.com/dylan-thinnes/register-machine)
    '';
}
