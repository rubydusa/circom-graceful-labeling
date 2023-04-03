const path = require('path');
const { OUTPUT_DIR } = require('../../circuits/test_config');

const { generateCircuitTest } = require('../../circuits/generate_tests');

generateCircuitTest({
    name: 'UniqueSet8',
    path: path.join(OUTPUT_DIR, 'UniqueSet8.t.circom'),
    cases: [
        {
            input: {
                in: [5, 2, 7, 0, 3, 4, 1, 6]
            },
            output: {
                out: 1
            },
        },
        {
            input: {
                in: [0, 2, 7, 0, 3, 4, 1, 6]
            },
            output: {
                out: 0
            },
            description: 'duplicates'
        },
        {
            input: {
                in: [1, 2, 3, 4, 5, 6, 7, 8]
            },
            output: {
                out: 0
            },
            description: 'out of bound'
        },
        {
            input: {
                in: [1, 2, 3, 4]
            },
            output: null,
            reasonOfFail: 'Not enough values for input signal in',
            description: 'not enough values'
        }
    ]
});
