const path = require('path');
const { OUTPUT_DIR } = require('../../circuits/test_config');

const { generateCircuitTest } = require('../../circuits/generate_tests');

generateCircuitTest({
    name: 'ValidTree8',
    path: path.join(OUTPUT_DIR, 'ValidTree8.t.circom'),
    cases: [
        {
            input: {
                parents: [0, 0, 0, 2, 3, 3, 4]
            },
            output: {
                out: 1
            },
        },
        {
            input: {
                parents: [1, 0, 0, 2, 3, 3, 4]
            },
            output: {
                out: 0
            },
            description: 'invalid parents'
        },
        {
            input: {
                parents: [0, 0, 0, 2, 3, 3, 7]
            },
            output: {
                out: 0
            },
            description: 'out of bounds'
        },
        {
            input: {
                parents: [1, 2, 3, 4]
            },
            output: null,
            reasonOfFail: 'Not enough values for input signal parents',
            description: 'not enough values'
        }
    ]
});
