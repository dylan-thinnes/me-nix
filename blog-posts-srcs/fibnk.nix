{
    title = "Fib N-K: A Short Mathematical Exploration";
    author = "Dylan Thinnes";
    description = "A mathematical exploration mini-task to implement in your language of choice!";
    time = "1564849285";
    content = ''
This is an article on a mathematical exploration I did to learn some C &
entertain myself one evening.

I've uploaded some corresponding code to a [Github repository for this math
exploration](https://github.com/dylan-thinnes/fib-nk). In it, I've doodled up a
few examples to the "fib n-k" problem (explained below) in different languages.

Write a solution in your own language, or update mine, and make a pull request!
I'd be happy to take any submissions.

Writing a program which can find all "fib n-k" sequences for a given n & k is a
fairly comfortable exercise for the fundamentals of any programming language.

It covers the basics of taking & parsing user input, applying functions
repeatedly, and (very!) simple data structures.

## What is Fib N-K?

Fib N-K is a group of sequences which can be quite fun to calculate.

The standard fibonacci sequence starts with two numbers (the "seed"), a and b,
which are a = 0 and b = 1.  
Every successive number in the sequence is formed by adding the previous two
numbers.

```
0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144...
```

If you apply a modulo of 10 to every single term after summation, you end up
with a similar but different sequence.

```
0, 1, 1, 2, 3, 5, 8, 3, 1, 4, 5, 9, 4...
```

You can think of this sequence as the result of a function which takes a pair
of values (a,b) and produces a sucessive pair (b,a+b), where a and b can take
on the values 0 to 9.

```
(0, 1) -> f -> (1, 1) -> f -> (1, 2) -> f -> (2, 3) -> f -> (3, 5) -> ...
 0              1              1              2              3
```

Obviously, this sequence eventually must produce the terms 0 and 1 again (it's
an injective function on a finite domain), at which point it will loop back on
itself. 

The full sequence, assuming the first two terms are 0 and 1, is as follows:

```
0, 1, 1, 2, 3, 5, 8, 3, 1, 4, 5, 9, 4, 3, 7, 0, 7, 7, 4, 1, 5, 6, 1, 7, 8, 5, 3, 8, 1, 9, 0, 9, 9, 8, 7, 5, 2, 7, 9, 6, 5, 1, 6, 7, 3, 0, 3, 3, 6, 9, 5, 4, 9, 3, 2, 5, 7, 2, 9, 1 (, 0, 1...)
```

Interestingly, this sequence consists of 60 pairs of numbers, so there are 40
other pairs in the domain that are never explored by it.

If we choose other pairs as seed values, we can discover 5 other sequences
that, combined with the sequence above, partition the domain entirely.

The first case, where the initial values are 0 and 0, is trivial and obviously
loops back on itself instantly.

```
0, 0 (, 0, 0...)
```
```
0, 2, 2, 4, 6, 0, 6, 6, 2, 8, 0, 8, 8, 6, 4, 0, 4, 4, 8, 2 (, 0, 2...)
```
```
5, 0, 5, 5 (, 0, 5...)
```
```
2, 1, 3, 4, 7, 1, 8, 9, 7, 6, 3, 9, 2 (, 1, 3...)
```
```
4, 2, 6, 8, 4 (, 2, 6...)
```

Since these partitions are completely disjoint, the function can be said to
form equivalence classes on pairs in the same sequence.

## Changing K & N
So, the first example added together the previous 2 values, and modulo'd them
by 10.

We call the first term (2) the "k", the total number of previous values to add
together.

The second term (10) is the "n", the modulo to take over each sum.

Varying the n & k make for differently long cycles w/ different patterns.

## Trying K = 3, N = 10

For example, let's take k = 3, and keep n = 10.

There are 3 numbers in each tuple, and each number can take on 10 values (0 to
9), thus there are 10^3 = 1000 tuples in the domain.

Since k = 3, we'll need to choose three seed values for our first sequence.
Let's pick 0 0 1.

```
(0 0 1) -> (0 1 1) -> (1 1 2) -> (1 2 4) -> (2 4 7) -> (4 7 3) -> (7 3 4) -> ...
 0          0          1          1          2          4          7
```

This seed produces a sequence 124 elements long. There are 20 sequences which
partition the state space completely.

## What next?

Different choices of n & k produce very different results, but many of them
seem to follow a pattern.

If you compile the C program in the repo I've linked, it takes values k & n as
arguments and then prints all of the cycles, composed of their elements in
order, like so:

```bash
> ./c 3 4
0 0 0
1 0 0 1 1 2 0 3 1 0
2 0 0 2 2 0
3 0 0 3 3 2 0 1 3 0
0 1 0 1 2 3 2 3 0 1
1 1 0 2 3 1 2 2 1 1
2 1 0 3 0 3 2 1 2 1
0 2 0 2
3 3 0 2 1 3 2 2 3 3
1 1 1 3 1 1
3 3 1 3 3 3
2 2 2
```

Using a few simple bash scripts, we can get the length of each cycle

```bash
> ./c 3 4 | 
> while read line
> do 
>     echo $line | cut -f 3- -d ' ' | wc -w
> done
1
8
4
8
8
8
8
2
8
4
4
1
```

By tacking on two more simple pipes, we can figure out the frequencies of each
length of cycle.

```bash
> # First column is the frequency, second column is the length
> ./c 3 4 | 
> while read line
> do 
>     echo $line | cut -f 3- -d ' ' | wc -w
> done | sort -n | uniq -c
2 1
1 2
3 4
6 8
```

As you can see, all the cycles's lengths fall into certain buckets. This result
is particularly interesting for larger n & k.

```bash
> ./c 4 10 | 
> while read line
> do 
>     echo $line | cut -f 4- -d ' ' | wc -w; 
> done | sort -n | uniq -c
1 1
3 5
2 312
6 1560
```

Finding & explaining a formula for the lengths of all cycle w/ n & k would be a
fun piece of work. Tell me if you do!

Otherwise, a (memory-efficient) way of computing a cycle & finding the next
seed w/o needing to keep the whole domain in memory would be very interesting
too.
    '';
}
