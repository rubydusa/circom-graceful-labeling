const path = require('path');
const { OUTPUT_DIR } = require('../../circuits/test_config');

const { generateCircuitTest } = require('../../circuits/generate_tests');

generateCircuitTest({
    name: 'GracefulLabeling8',
    path: path.join(OUTPUT_DIR, 'GracefulLabeling8.t.circom'),
    cases: [
        {
            input: {
                labeling: [0, 7, 3, 6, 5, 1, 2, 4],
                parents: [0, 0, 0, 2, 3, 3, 4]
            },
            output: {
                out: 1
            },
        }
    ]
});


