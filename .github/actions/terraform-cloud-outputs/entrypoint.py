import json
import os
import subprocess


REQUIRED_INPUTS = [
    'TFC_TOKEN',
    'TFC_ORG',
    'TFC_WORKSPACE',
    'TFC_VARIABLES',
]


def read_inputs():
    inputs = {x: os.environ.get(x) for x in REQUIRED_INPUTS}
    missing = {k: v for k, v in inputs.items() if v is None}
    if missing:
        for param in missing:
            print(f'Parameter required: {param}')
        exit(1)
    inputs['TFC_VARIABLES'] = [x.strip() for x in inputs['TFC_VARIABLES'].split(',')]
    return inputs


def main():
    inputs = read_inputs()
    variables = {}
    for variable in inputs['TFC_VARIABLES']:
        output = subprocess.check_output([
            '/bin/tfc-cli',
            'stateversions',
            'current',
            'getoutput',
            '-workspace',
            inputs['TFC_WORKSPACE'],
            '-name',
            variable
        ])
        variables[variable] = json.loads(output)['result']['value']

    for key, value in variables.items():
        print(f"::set-output name={key}::{value}")


if __name__ == '__main__':
    main()
