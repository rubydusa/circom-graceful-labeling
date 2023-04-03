import path from 'path';
import { generateTestCircuits, Protocol } from './generate_tests';

export const OUTPUT_DIR = path.join(__dirname, 'artifacts', 'test');
const TEST_CIRCUITS = [
    {
        name: 'UniqueSet8',
        main: 'UniqueSet',
        path: './circuit.circom',
        parameters: [8],
        publicSignals: [],
        protocol: Protocol.Groth16,
        version: '2.1.4'
    },
    {
        name: 'ValidTree8',
        main: 'ValidTree',
        path: './circuit.circom',
        parameters: [8],
        publicSignals: [],
        protocol: Protocol.Groth16,
        version: '2.1.4'
    },
    {
        name: 'GracefulLabeling8',
        main: 'GracefulLabeling',
        path: './circuit.circom',
        parameters: [8],
        publicSignals: [],
        protocol: Protocol.Groth16,
        version: '2.1.4'
    },
];

generateTestCircuits(TEST_CIRCUITS, OUTPUT_DIR);
