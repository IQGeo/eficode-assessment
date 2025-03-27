#!/bin/bash

# Check if a tool is installed
# $1 => tool name
check_if_available() {
    tool="$1"

    which -s "$tool"

    if [[ "$?" != 0 ]] ; then
        echo "❌ $tool: not installed"
        return 1
    else
        echo "✅ $tool: installed"
        return 0
    fi
}
# Checks if a brew package is installed (works with packages that installs a different binary name)
# $1 => package name
is_brew_package_installed() {
    brew list | grep "$1" > /dev/null 2>&1;

    if [[ "$?" != 0 ]] ; then
        echo "❌ $1: not installed"; return 1;
    else
        echo "✅ $1: installed"; return 0;
    fi
}
# Installs a brew package
# $1 => package name
install_brew_package() {
    is_brew_package_installed "$1";

    if [[ "$?" != 0 ]] ; then
        echo "Installing $1";
        brew update && brew install "$1";
    fi
}

# Install homebrew if not already installed
install_homebrew() {
    # [Homebrew](https://brew.sh/)
    check_if_available "brew"
    if [[ "$?" != 0 ]] ; then
        echo "Installing brew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # echo "You might need to add /opt/homebrew/bin to your PATH (by updating your shell profile)"
    fi
}

install_homebrew
install_brew_package "pandoc"
install_brew_package "weasyprint"

# Loop through all .md files and create an empty .pdf file with the same name
for md_file in *.md; do
  pdf_file="${md_file%.md}.pdf"
  pandoc --pdf-engine weasyprint "${md_file}" --o "${pdf_file}" 2>/dev/null
  echo "Updated ${pdf_file}"
done

cd "$(git rev-parse --show-toplevel)" || exit
if [ -f "playbook.md" ]; then
  pandoc --pdf-engine weasyprint playbook.md --o playbook.pdf 2>/dev/null
  echo "Updated playbook.pdf"
fi
