#!/bin/bash

# Define the main file name (without extension)
MAIN_FILE="main"

# Create versions directory if it doesn't exist
if [ ! -d "versions" ]; then
    mkdir versions
    echo "Created versions directory."
fi

echo "Compiling..."

# Compilation sequence to ensure references and citations are correct
pdflatex "${MAIN_FILE}.tex"
bibtex "${MAIN_FILE}"
pdflatex "${MAIN_FILE}.tex"
pdflatex "${MAIN_FILE}.tex"

# Check if compilation was successful
if [ $? -eq 0 ]; then
    echo "Compilation successful."
    
    # Get current timestamp
    TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
    
    # Define versioned filename
    VERSIONED_FILE="versions/${MAIN_FILE}_${TIMESTAMP}.pdf"
    
    # Copy the generated PDF to the versions folder
    cp "${MAIN_FILE}.pdf" "$VERSIONED_FILE"
    
    echo "PDF generated: ${MAIN_FILE}.pdf"
    echo "Versioned copy saved to: $VERSIONED_FILE"
else
    echo "Compilation failed."
    exit 1
fi
