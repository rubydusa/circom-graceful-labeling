pragma circom 2.1.4;

include "./node_modules/circomlib/circuits/comparators.circom";
include "./node_modules/circomlib/circuits/bitify.circom";

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
// TODO: compare against other possible implementation of total
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

    component result = CalculateTotal(N);
    for (var i = 0; i < N; i++) {
        var isEqual = IsEqual()([i, index]);
        result.in[i] <== isEqual * array[i];
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

    for (var i = 0; i < N; i++) {
        // in[i] < N is desirable
        var inBound = LessThan(bits(N - 1))([in[i], N]);
        accm += 1 - inBound;
    }

    for (var i = 0; i < N; i++) {
        for (var j = i + 1; j < N; j++) {
            // in[i] != in[j] is desirable
            var isEqual = IsEqual()([in[i], in[j]]);
            accm += isEqual;
        }
    }

    out <== IsZero()(accm);
}

// parents is an array such that the i-th element is the parent of node i
// in order to ensure non cyclicity, each vertex must have a parent whose index is lower than itself's
// vertex 0 has no parent hence only V - 1 parents
template ValidTree(V) {
    signal input parents[V - 1];
    signal output out;

    // if valid tree accm should remain 0
    var accm = 0;

    for (var i = 0; i < V - 1; i++) {
        // parents[i] < i is desirable
        var inBound = LessThan(bits(V - 1))([parents[i], i]);
        accm += 1 - inBound;
    }

    out <== IsZero()(accm);
}

// parents and labeling validation is required ==> proof generation will fail
// out is 1 if 'labeling' is a graceful labeling of tree 'parents'
// otherwise, 0

template GracefulLabeling(V) {
    signal input labeling[V];  // private
    signal input parents[V - 1];  // public

    signal output out;

    // validate parents (each parent must be lower than self)
    var isParentsValid = ValidTree(V)(parents);
    isParentsValid === 1;

    // validate labeling input (set of integers 0 - V - 1)
    var isLabelingUnique = UniqueSet(V)(labeling);
    isLabelingUnique === 1;

    // compute edges labeling
    signal ifAIsLess[V - 1];
    signal ifBIsLess[V - 1];
    signal edges[V - 1];

    for (var i = 0; i < V - 1; i++) {
        // compute edge vertex values
        var edgeA = AtIndex(V)(index <== i, array <== labeling);
        var edgeB = AtIndex(V)(index <== parents[i], array <== labeling);

        // compute absolute difference
        var isALessThanB = LessThan(bits(V - 1))([edgeA, edgeB]);
        ifAIsLess[i] <== isALessThanB * (edgeB - edgeA);
        ifBIsLess[i] <== (1 - isALessThanB) * (edgeA - edgeB);

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

// reduce the amount of public signals
template Main(V) {
    // how many bits needed to represent one vertex or one edge
    var bitsOfV = bits(V);

    // compute how many bits does the vertex labeling information require
    var labelingBits = bitsOfV * V;
    var labelingSignalsNeeded = (labelingBits \ 254) + 1;
    
    // compute how many bits does the parents information require
    var parentsBits = bitsOfV * (V - 1);
    var parentsSignalsNeeded = (parentsBits \ 254) + 1;

    signal input labeling[labelingSignalsNeeded];
    signal input parents[parentsSignalsNeeded];

    // 1 if true
    signal output out;

    component labelingAsBits[labelingSignalsNeeded];
    component parentsAsBits[parentsSignalsNeeded];

    for (var i = 0; i < labelingSignalsNeeded; i++) {
        var curBits = i == labelingSignalsNeeded - 1 ? labelingBits % 254 : 254;

        labelingAsBits[i] = Num2Bits(curBits);
        labelingAsBits[i].in <== labeling[i];
    }

    for (var i = 0; i < parentsSignalsNeeded; i++) {
        var curBits = i == parentsSignalsNeeded - 1 ? parentsBits % 254 : 254;

        parentsAsBits[i] = Num2Bits(curBits);
        parentsAsBits[i].in <== parents[i];
    }

    var labelingVars[V];
    var parentsVars[V - 1];

    // initialize variable arrays
    labelingVars[V - 1] = 0;
    for (var i = 0; i < V - 1; i++) {
        labelingVars[i] = 0;
        parentsVars[i] = 0;
    }

    // iterate over every bit, determine in which Num2Bits component it is located at which index,
    // determine to which vertex labeling it corresponds and add it to the appropriate vertex label
    for (var i = 0; i < labelingBits; i++) {
        var labelingIndex = i \ bitsOfV;
        var labelingAsBitsIndex = i \ 254;

        var currentPower = 2 ** (i % bitsOfV);

        labelingVars[labelingIndex] += currentPower * labelingAsBits[labelingAsBitsIndex].out[i % 254];
    }

    // iterate over every bit, determine in which Num2Bits component it is located at which index,
    // determine to which parent index it corresponds and add it to the appropriate parent value
    for (var i = 0; i < parentsBits; i++) {
        var parentsIndex = i \ bitsOfV;
        var parentsAsBitsIndex = i \ 254;

        var currentPower = 2 ** (i % bitsOfV);

        parentsVars[parentsIndex] += currentPower * parentsAsBits[parentsAsBitsIndex].out[i % 254];
    }

    component gracefulLabeling = GracefulLabeling(V);

    gracefulLabeling.labeling[V - 1] <== labelingVars[V - 1];
    for (var i = 0; i < V - 1; i++) {
        gracefulLabeling.labeling[i] <== labelingVars[i];
        gracefulLabeling.parents[i] <== parentsVars[i];
    }

    out <== gracefulLabeling.out;
}

component main {public [parents]} = Main(8);
