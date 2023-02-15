pragma circom 2.0.0;

include "./node_modules/circomlib/circuits/comparators.circom";

template Min() {
    signal input in[2];
    signal output out;

    component compare = LessThan(16);
    compare.in[0] <== in[0];
    compare.in[1] <== in[1];

    out <== compare.out * in[0] + (1 - compare.out) * in[1];
}

template AtIndex(N) {
    signal input array[N];
    signal input index;

    var accm = 0;
    signal output out;

    component isIIndex[N];
    for (var i = 0; i < N; i++) {
        isIIndex[i] = IsEqual();
        isIIndex[i].in[0] <== i;
        isIIndex[i].in[1] <== index;

        accm += isIIndex[i].out * array[i];
    }

    out <== accm;
}

// input is an array compromised of unique values
template UniqueSet(N) {
    signal input in[N];

    component isEquals[N][N];
    for (var i = 0; i < N; i++) {
        for (var j = i + 1; j < N; j++) {
            isEquals[i][j] = IsEqual();
            isEquals[i][j].in[0] <== in[i];
            isEquals[i][j].in[1] <== in[j];

            isEquals[i][j].out === 0;
        }
    }
}

// remove cyclic parents
// i = 0 doesn't have a parent (root), value symbolized with V, the number of edges
//
// if there are cyclic parents, both have their parent reassigned to root
// that is because that is the only node you can assign as a parent without potentially creating more cycles
template FixParents(V) {
    // original parents (potentially with cycles)
    signal input in[V];
    // fixed parents (no cycles)
    signal output out[V];

    component parentOfMyParent[V];
    component isCyclicParent[V];

    // root
    out[0] <== V;

    for (var i = 1; i < V; i++) {
        parentOfMyParnet[i] = AtIndex(V);
        isCyclicParent[i] = IsEqual();

        parentOfMyParent[i].index <== in[i];
        for (var j = 0; j < V; j++) {
            parentOfMyParent[i].array[j] <== in[j];
        }

        isCyclicParent[i].in[0] <== in[i];
        isCyclicParent[i].in[1] <== parentOfMyParent[i].out;

        out[i] <== (1 - isCyclicParent[i].out) * in[i]; 
    }
}

// i = 0 is the root node
template GracefulLabeling(V) {
    signal input verteciesLabeling[V];  // private
    signal input parents[V];  // public

    // proof generation fails if not graceful labeling
    signal output out <== 1;
    // always ignore parents[0], just for the convinience of index arithmetic
    // asserting ensures a random value wasn't placed by mistake
    assert(parents[0] === -1);
    
    // ensure labelings are unique and in bound (0 - V - 1, inclusive)
    component verteciesLabelingBounds[V];
    for (var i = 0; i < V; i++) {
        verteciesLabelingBounds[i] = LessThan(16);
        verteciesLabelingBounds[i].in[0] <== verteciesLabeling[i];
        verteciesLabelingBounds[i].in[1] <== V;
    }

    component isUnique = UniqueSet(V);

    // fix parents
    component fixedParents = FixParents(V);
    for (var i = 0; i < V; i++) {
        fixedParents.in[i] <== parents[i];
    }

    component edgesA[V - 1];
    component edgesB[V - 1];
    component edgesValue[V - 1];

    for (var i = 0; i < V - 1; i++) {
        // the current vertex value
        edgesA[i] = AtIndex(V);
        edgesA[i].index <== i;
        for (var j = 0; j < V - 1; j++) {
            edgesA.array[j] <== verteciesLabeling[j];
        }

        // the parent's vertex value
        edgesB[i] = AtIndex(V);
        edgesB[i].index <== fixedParents.out[i + 1];
        for (var j = 0; j < V - 1; j++) {
            edgesB.array[j] <== verteciesLabeling[j];
        }

        // for relatively small numbers, taking the minimum out of a - b and b - a is the absolute value
        edgesValue[i] = Min();
        edgesValue[i].in[0] <== edgesA[i].out - edgesB[i].out;
        edgesValue[i].in[1] <== edgesB[i].out - edgesA[i].out;
    }
}

