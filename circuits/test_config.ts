import path from 'path';
import { generateTestCircuits, Protocol } from './generate_test_circuits';

export const OUTPUT_DIR = path.join(__dirname, 'artifacts', 'test');
const TEST_CIRCUITS = [
    {
        name: 'UniqueSet8',
        main: 'UniqueSet',
        path: './circuits/circuit.circom',
        parameters: [8],
        publicSignals: [],
        protocol: Protocol.Groth16,
        version: '2.1.4'
    },
    {
        name: 'ValidTree8',
        main: 'ValidTree',
        path: './circuits/circuit.circom',
        parameters: [8],
        publicSignals: [],
        protocol: Protocol.Groth16,
        version: '2.1.4'
    },
    {
        name: 'GracefulLabeling8',
        main: 'GracefulLabeling',
        path: './circuits/circuit.circom',
        parameters: [8],
        publicSignals: [],
        protocol: Protocol.Groth16,
        version: '2.1.4'
    },
];

if (require.main === module) {
    generateTestCircuits(TEST_CIRCUITS, OUTPUT_DIR);
}
