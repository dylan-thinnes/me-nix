{
    title = "Register Machines, Part 1 - The Fundamentals";
    author = "Dylan Thinnes";
    description = "In this post, we go over the concept of register machines, and how some of Haskell's strengths can be used to implement them.";
    time = "1581520266";
    content = ''
# What are Register Machines?

Register machines, at their most basic level, are fairly easy to understand and explain.

Imagine a machine with an infinite number of "registers", $\text{r}0$,
$\text{r}1$, etcetera, which each contains a natural number (any integer $0, 1,
\dots$). Every register starts out containing $0$.

This machine also has a finite list of instructions, $I$, which it executes in
sequence. The machine keeps track of which instruction it's currently on using
a "counter" which indexes into $I$.

When the program counter moves past to a natural number for which no
instruction is defined, we stop running the machine and say it has "halted",
meaning there is no further work to be done.

Each instruction can be one of two types: **INC** and **DECJZ**.  Let's cover
what they do when executed:

## INC

**INC** is very simple: it is supplied a number "n" and increments the value in
register $\text{r}n$ by 1.

For example, the instruction `INC 0` would increment the value in register
$\text{r}0$ by 1.

## DECJZ

**DECJZ** is the "kitchen sink" instruction that gives us most of our power. It
takes two natural numbers, "n" and "destination".

If register $\text{r}n = 0$, the instruction jumps the machine's counter to the
position denoted by "destination".

If register $\text{r}n > 0$, the instruction decrements register $\text{r}n$ by 1
and doesn't jump.

For example, the instruction `DECJZ 0 5` checks register $\text{r}0$. If the
register contains 0, the machine jumps to the 5th instruction. Otherwise, it
subtracts 1 from $\text{r}0$ and proceeds to the next instruction.

## An Example Program

Let's go through an example program. I've marked the current instruction with a
`*`, and I report the numbers in registers $\text{r}0$ - $\text{r}4$ in a row
at the top.

```
registers 0 0 0 0 0
*1: inc 0
 2: decjz 0 7
 3: inc 1
 4: inc 2
 5: inc 3
 6: decjz 3 2
 7: inc 4
```

The machine starts, as is only natural, at the beginning, with `inc 0`. This
increments the number in $\text{r}0$ by 1. Then it steps forward to the next
instruction. The machine state thus becomes:

```
registers 1 0 0 0 0
 1: inc 0
*2: decjz 0 7
 3: inc 1
 4: inc 2
 5: inc 3
 6: decjz 3 2
 7: inc 4
```

Now, the second instruction checks if $\text{r}0$ is 0. Since it isn't, we
decrement $\text{r}0$ and progress to the next instruction:

```
registers 0 0 0 0 0
 1: inc 0
 2: decjz 0 7
*3: inc 1
 4: inc 2
 5: inc 3
 6: decjz 3 2
 7: inc 4
```

We'll cover the next three instructions (3-5) together: since each is an `inc`
instruction, operating on $\text{r}1$, $\text{r}2$, $\text{r}3$ respectively,
we increment each of those in sequence and end up finally at instruction 6.

```
registers 0 1 1 1 0
 1: inc 0
 2: decjz 0 7
 3: inc 1
 4: inc 2
 5: inc 3
*6: decjz 4 2
 7: inc 4
```

Now, `decjz 3 2` checks if $\text{r}4$ contains 0. Since it *does*, the machine
jumps back to instruction 2.

```
registers 0 1 1 1 0
 1: inc 0
*2: decjz 0 7
 3: inc 1
 4: inc 2
 5: inc 3
 6: decjz 4 2
 7: inc 4
```

Similarly, `decjz 0 7` checks if $\text{r}0$ contains 0. Since it *does*, the
machine jumps forwards to instruction 7.

```
registers 0 1 1 1 0
 1: inc 0
 2: decjz 0 7
 3: inc 1
 4: inc 2
 5: inc 3
 6: decjz 4 2
*7: inc 4
```

Finally, we execute the last increment, `inc 4`, and finish with the following
program:

```
registers 0 1 1 1 1
 1: inc 0
 2: decjz 0 7
 3: inc 1
 4: inc 2
 5: inc 3
 6: decjz 4 2
 7: inc 4
```

Note that the program will "loop" around from 2 to 6 and back again as long as
there is a positive value in $\text{r}0$. Every time it does this, it subtracts
1 from $\text{r}0$, so we can expect the number of "loops" to be equal to the
value initially in $\text{r}0$. Each time we "loop", we increment $\text{r}1$
and $\text{r}2$ and $\text{r}3$. Once we are done looping, the program finishes
by incrementing $\text{r}4$.

This means that using the simple construct above, we have formed a for loop!
It would be trivial to convert it to a while loop, simply by incrementing
$\text{r}0$ by 1 within the body of the loop, ensuring that $\text{r}0$ never
is 0 when the `decjz 0 7` instruction gets executed.

# Implementation in Haskell

So, now that you've been given an adequate versing in the fundamentals of
register machines, let's move on to writing an interpreter for it! All of the
final code for this post is in [my register-machine
repo](https://github.com/dylan-thinnes/register-machine).

## The Trivial

We will start with a trivial example and continue to expand the capabilities of
our simulator in future blog posts "step by step" to demonstrate individual
language features best.

I will try to use fairly simple Haskell with a minimal amount of clever
currying, but here and there I will use a syntactical language extension, such
as `RecordWildCards`. Feel free to take breaks to look them up
[here](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/glasgow_exts.html)
whenever you encounter one you don't know -- they are usually not complicated
and will make understanding this post easier.

### Start with the Types

As in all good Haskell programs, we start with our (data)types. We will need:

- The type for instructions.
- The type for the full machine program, with numbers associated to
  instructions.
- The type for the machine state, with a program counter and registers.
- The type for the full machine, uniting state with program.
- The type for a "interpreter" function which steps the machine state forward,
  given an instruction.

These we can code up quickly:

```hs
import Data.Map

-- A data type for instructions - either the increment with its register or the
-- decjz with its register and label.
data Instruction = Inc Integer | Decjz Integer Integer

-- A program is just a list of instructions
type Program = [Instruction]

-- A counter is just a Integer
-- Registers are just a Map of Integer keys to Integer values
data State = State { counter :: Integer, registers :: Map Integer Integer }

-- Uniting state and program under a machine is trivial...
data Machine = Machine { program :: Program, state :: State }

-- An interpreter function taking an instruction and state to a new state
type Interpreter = Instruction -> State -> State
```

> *Note:* You may ask why we separate `State` and `Program` at all, or why we
> don't have the `Interpreter` function take a full `Machine` to another `Machine`.
> The answer is that by splitting the two, we ensure that the `Interpreter`
> function for an instruction can only mutate what it ought to be allowed to
> mutate in the `Machine` - the program written should never change during
> execution of an instruction, so we hide its existence by making the `Interpreter`
> only take a machine state and a single instruction to interpret.

For a little added type safety, we will differentiate `Integer`s representing
labels and those representing registers, using newtypes. This requires us to
trivially adapt `Instruction` and `State`.

```hs
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
newtype Label = Label Integer
    deriving (Show, Eq, Ord, Enum, Num)
newtype Register = Register Integer
    deriving (Show, Eq, Ord, Enum, Num)

data Instruction = Inc Register | Decjz Register Label
data State = State { counter :: Label, registers :: Map Register Integer }
```

In the interest of speed, we can also adapt our `Program` to a `Map` or an
`Array`. I will go with `Map` for now since it makes some example code snippets
simpler, but there is little other reason to not choose `Array`.

```hs
type Program = Map Label Instruction
```

### The Interpreter

Great! Now, let's implement the classical interpreter, which takes an `Instruction`
and progresses the `State` accordingly. 

In keeping with good programming practice, we break the problem down to
digestible chunks. We'll start with a couple of helper functions which help us
set and retrieve Registers in a machine state.

```hs
{-# LANGUAGE RecordWildCards #-}
import Data.Maybe (fromMaybe)

getReg :: Register -> State -> Integer
getReg target (State {..})
    = fromMaybe 0 $ Data.Map.lookup target registers

setReg :: Register -> Integer -> State -> State
setReg target val state@(State {..})
    = state { registers = insert target val registers }

updateReg :: Register -> (Integer -> Integer) -> State -> State
updateReg target f state = setReg target (f $ getReg target state) state
```

> *Note:* In the actual implementation provided, I use lenses, which are a
> nifty concept you can find out about
> [here](https://github.com/ekmett/lens/wiki/Overview). They eliminate the need
> to write separate get, set, and update functions. They can also do far more
> if you put in the hard time to learn them.

We'll also write two helpers for the program counter: One for setting it (as
we'd do with **DECJZ**), and one for stepping it forward by 1 (as we'd do with
**INC**). We implement both of these using an update function under the hood.

```hs
updateCounter :: (Label -> Label) -> State -> State
updateCounter f state@(State {..}) = state { counter = f counter }

setCounter :: Label -> State -> State
setCounter i = updateCounter (const i)

stepCounter :: State -> State
stepCounter = updateCounter succ
```

Now that we've set up our helper functions, implementing the interpreter is not
nearly as daunting a task. We implement it for each of the two instructions
individually using pattern matching. Let's begin with implementing **INC**:

```hs
interpret :: Interpreter -- same as ":: Instruction -> State -> State"
interpret (Inc register) state = stepCounter $ updateReg register succ state
```

Wow, that's pretty simple! All we did was call `updateReg` to increment the
register, and then call `stepCounter` on the resulting state to increment the
counter. Of course, **INC** is a simple instruction -- let's try the much more
complex **DECJZ**.

```hs
interpret (Decjz register label) state
    | getReg register state == 0 = setCounter label state
    | otherwise                  = stepCounter $ updateReg register pred state
```

That too, was not so complicated! If the register was 0, we set the counter to
the new label. Otherwise, we decrement the register and step the counter again.

### Tying up the Interpreter

So, in not so many complicated lines, of which most were boilerplate helpers,
we've implemented the register machine's core functionality!

However, we are not done yet, we still need to turn the `Interpreter` into a
`run` function that can step the machine state in one go until it halts. We
make this a higher-order function, so that the `interpreter` is not aware of any
of the specifics of the full machine, and in turn the `run` function is not
aware of any of the specifics of the instructions it is running.

We start with a little helper which retrieves the instruction in a Machine
currently pointed to by the counter (if any).

```hs
-- Retrieve the instruction pointed at by the counter, if any
currInstruction :: Machine -> Maybe Instruction
currInstruction (Machine {..}) = program !? counter state
```

Now, we finally write the `run` function, which
1. takes an interpreter and a machine
2. continuously steps the machine until the counter ends up in a position where
   there are no instructions, indicating the machine has halted
3. returns that last machine with the invalid counter

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

> *Note:* We can break this down further, by having a `run` function that only
> takes a single step of type `Machine -> Maybe Machine`, and using an "unfold"
> function to create the infinite list of machine states. This gives us much
> finer control over our iteration and hides fewer details while exposing some
> that we may want, and is how I would normally do it.

There we go, we've made it, the `run`ner to our `interpret`er!

Isn't that pretty cool?

## Extending our Machines

We've created an appropriate simulator for the most basic register machines,
but what next? Let's write down a few nice to haves to think about them:

- Ability to write textual labels so we don't need to count line numbers before
  writing a jump.
- Parser to read in RM pseudo-source-code like in section 1 and run it.
- "Macros", so we can write and insert subprograms.
- Ability to add & interpret more instructions dynamically.
- Non-deterministic & probabilistic machines.

These and more will be covered in future blog posts! Or, if you can't wait, you
can look at the [final implementation at my
repository.](https://github.com/dylan-thinnes/register-machine)
    '';
}
