import fs, { PathLike } from 'fs';
import path from 'path';

export enum Protocol {
    Plonk,
    Groth16
}

export interface Circuit {
    name: string,
    main: string,
    path: PathLike, 
    parameters: number[],
    publicSignals: string[],
    protocol: Protocol,
    version: string
}

export function generateTestCircuit(circuit: Circuit): string {
    const { main, path: circuitPath, parameters, publicSignals, version } = circuit;

    const pragmaString = `pragma circom ${version};`;
    const includeString = `include "${path.resolve(circuitPath.toString())}";`;
    const publicSignalsString = publicSignals.length > 0 ? `{public [${publicSignals.join()}]} ` : '';
    const mainComponenetString = `component main ${publicSignalsString}= ${main}(${parameters.join()});`;

    return [
        pragmaString,
        includeString,
        mainComponenetString
    ].join('\n');
}

export function generateTestCircuits(circuits: Circuit[], outputDir: PathLike): void {
    fs.mkdirSync(outputDir, { recursive: true });

    for (const circuit of circuits) {
        const testCircuit = generateTestCircuit(circuit);
        fs.writeFileSync(path.join(outputDir.toString(), `${circuit.name}.t.circom`), testCircuit);
    }
}
