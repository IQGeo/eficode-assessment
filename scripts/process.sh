#!/bin/bash

# Run all the *.sh scripts except for process.sh
for script in *.sh; do
    if [ "${script}" != "process.sh" ]; then
        bash "${script}"
    fi
done

# Initialize the combined markdown file
echo "# Combined Report" > combined_report.md
printf "\n## Index\n" >> combined_report.md

# Create an index for the first two headings in each markdown file
for file in *.md; do
    if [ "${file}" != "combined_report.md" ]; then
        heading1=$(sed -n '/^# /p' "${file}" | head -1)
        heading2=$(sed -n '/^## /p' "${file}" | head -1)
        echo "- [${file}](#${file})" >> combined_report.md
        echo "  - [${heading1}](#${heading1// /-})"
        echo "  - [${heading2}](#${heading2// /-})"
    fi
done

printf "\n## Content\n" >> combined_report.md

# Combine all the markdown files into a single markdown file
for file in *.md; do
    if [ "${file}" != "combined_report.md" ]; then
        printf "\n### \"%s\"\n" "${file}" >> combined_report.md
        cat "${file}" >> combined_report.md
    fi
done
