#!/bin/bash

# Initialize the combined markdown file
echo "# Combined Report" > combined_report.md
printf "\n## Index\n\n" >> combined_report.md

# Create an index for the first two headings in each markdown file
for file in *.md; do
    if [ "${file}" != "combined_report.md" ]; then
        echo "- [${file}](###${file})" >> combined_report.md
        # heading1=$(sed -n '/^# /p' "${file}" | head -1)
        # heading2=$(sed -n '/^## /p' "${file}" | head -1)
        # echo "  - [${heading1}](#${heading1// /-})"
        # echo "  - [${heading2}](#${heading2// /-})"
    fi
done

printf "\n## Content\n" >> combined_report.md

# Combine all the markdown files into a single markdown file
for file in *.md; do
    if [ "${file}" != "combined_report.md" ]; then
        printf "\n### %s\n\n" "${file}" >> combined_report.md
        cat "${file}" >> combined_report.md
    fi
done
