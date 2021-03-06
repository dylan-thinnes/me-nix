{
    title = "Register Machines, Part 3 - Custom Instructions";
    author = "Dylan Thinnes";
    description = "In this post, we will go over how to allow our machine's instructions to be extended by anyone, without knowledge of other instruction extensions.";
    time = "1587483454";
    content = ''
# Defining Custom Instructions

> ***This is the third post in a series on implementing register machines in Haskell. If you haven't read parts 1 or 2, I'd recommend you go back to read them:***
<center>
[<%= ./get/article/title.sh ./src/articles/register-machines-in-haskell.article =%>](/blog/register-machines-in-haskell)
</center>
<center>
[<%= ./get/article/title.sh ./src/articles/register-machines-in-haskell-labels.article =%>](/blog/register-machines-in-haskell-labels)
</center>

Our new objective for today is to open up our machines and add a key piece of
functionality: the ability to add new instructions to our instruction set,
without needing to know any of the other instructions. 

## Why Do We Need This?

You may ask: Why is this a whole blog post? Can't we just take our
`Instruction` data structure and add a new constructor and update our
`Interpreter` to define it?

For example, if we wanted to add a `Move` instruction, that copies one register
to another, surely we could update our code like this:

```hs
{-# LANGUAGE DeriveFunctor #-}

data Instruction label
    = Inc ...                -- Keep Inc constructor unchanged
    | Decjz ...              -- Keep Decjz constructor unchanged
    | Move Register Register -- Add new Move constructor
    deriving (Show, Eq, Functor)

interpret :: Instruction (Either label Position) -> State label -> State label
interpret (Inc ...) state = ...   -- Keep Inc interpreter unchanged
interpret (Decjz ...) state = ... -- Keep Decjz interpreter unchanged
interpret (Move from to) state    -- Add Move interpreter
    = setReg to (getReg register state) state
```

Yes, this is very straightforward, but as with many straightforward solutions,
it obscures and ignores a good number of details and thorny issues:

1. **All or nothing**

    Our data constructor provides all the constructors, or none of them. You
    can't, for example, design a machine that only uses a subset of the
    constructors and doesn't bother with the rest.

    Seeing as technically DECJZ and INC are all one needs to be turing
    complete, forcibly bundling in nice-to-haves like MOVE and JUMP limits the
    usability of our machine as a means for experimentation.

2. **Extensible for me, but not for thee**

    This mode of extension works fine for us, the library authors, who can edit
    the source as we please. However, users of our library can't add their own
    instructions or have any of their own ideas about instruction sets.

    Our code is thus unusable as a package. The only way one can experiment
    with our code is to edit it directly, which is not only error-prone but
    also allows the "users" of our code to change everything, not just our
    instruction set.

3. **One module to rule them all**

    Finally, even for us, the library authors, there are some limits, namely
    that we have to define all of the constructors at one site in one module.
    We can't develop our instructions and iterate them separately in separate
    modules, we have to write a single monolith module, wholly responsible for
    all construction and interpretation.

## The Expression Problem

Turns out that this is a well-articulated problem/solution pair that goes by
the name "The Expression Problem", [named thus by Philip Wadler in
1998](http://homepages.inf.ed.ac.uk/wadler/papers/expression/expression.txt).

> The expression problem is a new name for an old problem. The goal is to define a datatype by cases, where one can add new cases to the datatype and new functions over the datatype, without recompiling existing code, and while retaining static type safety (e.g., no casts).

Today we'll be solving this problem using methods expounded in the paper /
functional pearl ["Data Types a la Carte" by Swierstra](https://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.101.4131).
This paper is one of the easier reads out there as PLT papers go, so I would
encourage you to read it if you feel reasonably confident in Haskell. Or don't,
and read on for a practical demonstration anyways.

# Harnessing the Power of the Sum

This is all a result of all our constructors being pooled together. [Wouldn't
it be nice if we could](https://www.youtube.com/watch?v=nZBKFoeDKJo) just
define each constructor as its own datatype and only unify them later in the
`Interpreter` and `Machine` as we needed them?

Turns out there's a way to do this: `Sum`. Briefly, let's explore what a `Sum`
is to our system.

## First Intuition

Let's begin with a basic pair of instructions, with no freeform labels, like we
had in the first post:

```hs
data OldInstruction = Decjz Register Position | Inc Register
```

Notice the bar which I've pointed to in the code. This bar can actually be
considered as syntactic sugar which eventually would convert into this:

```hs
data Decjz = Decjz Register Position
data Inc = Inc Register
type Instruction = Either Decjz Inc
```

As you can see, our new definition of `Instruction` is isomorphic to the old
one - both definitions can easily be converted from one to the other. However,
where one defines a new data type with two constructors, the new one defines
two data types and type synonym to Either to unify them.

Not only that, but by factoring out our two instruction to two independent data
types with one constructor each, we've managed to technically split our
instruction set into two instruction sets, each containing only a single
instruction.

### More than 3 Constructors

We can go further and factor out datatypes containing more than two
constructors by recursively wrapping things in `Either`. Let's convert our MOVE
instruction set from the beginning of this post (ignoring labels again):

```hs
-- Old instructions, no label
data OldInstruction = Decjz Position Register | Inc Register | Move Register Register

-- New instructions, without Move
data Decjz = Decjz Position Register
data Inc = Inc Register
type Instruction = Either Decjz Inc

-- New instructions, with Move
data Move = Move Register Register
type InstructionPrime = Either Instruction Move
```

Notice how we reused the previous factoring work we did for `Decjz` and `Inc`
into `Instruction` to construct a new type `InstructionPrime`. This reuse means
that we can combine both individual instructions and existing groups of
instructions with impunity.

### Insert labels

We can also insert labels back into our instructions, provided we paramaterize
our type synonym.

```hs
{-# LANGUAGE DeriveFunctor #-}
data OldInstruction label = Inc Register | Decjz Register label
    deriving (Show, Eq, Functor)

data Inc label   = Inc Register
    deriving (Show, Eq, Functor)
data Decjz label = Decjz Register label
    deriving (Show, Eq, Functor)
type Instruction label = Either (Inc label) (Decjz label)
```

However, there is a problem with using `Either` here: the `Functor` instance
that was declared on `OldInstruction` in the code snippet does not exist on
`Instruction label`. We will cover how to get that back in a moment.

### Just like an Either

Thus, our first intuition for a `Sum` is that it is identical to an `Either` -
it allows us to take the unions that we normally express with bar (`|`) in our data
declarations and explicitly implement them, splitting our datatypes in the
process.

## Bringing it back to Functors

As mentioned a bit further up, `Either` has the unfortunate side-effect of not
preserving the `Functor` instances for the constructors it unifies.

Fortunately, we can create a new datatype, which we will call `Sum`, which
properly unifies two `Functor`s into one:

```hs
data Sum f g a = L (f a) | R (g a)
    deriving (Show, Eq, Ord)

instance (Functor l, Functor r) => Functor (Sum l r) where
    fmap f (L la) = L (fmap f la)
    fmap f (R ra) = R (fmap f ra)
```

I could have derived that functor instance automatically using `DeriveFunctor`,
but I wrote it by hand so that you could inspect the `Sum` type's functoriality
for yourself. Do not worry too much if the signature is a lot to swallow (and
if it's obvious to you, well done!). We will proceed to use this by hand, so
you get a feel for it.

# Summing our Instructions

Now that we are armed with our new `Sum` type, let's convert our existing,
latest instruction set, with labels and all.

```hs
{-# LANGUAGE DeriveFunctor #-}
data OldInstruction label = Inc Register | Decjz Register label
    deriving (Show, Eq, Functor)

data Decjz label = Decjz Register label
    deriving (Functor)
data Inc label = Inc Register
    deriving (Functor)
type Instruction = Sum Decjz Inc
```

See how our new version of `Sum Inc Decjz`, unlike `Either Inc Decjz`, will
have a `Functor` instance that is identical to that of `OldInstruction`.

We can even add our new `Move` instruction easily, simply by defining it.

```hs
data Move label = Move Register Register
    deriving (Functor)
type InstructionPrime = Sum (Sum Decjz Inc) Move
--   InstructionPrime = Sum Instruction     Move
```

We have now disassembled our `Instruction` data type into singular pieces and
glued them back together using `Sum`. This another common tenet of FP
languages: Breaking down a normally rigid data structure into a few independent
pieces and higher-level "combinators", like `Sum`. This makes the behaviour of
our data structures easy to dissect and reason about.

# Adapting the Interpreter

Alright, we have built a new `Instruction` using our `Sum` that is identical to
our original, rigid type. Let's quickly adapt our `interpret` function to
handle this new datatype, just to prove that our `Instruction` hasn't changed.

```hs
interpret :: Instruction (Either label Position) -> State label -> State label
interpret (R (Inc register)) state = stepCounter $ updateReg register succ state
interpret (L (Decjz register label)) state
    | getReg register state == 0 = setCounter label state
    | otherwise                  = stepCounter $ updateReg register pred state
```

Isn't that something! The only changes, if you can even see them, from our
previous code, was pattern matching on the `L` and the `R` constructors that
contain the `Decjz` and `Inc` constructors / types respectively.

## Generalizing Interpret

There is an obvious problem with our implementation of `interpret`: it's just as
rigid as the our last implementation. Alas, we have created the ability to add
new instructions freely to our instruction sets, but our interpreter still
expects a rigid signature of exactly the same instructions every time.

We need to not only split our constructors for our data types, we now need to
split our interpreters or "destructors" too.

We can begin by creating a typeclass, `IsInstruction`, which marks a given
data type as an instruction. We'll make `interpretInstr` a function belonging
to this typeclass, so any `IsInstruction` can be interpreted.

```hs
class IsInstruction instr where
    interpretInstr :: instr (Either label Position) -> State label -> State label
```

Implementing the `IsInstruction` typeclass for both `Decjz` and `Inc` is as
simple as copying the code that we've already written for our previous
implementation of `interpret`. However, since the typeclass gets defined on one
instruction data type, we define these `interpretInstr` functions separately.

```hs
-- Previous, rigid implementation of interpret:
interpret :: IsInstruction (Either label Position) -> State label -> State label
interpret (R (Inc register)) state = stepCounter $ updateReg register succ state
interpret (L (Decjz register label)) state
    | getReg register state == 0 = setCounter label state
    | otherwise                  = stepCounter $ updateReg register pred state

instance IsInstruction Inc where
    -- Copy over code from first pattern match in `interpret` to here
    interpretInstr (Inc register) state = stepCounter $ updateReg register succ state

instance IsInstruction Decjz where
    -- Copy over code from second pattern match in `interpret` to here
    interpretInstr (Decjz register label) state
        | getReg register state == 0 = setCounter label state
        | otherwise                  = stepCounter $ updateReg register pred state
```

## What's Left?

Great, but now we need to be able to combine these `interpretInstr` functions
for any `Sum` of instructions we may create. That's really easy with
typeclasses! Take a look:

```hs
instance (IsInstruction f, IsInstruction g) => IsInstruction (Sum f g) where
    interpretInstr (L f) state = interpretInstr f state
    interpretInstr (R g) state = interpretInstr g state
```

This instance fully describes how to interpret an instruction set that is
composed of two further instruction sets. It is easier to read if you break it
down bit by bit: 

- The first line of code says the following:
 
  If a functor `f` is an `IsInstruction`, and a functor `g` is an `IsInstruction`,
  then their sum, expressed `Sum f g`, is also an `IsInstruction`.

- The second line of code says:

  If you attempt to interpret a instruction of type `Sum l r`, and you find a
  left instance `L`, you can assume that it contains a value of type `f (Either
  label Position)`, and since we know `f` is an `IsInstruction` by line 1, we
  can interpret it using the `interpretInstr` function defined for `f`.

- The third line of code says:

  Similarly, if you attempt to interpret a instruction of type `Sum l r`, and
  you find a right instance `R`, you can assume that it contains a value of
  type `g (Either label Position)`, and since we know that `g` too is an
  `IsInstruction` by line 1, we can interpret it using the `interpretInstr`
  function defined for `g`.

In a way, the instance for `Sum f g` is about as plain-English as code can get.

## Finally...

Finally, we can redefine our `interpret` function as `interpretInstr`, or the
other way around, depending on our preference:

```hs
interpret :: IsInstruction instr => instr (Either label Position) 
                                 -> State label -> State label
interpret = interpretInstr
```

There we have it: the free ability to mix and match instructions, across
modules and compilations, inside and outside the package, and a free
interpreter to go along with it!

### Parameterize labels to Assembly, Machines, and "run"

> Note: This parameterize subsection was added later on the suggestion of a
> friend.

Of course, with the ability to mix and match instructions, we need to be able
to put them inside our `Program`, `Machine`, `Assembly`, `assembled`, and
`run`. As of the redefinition of `interpret` all of those function will be
broken. Luckily, by working with types this process is quite mechanical and
easy!

Our old definitions of `Program`, `Machine`, and `Assembly` encoded
`Instruction` statically like this:

```hs
type Program instr label = [(Maybe label, Instruction label)]
type Assembled label = Array Position (Instruction (Either label Position))
data Machine label = Machine
    { assembled :: Assembled label
    , state :: State label
    }
```

You can see that `Program` and `Assembled` are where `Instruction` is placed,
so to allow free-form `Instruction`s, we need to add a new argument `instr` to
all three types to replace `Instruction`.

```hs
-- Add instr parameter, replace Instruction
type Program instr label = [(Maybe label, instr label)]
-- Add instr parameter, replace Instruction
type Assembled instr label = Array Position (instr (Either label Position))
-- Add instr parameter, pass to Assembled
data Machine instr label = Machine
    { assembled :: Assembled instr label
    , state :: State label
    }
```

Adapting `assemble`, `toMachine`, and `run` now only require a few type
signatures to change. We'll start with `assemble`.

First, here is the old code for `assemble` in full:

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

And what follows is a brief of the only changes that need to be made to update `assemble`:

```hs
-- old sig: forall label.       (Ord label)                => Program       label -> Assembled       label
assemble :: forall label instr. (Functor instr, Ord label) => Program instr label -> Assembled instr label
assemble program = assembled
    where
    ...
    -- old sig :: [Instruction (Either label Position)]
    instrs     :: [instr       (Either label Position)]
    ...
```

As you can see, only a few type signatures were changed - no code actually had
to change. Similarly, `toMachine` only needs a change in type signature:

```hs
-- Old version
toMachine :: (Ord label) => Program label -> Machine label
toMachine program = Machine (assemble program) (State (Right 0) Data.Map.empty)
```

```
-- New version
toMachine :: (Functor instr, Ord label) => Program instr label -> Machine instr label
toMachine program = Machine (assemble program) (State (Right 0) Data.Map.empty)
```

Changes for `run` also involve the removal of the `interpret` parameter, since
we now get `interpret` from the `IsInstruction` constraint. Otherwise, only
types change. Here is the old version:

```hs
run :: Interpreter label -> Machine label -> Machine label
run interpret machine@(Machine {..})
    = case currInstruction machine of
        -- If there is no instruction, assume the machine has halted and return it
        Nothing -> machine
        -- If there is an instruction, transform the state using it, and run
        -- the interpreter again on that new machine
        Just instruction -> run interpret
                          $ machine { state = interpret instruction state }
```

And here is the new version:

```hs
run :: IsInstruction instr => Machine instr label -> Machine instr label
run machine@(Machine {..}) -- Remove "interpret" parameter
    = case currInstruction machine of
        -- If there is no instruction, assume the machine has halted and return it
        Nothing -> machine
        -- If there is an instruction, transform the state using it, and run
        -- the interpreter again on that new machine
        Just instruction -> run -- Remove passing in of "interpret" parameter
                          $ machine { state = interpret instruction state }
```

# A Minor Caveat

The caveat is this: when constructing our programs by hand, we now need to
explicitly wrap our constructors in `L` and in `R`, like so:

```hs
myProgram :: Program String
myProgram =
    [ (Nothing,     R (Inc (Register 0)))
    , (Just "loop", L (Decjz (Register 0) "halt"))
    , (Nothing    , R (Inc (Register 1)))
    , (Nothing    , R (Inc (Register 2)))
    , (Nothing    , R (Inc (Register 3)))
    , (Nothing    , L (Decjz (Register 4) "loop"))
    , (Just "exit", R (Inc (Register 4)))
    ]
```

That may not seem like such a big issue now, but it becomes worse: as you add
more instructions to your instruction set, you need to add more and more nested
`L` and `R` constructors.

This obviously isn't ideal, and Swierstra's paper, ["Data Types a la
Carte"](https://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.101.4131),
which I mentioned at the beginning of this blog post, explains how the clever
use of typeclasses can give you an "injector" function `inj` which
automatically adds the correct `L` and `R` constructors. The particularly
motivated should feel free to read the paper and understand how to implement
such a function, but such an explanation would make this blog post far too
long.

# What's Next?

In Part 1, we covered the basics of building a Register Machine simulator in
Haskell. In Part 2, we added the nice-to-have that is labels, while
demonstrating the guarantees and simple refactoring that typing gives us. Now,
we implemented arguably the most powerful feature so far, custom instructions
that can transcend module and compilation boundaries, while still being
type-safe.

Here is what remains from the list of TODOs we covered at the end of Part 1:

- Parser to read in RM pseudo-source-code like in section 1 and run it.
- "Macros", so we can write and insert subprograms.
- Non-deterministic & probabilistic machines.

These and more will be covered in future blog posts! Or, if you can't wait, you
can look at the [final implementation at my
repository.](https://github.com/dylan-thinnes/register-machine)
    '';
}
