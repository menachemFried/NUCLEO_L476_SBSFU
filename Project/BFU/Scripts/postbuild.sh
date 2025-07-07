#!/bin/sh

# ==============================================================================
#
# Post-build Script for SBSFU Project - POSIX sh Compliant
#
# Description:
#   This script is executed after the SBSFU project has been built, from
#   within the build output directory (e.g., 'Debug' or 'Release').
#   It automates the process of preparing critical build artifacts for the
#   User Application.
#
# Main Tasks:
#   1. Auto-detects the build configuration ('Debug' or 'Release').
#   2. Extracts Secure Engine API symbols from the SBSFU ELF file.
#   3. Generates a linker script ('se_interface_app.ld') and places it in the
#      shared 'Common/Linker' directory.
#   4. Copies the final ELF and the SE interface object file to the
#      shared Common directory ('Common/Debug' or 'Common/Release').
#   5. Provides flexible logging to console, file, or both, with output
#      in the central 'BFU/Output' directory.
#
# Parameters:
#   $1 - SBSFU ELF Filename:  Filename of the SBSFU ELF file (e.g., "SBSFU.elf").
#   $2 - Common Directory:    Relative path to the Common directory.
#   $3 - Log Info Mode:       (Optional) Logging mode for INFO messages. Default: 1.
#   $4 - Log Debug Mode:      (Optional) Logging mode for DEBUG messages. Default: 1.
#   $5 - Log Error Mode:      (Optional) Logging mode for ERROR messages. Default: 1.
#
# Logging Modes: 1=Console, 2=File, 3=Both
#
# ==============================================================================

# --- Configuration ---

# Exit on error or unset variable
set -e
set -u

# --- Function Definitions ---

# Print usage information and exit
usage() {
    echo "Usage: $0 <SBSFU ELF Filename> <Path to Common Dir> [Log Info] [Log Debug] [Log Error]"
    exit 1
}

# Log an error message and exit
error_exit() {
    error_log "$1" "$2"
    exit 1
}

# --- Logging Functions ---

info_log() {
    message="[LINE $1 - INFO] $2"
    case "$LOG_INFO_MODE" in
        1) echo "$message";;
        2) echo "$message" >> "$LOG_INFO_FILE";;
        3) echo "$message" | tee -a "$LOG_INFO_FILE";;
    esac
}

debug_log() {
    message="[LINE $1 - DEBUG] $2"
    case "$LOG_DEBUG_MODE" in
        1) echo "$message";;
        2) echo "$message" >> "$LOG_DEBUG_FILE";;
        3) echo "$message" | tee -a "$LOG_DEBUG_FILE";;
    esac
}

error_log() {
    message="[LINE $1 - ERROR] $2"
    case "$LOG_ERROR_MODE" in
        1) echo "$message";;
        2) echo "$message" >> "$LOG_ERROR_FILE";;
        3) echo "$message" | tee -a "$LOG_ERROR_FILE";;
    esac
}

# --- Main Script Logic ---

main() {
    # --- 1. Argument and Environment Validation ---

    if [ $# -lt 2 ]; then
        echo "Error: Missing mandatory arguments."
        usage
    fi

    SBSFU_ELF_FILENAME="$1"
    COMMON_DIR_REL="$2"

    # Auto-detect build mode from the current directory's name
    BUILD_MODE=$(basename "$(pwd)")

    # --- 2. Path and Logging Setup ---

    # Get the BFU project root directory by going up from the script's own location
    SCRIPT_DIR_ABS="$(cd "$(dirname "$0")" && pwd)"
    BFU_PROJECT_ROOT_ABS="$(cd "$SCRIPT_DIR_ABS/.." && pwd)"

    # Setup logging in the central BFU/Output directory
    LOG_DIR="$BFU_PROJECT_ROOT_ABS/Output"
    mkdir -p "$LOG_DIR"
    LOG_INFO_FILE="$LOG_DIR/postbuild_info.log"
    LOG_DEBUG_FILE="$LOG_DIR/postbuild_debug.log"
    LOG_ERROR_FILE="$LOG_DIR/postbuild_error.log"
    
    LOG_INFO_MODE=${3:-1}
    LOG_DEBUG_MODE=${4:-1}
    LOG_ERROR_MODE=${5:-1}

    : > "$LOG_INFO_FILE"
    : > "$LOG_DEBUG_FILE"
    : > "$LOG_ERROR_FILE"

    # Convert Common dir to an absolute path for reliability
    COMMON_DIR_ABS="$(cd "$COMMON_DIR_REL" && pwd)"

    # Define source and destination paths
    SOURCE_DIR_ABS="$(pwd)"
    DEST_DIR_ABS="$COMMON_DIR_ABS/$BUILD_MODE"
    # Linker script destination is SHARED, not mode-specific
    DEST_LINKER_DIR="$COMMON_DIR_ABS/Linker"
    DEST_SE_IF_DIR="$DEST_DIR_ABS/Middlewares/STM32_Secure_Engine"

    info_log "$LINENO" "Post-build started for '$BUILD_MODE' configuration."
    debug_log "$LINENO" "--- Initial Values & Paths ---"
    debug_log "$LINENO" "Build Mode (auto-detected): $BUILD_MODE"
    debug_log "$LINENO" "SBSFU ELF Filename (param 1): $SBSFU_ELF_FILENAME"
    debug_log "$LINENO" "Common Dir Relative (param 2): $COMMON_DIR_REL"
    debug_log "$LINENO" "Log Modes (I/D/E): $LOG_INFO_MODE/$LOG_DEBUG_MODE/$LOG_ERROR_MODE"
    debug_log "$LINENO" " "
    debug_log "$LINENO" "--- Constructed Paths ---"
    debug_log "$LINENO" "BFU Project Root (abs): $BFU_PROJECT_ROOT_ABS"
    debug_log "$LINENO" "Log Directory: $LOG_DIR"
    debug_log "$LINENO" "Source Dir (abs): $SOURCE_DIR_ABS"
    debug_log "$LINENO" "Common Dir (abs): $COMMON_DIR_ABS"
    debug_log "$LINENO" "Artifacts Dest Dir (abs): $DEST_DIR_ABS"
    debug_log "$LINENO" "Linker Script Dest Dir: $DEST_LINKER_DIR"
    debug_log "$LINENO" "SE Interface Dest Dir: $DEST_SE_IF_DIR"
    debug_log "$LINENO" "---------------------------------"

    # --- 3. Symbol Extraction and Linker Script Generation ---

    # Define file paths
    SBSFU_ELF_FILE_ABS="$SOURCE_DIR_ABS/$SBSFU_ELF_FILENAME"
    SE_INTERFACE_DEF_FILE="$SCRIPT_DIR_ABS/se_interface.txt"
    OUTPUT_LD_FILE="$DEST_LINKER_DIR/se_interface_app.ld"

    # Temporary files
    NM_OUTPUT_FILE="$SOURCE_DIR_ABS/nm.txt"
    SYMBOL_LIST_FILE="$SOURCE_DIR_ABS/symbol.list"
    SE_INTERFACE_UNIX_FILE="$SOURCE_DIR_ABS/se_interface_unix.txt"

    # Verify required files exist
    if [ ! -f "$SBSFU_ELF_FILE_ABS" ]; then
        error_exit "$LINENO" "SBSFU ELF file not found at '$SBSFU_ELF_FILE_ABS'"
    fi
    if [ ! -f "$SE_INTERFACE_DEF_FILE" ]; then
        error_exit "$LINENO" "Secure Engine interface definition file not found at '$SE_INTERFACE_DEF_FILE'"
    fi

    info_log "$LINENO" "Step 1: Extracting symbols from '$SBSFU_ELF_FILENAME'..."
    if ! command -v arm-none-eabi-nm >/dev/null 2>&1; then
        error_exit "$LINENO" "'arm-none-eabi-nm' not found. Ensure ARM toolchain is in PATH."
    fi
    arm-none-eabi-nm "$SBSFU_ELF_FILE_ABS" > "$NM_OUTPUT_FILE"

    info_log "$LINENO" "Step 2: Filtering symbols..."
    tr -d '\r' < "$SE_INTERFACE_DEF_FILE" > "$SE_INTERFACE_UNIX_FILE"
    grep -F -f "$SE_INTERFACE_UNIX_FILE" "$NM_OUTPUT_FILE" > "$SYMBOL_LIST_FILE"
    
    symbol_count=$(wc -l < "$SYMBOL_LIST_FILE")
    debug_log "$LINENO" "Found $symbol_count matching API symbols."
    if [ "$symbol_count" -eq 0 ]; then
        error_exit "$LINENO" "No matching symbols found. Check 'se_interface.txt'."
    fi

    info_log "$LINENO" "Step 3: Generating linker script..."
    mkdir -p "$DEST_LINKER_DIR"
    awk '{print $3 " = 0x" $1 ";"}' < "$SYMBOL_LIST_FILE" > "$OUTPUT_LD_FILE"
    debug_log "$LINENO" "Generated linker script at '$OUTPUT_LD_FILE'"

    # Cleanup temporary files
    rm "$NM_OUTPUT_FILE" "$SYMBOL_LIST_FILE" "$SE_INTERFACE_UNIX_FILE"

    # --- 4. Copying Build Artifacts to Common Directory ---

    info_log "$LINENO" "Step 4: Copying build artifacts to '$DEST_DIR_ABS'..."

    # Create destination directories if they don't exist
    mkdir -p "$DEST_DIR_ABS"
    mkdir -p "$DEST_SE_IF_DIR"

    # 1. Copy the main ELF file to the destination, naming it 'SBSFU.elf'
    cp "$SBSFU_ELF_FILE_ABS" "$DEST_DIR_ABS/SBSFU.elf"
    debug_log "$LINENO" "Copied '$SBSFU_ELF_FILENAME' to '$DEST_DIR_ABS/SBSFU.elf'"

    # 2. Copy the Secure Engine interface object file
    SE_IF_OBJ_FILE_SOURCE="$SOURCE_DIR_ABS/Middlewares/STM32_Secure_Engine/se_interface_application.o"
    if [ -f "$SE_IF_OBJ_FILE_SOURCE" ]; then
        cp "$SE_IF_OBJ_FILE_SOURCE" "$DEST_SE_IF_DIR/"
        debug_log "$LINENO" "Copied 'se_interface_application.o' to '$DEST_SE_IF_DIR/'"
    else
        error_exit "$LINENO" "Secure Engine interface object file not found at '$SE_IF_OBJ_FILE_SOURCE'"
    fi

    # --- 5. Optional: Sync ELF with Application Common Directory ---

    info_log "$LINENO" "Step 5: Checking for application-specific common directory..."
    app_common_location_file="$COMMON_DIR_ABS/App_Common/App_Common_location.txt"
    debug_log "$LINENO" "Checking for file: $app_common_location_file"

    if [ -f "$app_common_location_file" ]; then
        info_log "$LINENO" "'$app_common_location_file' found. Syncing SBSFU.elf to application."

        # Read the path from the file
        app_common_path_from_file=$(cat "$app_common_location_file")
        debug_log "$LINENO" "Path read from file: $app_common_path_from_file"

        # Resolve the path to be absolute, handling both absolute and relative paths.
        case "$app_common_path_from_file" in
            /*) # Absolute path for POSIX
                app_common_dir_abs_temp="$app_common_path_from_file"
                ;;
            [a-zA-Z]:*) # Absolute path for Windows (e.g., C:...)
                app_common_dir_abs_temp="$app_common_path_from_file"
                ;;
            *) # Relative path, assumed to be relative to the config file's location.
                app_common_dir_abs_temp="$COMMON_DIR_ABS/App_Common/$app_common_path_from_file"
                ;;
        esac
        debug_log "$LINENO" "Temporary resolved path: $app_common_dir_abs_temp"

        # First, check if the resolved directory exists BEFORE trying to 'cd' into it.
        if [ ! -d "$app_common_dir_abs_temp" ]; then
            error_log "$LINENO" "Application Common directory '$app_common_dir_abs_temp' specified in file does not exist. Skipping copy."
        else
            # Now it's safe to normalize the path to get its canonical absolute name.
            app_common_dir_abs="$(cd "$app_common_dir_abs_temp" && pwd)"
            debug_log "$LINENO" "Final Resolved Application Common Dir: $app_common_dir_abs"

            # Define target directory for the app and create it
            app_dest_dir_abs="$app_common_dir_abs/$BUILD_MODE"
            info_log "$LINENO" "Ensuring application artifacts directory exists: $app_dest_dir_abs"
            mkdir -p "$app_dest_dir_abs"

            # Copy the ELF file
            info_log "$LINENO" "Copying SBSFU.elf to application's common directory."
            cp "$DEST_DIR_ABS/SBSFU.elf" "$app_dest_dir_abs/"
            debug_log "$LINENO" "Copied 'SBSFU.elf' to '$app_dest_dir_abs/'"
        fi
    else
        debug_log "$LINENO" "'$app_common_location_file' not found. No application-specific sync needed."
    fi

    info_log "$LINENO" "Post-build script finished successfully."
    exit 0
}

# --- Execute Main Function ---
main "$@"
