pragma circom 2.0.0;

include "./node_modules/circomlib/circuits/comparators.circom";

// amount of bits needed to represent n
function bits(n) {
    var result = 1;
    while (n <= 1) {
        n \= 2;
        result++;
    }
    return result;
}

// sum in[N]
// thanks snark-jwt-verify :))
template CalculateTotal(N) {
    signal input in[N];
    signal output out;

    signal outs[N];
    outs[0] <== in[0];

    for (var i=1; i < N; i++) {
        outs[i] <== outs[i - 1] + in[i];
    }

    out <== outs[N - 1];
}

// array[index] when index is a signal
// O(n) because of how circuits work
template AtIndex(N) {
    signal input array[N];
    signal input index;

    signal output out;

    component isIIndex[N];
    component result = CalculateTotal(N);
    for (var i = 0; i < N; i++) {
        isIIndex[i] = IsEqual();
        isIIndex[i].in[0] <== i;
        isIIndex[i].in[1] <== index;

        // accm = accm + isIIndex[i].out * array[i];
        result.in[i] <== isIIndex[i].out * array[i];
    }

    out <== result.out;
}

// out is 1 if in[N] is an array compromised of unique values between 0 and N - 1 (inclusive)
// otherwise, 0
template UniqueSet(N) {
    signal input in[N];
    signal output out;

    // if unique set accm should remain 0
    var accm = 0;

    component boundCheck[N];
    for (var i = 0; i < N; i++) {
        boundCheck[i] = LessThan(bits(N - 1));
        boundCheck[i].in[0] <== in[i];
        boundCheck[i].in[1] <== N;

        // in[i] < N is desirable
        accm += 1 - boundCheck[i].out;
    }

    component isEquals[N][N];
    for (var i = 0; i < N; i++) {
        for (var j = i + 1; j < N; j++) {
            isEquals[i][j] = IsEqual();
            isEquals[i][j].in[0] <== in[i];
            isEquals[i][j].in[1] <== in[j];

            // in[i] != in[j] is desirable
            accm += isEquals[i][j].out;
        }
    }

    component isUniqueSet = IsZero();
    isUniqueSet.in <== accm;
    out <== isUniqueSet.out;
}

// parents is an array such that the i-th element is the parent of node i
// in order to ensure non cyclicity, each vertex must have a parent whose index is lower than itself's
// vertex 0 has no parent hence only V - 1 parents
template ValidTree(V) {
    signal input parents[V - 1];
    signal output out;

    // if valid tree accm should remain 0
    var accm = 0;

    component boundsCheck[V - 1];
    for (var i = 0; i < V - 1; i++) {
        boundsCheck[i] = LessThan(bits(V - 1));
        boundsCheck[i].in[0] <== parents[i];
        boundsCheck[i].in[1] <== i;

        // parents[i] < i is desirable
        accm += 1 - boundsCheck[i].out;
    }

    component isValidTree = IsZero();
    isValidTree.in <== accm;
    out <== isValidTree.out;
}

// parents and labeling validation is required ==> proof generation will fail
// out is 1 if 'labeling' is a graceful labeling of tree 'parents'
// otherwise, 0

template GracefulLabeling(V) {
    signal input labeling[V];  // private
    signal input parents[V - 1];  // public

    signal output out;

    // validate parents (each parent must be lower than self)
    component isParentsValid = ValidTree(V);
    for (var i = 0; i < V - 1; i++) {
        isParentsValid.parents[i] <== parents[i];
    }
    isParentsValid.out === 1;

    // validate labeling input (set of integers 0 - V - 1)
    component isLabelingUnique = UniqueSet(V);
    for (var i = 0; i < V; i++) {
        isLabelingUnique.in[i] <== labeling[i];
    }
    isLabelingUnique.out === 1;

    // in a tree with V vertexes there are V - 1 edges
    signal edges[V - 1];

    // compute edges labeling
    component edgesA[V - 1];
    component edgesB[V - 1];
    component isALessThanB[V - 1];

    signal ifAIsLess[V - 1];
    signal ifBIsLess[V - 1];

    for (var i = 0; i < V - 1; i++) {
        // the current vertex value
        edgesA[i] = AtIndex(V);
        edgesA[i].index <== i;
        for (var j = 0; j < V; j++) {
            edgesA[i].array[j] <== labeling[j];
        }

        // the parent's vertex value
        edgesB[i] = AtIndex(V);
        edgesB[i].index <== parents[i]; 
        for (var j = 0; j < V; j++) {
            edgesB[i].array[j] <== labeling[j];
        }

        isALessThanB[i] = LessThan(bits(V - 1));
        isALessThanB[i].in[0] <== edgesA[i].out;
        isALessThanB[i].in[1] <== edgesB[i].out;

        ifAIsLess[i] <== isALessThanB[i].out * (edgesB[i].out - edgesA[i].out);
        ifBIsLess[i] <== (1 - isALessThanB[i].out) * (edgesA[i].out - edgesB[i].out);
        edges[i] <== ifAIsLess[i] + ifBIsLess[i];
    }

    // verify edges labeling
    component isEdgesUnique = UniqueSet(V);
    // there isn't a 0 edge because two vertecies can never share the same value
    isEdgesUnique.in[V - 1] <== 0;
    for (var i = 0; i < V - 1; i++) {
        isEdgesUnique.in[i] <== edges[i];
    }

    out <== isEdgesUnique.out;
}

component main {public [parents]} = GracefulLabeling(8);
// component main = AtIndex(16);
