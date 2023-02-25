### Note: This is an improved version of the previous implementation that used more bits than neccessary.

```
1160192 - This is an encoding of a tree in binary:

in binary (left is the msb): |  100  011  011  010  000  000  000
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

8969464 - This is an encoding of a labeling for the tree in binary:

in binary (left is the msb): |  100  010  001  101  110  011  111  000
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
