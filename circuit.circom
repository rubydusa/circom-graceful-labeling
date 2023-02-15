pragma circom 2.0.0;

template XOR() {
    signal input a;
    signal input b;
    signal output out;

    out <== a + b - 2*a*b;
}

template AND() {
    signal input a;
    signal input b;
    signal output out;

    out <== a*b;
}

template IsEqual() {
    signal input in[2];
    signal output out;

    component isz = IsZero();

    in[1] - in[0] ==> isz.in;

    isz.out ==> out;
}

template IsZero() {
    signal input in;
    signal output out;

    signal inv;

    inv <-- in!=0 ? 1/in : 0;

    out <== -in*inv +1;
    in*out === 0;
}

// E is the amount of edges
// V is the amount of vertecies
template ConnectionMap(E, V) {
    signal input edges[2 * E];  // each edge is compromised of two values

    signal output connectionMap[V][V];

    component aIsI[V][V][E];
    component bIsI[V][V][E];
    component aIsJ[V][V][E];
    component bIsJ[V][V][E];

    component aIsIbIsJ[V][V][E];
    component aIsJbIsI[V][V][E];
    component abIsIJEdge[V][V][E];

    component isIJEdge[V][V];

    // for each i, j connectionMap[i][j] signifies there is an edge between the vertex i and j
    for (var i = 0; i < V; i++) {
        for (var j = i + 1; j < V; j++) {
            var count = 0;
            for (var k = 0; k < E; k++) {
                var a = edges[2 * k];
                var b = edges[2 * k + 1];

                aIsI[i][j][k] = IsEqual();
                bIsI[i][j][k] = IsEqual();
                aIsJ[i][j][k] = IsEqual();
                bIsJ[i][j][k] = IsEqual();

                aIsIbIsJ[i][j][k] = AND();
                aIsJbIsI[i][j][k] = AND();

                abIsIJEdge[i][j][k] = XOR();

                aIsI[i][j][k].in[0] <== a;
                aIsI[i][j][k].in[1] <== i;
                bIsI[i][j][k].in[0] <== b;
                bIsI[i][j][k].in[1] <== i;
                aIsJ[i][j][k].in[0] <== a;
                aIsJ[i][j][k].in[1] <== j;
                bIsJ[i][j][k].in[0] <== b;
                bIsJ[i][j][k].in[1] <== j;

                aIsIbIsJ[i][j][k].a <== aIsI[i][j][k].out;
                aIsIbIsJ[i][j][k].b <== bIsJ[i][j][k].out;
                aIsJbIsI[i][j][k].a <== aIsJ[i][j][k].out;
                aIsJbIsI[i][j][k].b <== bIsI[i][j][k].out;

                abIsIJEdge[i][j][k].a <== aIsIbIsJ[i][j][k].out;
                abIsIJEdge[i][j][k].b <== aIsJbIsI[i][j][k].out;

                count += abIsIJEdge[i][j][k].out;
            }

            isIJEdge[i][j] = IsZero();
            isIJEdge[i][j].in <== count;

            connectionMap[i][j] <== 1 - isIJEdge[i][j].out;
        }
    }
    // graph is non-directional so relationship is symmetric
    for (var i = 0; i < V; i++) {
        for (var j = i + 1; j < V; j++) {
            connectionMap[j][i] <== connectionMap[i][j];
        }
    }

    // vertecies can't have edges with themselves
    for (var i = 0; i < V; i++) {
        connectionMap[i][i] <== 0;
    }
}

component main = ConnectionMap(8, 8);
