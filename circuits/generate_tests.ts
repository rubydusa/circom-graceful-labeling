// @ts-ignore
import { wasm as wasmTester } from 'circom_tester';

import chai, { expect } from 'chai';
import chaiAsPromised from 'chai-as-promised';
chai.use(chaiAsPromised);

import { PathLike } from 'fs';

import 'mocha';

interface CircuitTest {
    path: PathLike,
    name: string,
    cases: CircuitTestCase[]
}

interface CircuitTestCase {
    input: object,
    output: object | null,
    reasonOfFail?: string,
    description?: string
}

export function generateCircuitTest(circuitTest: CircuitTest): void {
    describe(circuitTest.name, () => {
        let circuit: any;
        before(async () => {
            circuit = await wasmTester(circuitTest.path);
        });

        for (const [i, caseData] of circuitTest.cases.entries()) {
            const { input, output, reasonOfFail, description } = caseData;
            const caseName = description !== undefined ? `Case#${i}: ${description}` : `Case#${i}`; 

            if (reasonOfFail !== undefined) {
                it(caseName, async () => {
                    await expect((async () => {
                        const witness = await circuit.calculateWitness(input);
                        await circuit.checkConstraints(witness);
                    })()).to.be.rejectedWith(reasonOfFail);
                });
            } else {
                it(caseName, async () => {
                    const witness = await circuit.calculateWitness(input);
                    await circuit.checkConstraints(witness);

                    if (output !== null) {
                        await circuit.assertOut(witness, output);
                    }
                });
            }
        }
    });
}
