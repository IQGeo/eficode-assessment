# EMU Scripts

This directory contains scripts that can be used to automate creating .md files from the json files in the `data` directory.
The scripts are written in Bash and can be run from the command line.

## Prepare the data

- Download all the artifacts from the assessment run into their own folder

- Extract the artifacts into the target repository under `data` directory, you can use the following example script:

`./scripts/_unzip_data.sh ~/Downloads/dufry ~/dev/customers/avolta/data

## Process the data

Run the process.sh script to create the markdown files
It'll process the json files in there and put the markdown files in the corresponding ../reports folder

`./scripts/process.sh ~/dev/customers/avolta/data`

## Go through the reports

It is generally a good idea to go through the generated reports and check that everything is in order

## Update the playbook.md

Update the playbook.md file with the data generated from the reports
