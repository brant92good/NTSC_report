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
# Check if compilation was successful
if [ $? -eq 0 ]; then
    echo "Compilation successful."
    
    # --- Backup Configuration ---
    BACKUP_ROOT="backups"
    TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
    BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"
    LATEST_LINK="${BACKUP_ROOT}/latest"
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    echo "Creating backup in $BACKUP_DIR..."

    # 1. Copy source files (excluding images, backups, git, and temp files)
    # Using rsync for clean exclusion. If rsync is not available, fail gracefully.
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --exclude="images" \
                 --exclude="backups" \
                 --exclude=".git" \
                 --exclude="*.aux" \
                 --exclude="*.log" \
                 --exclude="*.out" \
                 --exclude="*.toc" \
                 --exclude="*.lof" \
                 --exclude="*.lot" \
                 --exclude="*.bbl" \
                 --exclude="*.blg" \
                 --exclude="*.fls" \
                 --exclude="*.fdb_latexmk" \
                 --exclude="*.synctex.gz" \
                 . "$BACKUP_DIR/"
    else
        # Fallback to pure cp if rsync is missing (less precise exclusions but works)
        echo "Warning: rsync not found. Using cp (ignore warnings about exclusions)."
        # Copy everything then remove excluded typically
        cp -r . "$BACKUP_DIR/"
        # Cleanup
        rm -rf "$BACKUP_DIR/backups" "$BACKUP_DIR/.git" "$BACKUP_DIR/images"
        find "$BACKUP_DIR" -name "*.aux" -delete
        find "$BACKUP_DIR" -name "*.log" -delete
        find "$BACKUP_DIR" -name "*.out" -delete
        # (Add other cleanups as needed)
    fi

    # 2. Handle Images (Symlink if unchanged)
    # Check if 'latest' symlink exists and points to a valid directory
    IMAGES_LINKED=false
    if [ -L "$LATEST_LINK" ] && [ -d "$LATEST_LINK/images" ]; then
        PREV_IMAGES_PATH=$(readlink -f "$LATEST_LINK/images")
        
        # Compare current images with previous backup's images
        # -r: recursive, -q: brief, -N: treat absent files as empty (not strictly needed but good habit)
        diff -r -q "images" "$PREV_IMAGES_PATH" > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo "Images unchanged. Creating symlink."
            # Create relative symlink to the previous images folder
            # We use absolute path for the target to be safe, or calculate relative.
            # Simple approach: Symlink to the absolute path of the previous images
            ln -s "$PREV_IMAGES_PATH" "$BACKUP_DIR/images"
            IMAGES_LINKED=true
        else
            echo "Images changed. Copying new version."
        fi
    fi

    if [ "$IMAGES_LINKED" = false ]; then
        cp -r "images" "$BACKUP_DIR/"
    fi
     
    # Copy the compiled PDF to the backup directory
    cp "${MAIN_FILE}.pdf" "$BACKUP_DIR/"

    # 3. Update 'latest' symlink
    # -n: treat as file if destination is a link to directory (avoid nesting)
    # -f: force
    ln -sfn "$TIMESTAMP" "$LATEST_LINK"

    echo "Backup complete: $BACKUP_DIR"
else
    echo "Compilation failed. No backup created."
    exit 1
fi
