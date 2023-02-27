```
7045932 - This is an encoding of a tree in binary:

in binary (left is the msb): | 0100 0011 0011 0010 0000 0000 0000
parents:                     |    4    3    3    2    0    0    0
node indices:                |    7    6    5    4    3    2    1

0 doesn't have a parent.

This is how the tree looks like:

   0
 / | \
1  2  3
   |  / \
   4 5   6
   |
   7

1108697968 - This is an encoding of a labeling for the tree in binary:

in binary (left is the msb): | 0100 0010 0001 0101 0110 0011 0111 0000
labels:                      |    4    2    1    5    6    3    7    0
node indices:                |    7    6    5    4    3    2    1    0

This is how the tree looks with labels assigned:

   0
 / | \
7  3  6
   |  / \
   5 1   2
   |
   4
```
