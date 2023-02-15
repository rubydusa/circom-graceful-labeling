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

template GracefulLabeling() {
    // signal input vertecies[8];
    signal input edges[16];  // each edge is compromised of two values
    // signal input edgesLabeling[8];

    signal output connectionMap[8][8];

    component aIsI[8][8][8];
    component bIsI[8][8][8];
    component aIsJ[8][8][8];
    component bIsJ[8][8][8];

    component aIsIbIsJ[8][8][8];
    component aIsJbIsI[8][8][8];
    component abIsIJEdge[8][8][8];

    component isIJEdge[8][8];

    // for each i, j connectionMap[i][j] signifies there is an edge between the vertex i and j
    for (var i = 0; i < 8; i++) {
        for (var j = 0; j < 8; j++) {
            var count = 0;
            for (var k = 0; k < 8; k ++) {
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
}

component main = GracefulLabeling();
