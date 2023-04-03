pragma circom 2.1.4;
include "../node_modules/circomlib/circuits/comparators.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

// amount of bits needed to represent n
function bits(n) {
    var result = 1;
    while (n > 1) {
        n \= 2;
        result++;
    }
    return result;
}

// 1. return how many bits are needed
// 2. return how many signals are needed
function bit_usage(MAX_VALUE, AMOUNT) {
    var b = bits(MAX_VALUE);

    return b * AMOUNT;
}

function bit_usage_signals(MAX_VALUE, AMOUNT) {
    var b = bits(MAX_VALUE);

    return ((b * AMOUNT) \ 254) + 1;
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
        var inBound = LessThan(bits(N))([in[i], N]);
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
    // parents[0] represents the parent of vertex index 1
    signal input parents[V - 1];
    signal output out;

    // if valid tree accm should remain 0
    var accm = 0;

    for (var i = 0; i < V - 1; i++) {
        // parents[i] < i + 1 is desirable
        var inBound = LessThan(bits(V))([parents[i], i + 1]);
        accm += 1 - inBound;
    }

    out <== IsZero()(accm);
}

// parents and labeling validation is required ==> proof generation will fail
// out is 1 if 'labeling' is a graceful labeling of tree 'parents'
// otherwise, 0
template GracefulLabeling(V) {
    signal input labeling[V];  // private
    // parents[0] represents the parent of vertex index 1
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

    for (var i = 1; i < V; i++) {
        // compute edge vertex values
        var edgeA = AtIndex(V)(index <== i, array <== labeling);
        var edgeB = AtIndex(V)(index <== parents[i - 1], array <== labeling);

        // compute absolute difference
        var isALessThanB = LessThan(bits(V - 1))([edgeA, edgeB]);
        ifAIsLess[i - 1] <== isALessThanB * (edgeB - edgeA);
        ifBIsLess[i - 1] <== (1 - isALessThanB) * (edgeA - edgeB);

        edges[i - 1] <== ifAIsLess[i - 1] + ifBIsLess[i - 1];
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

// returns an array of AMOUNT values in range 0 to MAX_VALUE (inclusive)
// from compressed input
template FromCompressed(MAX_VALUE, AMOUNT) {
    var bitsOfV = bits(MAX_VALUE);
    var bitsNeeded = bit_usage(MAX_VALUE, AMOUNT);
    var signalsNeeded = bit_usage_signals(MAX_VALUE, AMOUNT);

    signal input in[signalsNeeded];
    signal output out[AMOUNT];

    component asBits[signalsNeeded];

    for (var i = 0; i < signalsNeeded; i++) {
        var curBits = i == signalsNeeded - 1 ? bitsNeeded % 254 : 254;

        asBits[i] = Num2Bits(curBits);
        asBits[i].in <== in[i];
    }

    var values[AMOUNT];
    for (var i = 0; i < AMOUNT; i++) {
        values[i] = 0;
    }

    for (var i = 0; i < bitsNeeded; i++) {
        var valuesIndex = i \ bitsOfV;
        var asBitsIndex = i \ 254;

        var currentPower = 2 ** (i % bitsOfV);

        values[valuesIndex] += currentPower * asBits[asBitsIndex].out[i % 254];
    }

    for (var i = 0; i < AMOUNT; i++) {
        out[i] <== values[i];
    }
}

template Main(V) {
    // bit usage of V labels such that the max value is V - 1
    var labelingSignalsNeeded = bit_usage_signals(V - 1, V);
    // bit usage of V - 1 parents array such that the max value is V - 1
    var parentsSignalsNeeded = bit_usage_signals(V - 1, V - 1);

    signal input labeling[labelingSignalsNeeded];
    signal input parents[parentsSignalsNeeded];

    // 1 if true
    signal output out;

    component labelingAsBits[labelingSignalsNeeded];
    component parentsAsBits[parentsSignalsNeeded];

    var labelingUncompressed[V] = FromCompressed(V - 1, V)(labeling);
    var parentsUncompressed[V - 1] = FromCompressed(V - 1, V - 1)(parents);

    var isGracefulLabeling = GracefulLabeling(V)(labeling <== labelingUncompressed, parents <== parentsUncompressed);

    out <== isGracefulLabeling;
    log("result: ", out);
}

component main {public [parents]} = Main(8);
