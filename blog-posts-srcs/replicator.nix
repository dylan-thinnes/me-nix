{
    title = "Fun with Bash: The Tee Replicator";
    author = "Dylan Thinnes";
    description = "A small post on using tee to duplicate input lines an arbitrary number of times.";
    time = "1573855409";
    content = ''
Anyone who's met me will know I delight in taking small tools or concepts with
odd corner cases and exploiting them to do things that they are otherwise
unsuited for. Today, we'll be going over a simple task and covering a fun way
to implement it using nothing but one common unix shell command, `tee`, and
Bash to glue it together.

### The Task

Let us suppose the following basic task: design a program that takes the
standard input and copies it $k$ times to standard output. The $k$ is passed as
an argument.

```bash
$ echo "a" | my-program 5
a
a
a
a
a
```

There are many ways to implement such a program, with varying levels of
performance. For example, Bash for loops are extremely simple but similarly
slow. GNU yes does the trick, and is quick about it.  We'll be using `tee`,
which sits somewhere in the middle on performance.

### Intro to Tee

`tee` is a very simple program. It takes its standard input and prints it to
standard output and also writes it of the files named in its arguments.

For example:

```bash
$ echo a | tee ./my-file
```

would both print "a" to standard output and write "a" into "./my-file".

### The Fun Part

In keeping with the Unix philosophy, since tee simply writes to files you tell
it to, it can also write to files that aren't actually files, such as...
`/dev/stdout`.

Thus, the program `tee /dev/stdout` will copy its standard input to both
standard output and, again, standard output.

```bash
$ echo a | tee /dev/stdout
a
a
```

Furthermore, if you specify /dev/stdout several times, it will copy that
several times again.

```bash
$ # /dev/stdout specified twice
$ echo a | tee /dev/stdout /dev/stdout  
a  # The original output
a  # The first copy
a  # The second copy
```

### Arbitrary Powers of Two

Quite obviously, pipe `tee` into itself $j$ times and you get $2^{j+1}$
duplication.

```bash
$ # Pipe it into itself twice, j = 2 -> 2^(j+1) = 8
$ echo a | tee /dev/stdout | tee /dev/stdout | tee /dev/stdout
a
a
a
a
a
a
a
a
```

This gives us arbitrary duplication to $2^j$ times with $j$ processes, which
will serve useful in a moment.

### Standard Error Deserves Recognition Too

`tee` can also pipe to `/dev/stderr`, which allows us to write the output of a
command to both `/dev/stdout` and `/dev/stderr`.

From then on, stderr will, as it always does, "pass through" any future tee
program.

By copying program output to stderr and stdout, we can operate on the stdout
stream independently of what was originally copied, transforming it, and then
merge it back with its original self using the bash redirect `2>&1`.

In essence, the following two commands are equivalent:

```bash
(tee /dev/stderr | my_command) 2>&1
```

```bash
A=$(cat)
echo $A
echo $A | my_command
```

Of course, the former solution is what we'll be using today for its 

1. Wanton abuse of tools never meant for the purpose.
2. Lack of cattiness.

### Tying All Our Components Together

Those of you who've fiddled with bits before will likely anticipate the
solution now.

First, we take our $k$ and decompose it into its binary representation:

```
n    binary
4  = 00100
10 = 01010
12 = 01100
29 = 11101
```

Then, we take our initial input, which can be considered as a single ($1$)
occurence. We double our input, creating $2_{10}=10_2$, then $4_{10}=100_2$, then $8_{10}=1000_2$
etc. successively, until we reach a digit present in the original number.

So, if we have $k=12_{10}=01100_2$, we double twice, until reaching $100$

```
objective: 12 = 01100
        start    double   double
stdout: 00001 => 00010 => 00100
stderr: 00000 => 00000 => 00000
```

Where lines "stdout" and "stderr" above denote how many copies of the original
input are in stdout and stderr at any given time.

Then, we copy the current duplicates to stderr, "saving" it.

```
objective: 12 = 01100
        start    double   double   copy
stdout: 00001 => 00010 => 00100 => 00100
stderr: 00000 => 00000 => 00000 => 00100
```

Then, we continue to double again until reaching the next digit, then copying
again, and repeat this process until there are no digits remaining.

```
objective: 12 = 01100
        start    double   double   copy     double   copy
stdout: 00001 => 00010 => 00100 => 00100 => 01000 => 01000
stderr: 00000 => 00000 => 00000 => 00100 => 00100 => 01100
```

Finally, we clear stdout (using `> /dev/null`) and then swap stderr
to stdout (using `2&>1`).

```
objective: 12 = 01100
               copy     double   copy     clear    swap
stdout: ... => 00100 => 01000 => 01000 => 00000 => 01100
stderr: ... => 00100 => 00100 => 01100 => 01100 => 00000
```

If we take this sequence of steps and systematically turn them into a shell
script, we get a little something like this:

```bash
dupe () {
    local N=$1
    # Avoid any processing if N is below 1.
    if [[ $N > 0 ]]; then
        if [[ $N == 1 ]]; then
            # If the current bit is the last bit, copy to
            # stderr and stop duplicating
            tee /dev/stderr
        elif [[ $((N % 2)) == 1 ]]; then
            # If current bit is one, copy to stderr, set
            # current bit to zero, and continue duplicating
            tee /dev/stderr | dupe $((N-1))
        else
            # If current bit is zero, duplicate input once,
            # shift N to next bit, and continue duplicating
            tee /dev/stdout | dupe $((N/2))
        fi
    fi
}

# Throw away stdout & redirect stderr to stdout
dupe $1 2>&1 >/dev/null
```

A not-so-small aside: the behaviour expressed in the first clause of the
innermost if statement, `[[ $N == 1 ]]`, can be removed and expressed in an
else branch on the outermost if statement.

```bash
dupe () {
    local N=$1
    if [[ $N > 0 ]]; then
        if [[ $((N % 2)) == 1 ]]; then
            # If current bit is one, copy to stderr, set
            # current bit to zero, and continue duplicating
            tee /dev/stderr | dupe $((N-1))
        else
            # If current bit is zero, duplicate input once,
            # shift N to next bit, and continue duplicating
            tee /dev/stdout | dupe $((N/2))
        fi
    else
        tee
    fi
}

# Redirect stderr to stdout & redirect stderr to stdout.
dupe $1 2>&1 >/dev/null
```

Furthermore, with the final step of the recursion (either with the innermost if
statement of the former implementation, or the outermost else branch of the
latter implementation), clearing stdout can be moved inside the final call.

```bash
dupe () {
    local N=$1
    if [[ $N > 0 ]]; then
        if [[ $((N % 2)) == 1 ]]; then
            # If current bit is one, copy to stderr, set
            # current bit to zero, and continue duplicating
            tee /dev/stderr | dupe $((N-1))
        else
            # If current bit is zero, duplicate input once,
            # shift N to next bit, and continue duplicating
            tee /dev/stdout | dupe $((N/2))
        fi
    else
        # Throw away stdout
        tee >/dev/null
    fi
}

# Redirect stderr to stdout
dupe $1 2>&1
```

The distinction is largely one of ["neether or
naither"](https://www.youtube.com/watch?v=J2oEmPP5dTM). Which one you use is
largely up to you - it adds one extra call to the recursive function to use the
else branch on the outermost if statement.

Thus, we've reached the end of this mini-post! Congratulations! Using nothing
but tee and built-in bash features, you can now duplicate any possible input
any number of times!
    '';
}
