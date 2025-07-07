#!/bin/sh

# ==============================================================================
#
# Pre-build Script for Secure Engine (SE) - POSIX sh Compliant
#
# Description:
#   This script prepares the necessary files for the Secure Engine build.
#   It is written to be compatible with the POSIX 'sh' standard.
#
# Usage: "../Scripts/prebuild.sh" "../../Common" 3 3 3
#
# Usage: $0 <Common Directory> [Log Info Mode] [Log Debug Mode] [Log Error Mode]"
#
## ==============================================================================

# --- Script Configuration ---

# Exit on error or unset variable to prevent unexpected behavior
set -e
set -u

# --- Function Definitions ---

# Print usage information and exit
usage() {
    echo "Usage: $0 <Common Directory> [Log Info Mode] [Log Debug Mode] [Log Error Mode]"
    echo "  Log Modes (optional, default to 1): 1=console, 2=file, 3=both"
    exit 1
}

# Log an error message and exit
error_exit() {
    # $1: Line number, $2: Error message
    error_log "$1" "$2"
    echo "Press any key to continue..."
    # 'read' might fail in a non-interactive script, '|| true' prevents exit
    read -r _ || true
    exit 1
}

# --- Logging Functions (Separate for POSIX compatibility) ---

info_log() {
    # $1: Line number, $2: Message
    message="[LINE $1 - INFO] $2"
    case "$LOG_INFO_MODE" in
        1) echo "$message";;
        2) echo "$message" >> "$LOG_INFO_FILE";;
        3) echo "$message" | tee -a "$LOG_INFO_FILE";;
    esac
}

debug_log() {
    # $1: Line number, $2: Message
    message="[LINE $1 - DEBUG] $2"
    case "$LOG_DEBUG_MODE" in
        1) echo "$message";;
        2) echo "$message" >> "$LOG_DEBUG_FILE";;
        3) echo "$message" | tee -a "$LOG_DEBUG_FILE";;
    esac
}

error_log() {
    # $1: Line number, $2: Message
    message="[LINE $1 - ERROR] $2"
    case "$LOG_ERROR_MODE" in
        1) echo "$message";;
        2) echo "$message" >> "$LOG_ERROR_FILE";;
        3) echo "$message" | tee -a "$LOG_ERROR_FILE";;
    esac
}

# --- Main Script Logic ---

main() {
    # --- 1. Argument Parsing and Validation ---

    if [ $# -lt 1 ]; then
        echo "Error: Missing mandatory arguments."
        usage
    fi

    # Determine project directory from script's location
    # The script is in <Project_Dir>/Scripts, so we go up one level
    SCRIPT_DIR=$(dirname "$0")
    debug_log "$LINENO" "SCRIPT_DIR: $SCRIPT_DIR"
    PROJECT_DIR_ABS="$(cd "$SCRIPT_DIR/.." && pwd)"
    debug_log "$LINENO" "PROJECT_DIR_ABS: $PROJECT_DIR_ABS"

    # POSIX-compliant way to get absolute path for Common Directory
    COMMON_DIR_ABS="$(cd "$1" && pwd)"
    debug_log "$LINENO" "COMMON_DIR_ABS: $COMMON_DIR_ABS"

    # Validate that directories exist
    if [ ! -d "$PROJECT_DIR_ABS" ]; then
        echo "[ERROR] Project Directory '$PROJECT_DIR_ABS' (derived from script location) does not exist."
        exit 1
    fi
    if [ ! -d "$COMMON_DIR_ABS" ]; then
        echo "[ERROR] Common Directory '$1' does not exist."
        exit 1
    fi

    # --- 2. Logging Setup ---

    OUTPUT_DIR_ABS="$PROJECT_DIR_ABS/Output"
    LOG_INFO_FILE="$OUTPUT_DIR_ABS/info.log"
    LOG_DEBUG_FILE="$OUTPUT_DIR_ABS/debug.log"
    LOG_ERROR_FILE="$OUTPUT_DIR_ABS/error.log"

    # Assign logging modes from parameters with defaults (POSIX compliant)
    LOG_INFO_MODE=${2:-1}
    LOG_DEBUG_MODE=${3:-1}
    LOG_ERROR_MODE=${4:-1}

    # Validate log modes
    for mode in "$LOG_INFO_MODE" "$LOG_DEBUG_MODE" "$LOG_ERROR_MODE"; do
        case "$mode" in
            [1-3]) ;; # Valid
            *)
                echo "[ERROR] Invalid log mode '$mode'. Must be 1, 2, or 3."
                usage
                ;;
        esac
    done

    # Create output directory and clear previous logs
    mkdir -p "$OUTPUT_DIR_ABS"
    # The ':' command is a POSIX no-op, used here to truncate files
    : > "$LOG_INFO_FILE"
    : > "$LOG_DEBUG_FILE"
    : > "$LOG_ERROR_FILE"

    info_log "$LINENO" "prebuild.sh started."
    debug_log "$LINENO" "Project Dir: $PROJECT_DIR_ABS"
    debug_log "$LINENO" "Common Dir:  $COMMON_DIR_ABS"
    debug_log "$LINENO" "Log Modes (I/D/E): $LOG_INFO_MODE/$LOG_DEBUG_MODE/$LOG_ERROR_MODE"
    debug_log "$LINENO" "OUTPUT_DIR_ABS: $OUTPUT_DIR_ABS"
    debug_log "$LINENO" "LOG_INFO_FILE: $LOG_INFO_FILE"
    debug_log "$LINENO" "LOG_DEBUG_FILE: $LOG_DEBUG_FILE"
    debug_log "$LINENO" "LOG_ERROR_FILE: $LOG_ERROR_FILE"

    # --- 3. Directory and Path Validation ---

    # Validate required source subdirectories in Common
    for dir in "Binary_Keys" "KeysAndImages_Util" "Linker"; do
        if [ ! -d "$COMMON_DIR_ABS/$dir" ]; then
            error_exit "$LINENO" "Required source directory '$COMMON_DIR_ABS/$dir' not found."
        fi
    done
    debug_log "$LINENO" "All required Common source sub-directories are present."

    # Define key paths
    scripts_dir_abs="$PROJECT_DIR_ABS/Scripts"
    common_scripts_dir_abs="$COMMON_DIR_ABS/Scripts"
    common_image_util_dir_abs="$COMMON_DIR_ABS/KeysAndImages_Util"
    common_binary_keys_dir_abs="$COMMON_DIR_ABS/Binary_Keys"
    common_startup_dir_abs="$COMMON_DIR_ABS/Startup"
    crypto_header_file="$PROJECT_DIR_ABS/Application/Core/Inc/se_crypto_config.h"
    asm_file="$common_startup_dir_abs/se_key.s"
    debug_log "$LINENO" "scripts_dir_abs: $scripts_dir_abs"
    debug_log "$LINENO" "common_scripts_dir_abs: $common_scripts_dir_abs"
    debug_log "$LINENO" "common_image_util_dir_abs: $common_image_util_dir_abs"
    debug_log "$LINENO" "common_binary_keys_dir_abs: $common_binary_keys_dir_abs"
    debug_log "$LINENO" "common_startup_dir_abs: $common_startup_dir_abs"
    debug_log "$LINENO" "crypto_header_file: $crypto_header_file"
    debug_log "$LINENO" "asm_file: $asm_file"

    # --- 4. Toolchain Setup (Python/Exe) ---

    prepare_image_exe="$common_image_util_dir_abs/win/prepareimage/prepareimage.exe"
    prepare_image_py="$common_image_util_dir_abs/prepareimage.py"
    prepare_image_path=""
    python_cmd=""
    debug_log "$LINENO" "prepare_image_exe: $prepare_image_exe"
    debug_log "$LINENO" "prepare_image_py: $prepare_image_py"

    # Check for uname and grep, as they might not be on all minimal systems
    if command -v uname >/dev/null 2>&1 && command -v grep >/dev/null 2>&1; then
        # POSIX compliant check for Windows-like environments
        if uname -s | grep -q -E 'MINGW|CYGWIN|Windows_NT'; then
            is_windows=true
        else
            is_windows=false
        fi
    else
        is_windows=false # Assume not windows if tools are missing
    fi
    debug_log "$LINENO" "is_windows: $is_windows"

    if [ "$is_windows" = true ] && [ -f "$prepare_image_exe" ]; then
        info_log "$LINENO" "Using Windows executable for prepareimage."
        prepare_image_path="$prepare_image_exe"
    else
        info_log "$LINENO" "Using Python script for prepareimage."
        if [ "$is_windows" = true ]; then
            python_cmd="python"
        else
            python_cmd="python3"
        fi
        prepare_image_path="$prepare_image_py"
        debug_log "$LINENO" "Python command set to: $python_cmd"
    fi
    debug_log "$LINENO" "PrepareImage path: $prepare_image_path"

    # --- 5. Cleanup Previous Artifacts ---

    info_log "$LINENO" "Cleaning up previous build artifacts..."
    # Ensure target directories exist before attempting to remove files from them
    mkdir -p "$common_startup_dir_abs"
    mkdir -p "$common_scripts_dir_abs"
    rm -f "$OUTPUT_DIR_ABS/crypto.txt" "$asm_file" "$common_scripts_dir_abs/postbuild.sh"

    # --- 6. Determine Crypto Scheme ---

    info_log "$LINENO" "Determining crypto scheme from $(basename "$crypto_header_file")..."
    crypto_scheme=""
    if [ -n "$python_cmd" ]; then
        crypto_scheme=$($python_cmd "$prepare_image_path" conf "$crypto_header_file")
    else
        crypto_scheme=$("$prepare_image_path" conf "$crypto_header_file")
    fi

    if [ -z "$crypto_scheme" ]; then
        error_exit "$LINENO" "Failed to determine crypto scheme. 'prepareimage' returned empty."
    fi
    echo "$crypto_scheme" > "$OUTPUT_DIR_ABS/crypto.txt"
    info_log "$LINENO" "Crypto scheme selected: $crypto_scheme"
    debug_log "$LINENO" "crypto_scheme: $crypto_scheme"

    # --- 7. Generate Assembly Key File ---

    info_log "$LINENO" "Generating assembly key file: $(basename "$asm_file")"
    cortex_arch="V7M"
    debug_log "$LINENO" "cortex_arch: $cortex_arch"
    # Create header for the assembly file using POSIX compliant here-document
    cat > "$asm_file" <<EOF
	.section .SE_Key_Data,"a",%progbits
	.syntax unified
	.thumb
EOF

    # Function to run prepareimage for key translation
    run_prepare_image_trans() {
        if [ -n "$python_cmd" ]; then
            # Use sh -c to handle arguments correctly
            sh -c "$python_cmd '$prepare_image_path' trans $*" >> "$asm_file"
        else
            "$prepare_image_path" trans "$@" >> "$asm_file"
        fi
    }

    # Append AES keys if applicable
    aes_type=""
    if [ "$crypto_scheme" = "SECBOOT_AES128_GCM_AES128_GCM_AES128_GCM" ]; then
        aes_type="GCM"
    elif [ "$crypto_scheme" = "SECBOOT_ECCDSA_WITH_AES128_CBC_SHA256" ]; then
        aes_type="CBC"
    fi
    debug_log "$LINENO" "aes_type: $aes_type"

    if [ -n "$aes_type" ]; then
        debug_log "$LINENO" "Processing AES keys of type: $aes_type"
        for i in 1 2 3; do
            oem_key_file="$common_binary_keys_dir_abs/OEM_KEY_COMPANY${i}_key_AES_${aes_type}.bin"
            debug_log "$LINENO" "oem_key_file: $oem_key_file"
            if [ -f "$oem_key_file" ]; then
                info_log "$LINENO" "Adding OEM Key $i from $(basename "$oem_key_file")"
                run_prepare_image_trans -a GNU -k "$oem_key_file" -f "SE_ReadKey_${i}" -v "$cortex_arch"
            fi
        done
    fi

    # Append ECC public keys if applicable
    if echo "$crypto_scheme" | grep -q "ECCDSA"; then
        debug_log "$LINENO" "Processing ECC public keys."
        for i in 1 2 3; do
            ecc_key_file="$common_binary_keys_dir_abs/ECCKEY${i}.txt"
            debug_log "$LINENO" "ecc_key_file: $ecc_key_file"
            if [ -f "$ecc_key_file" ]; then
                info_log "$LINENO" "Adding ECC Public Key $i from $(basename "$ecc_key_file")"
                run_prepare_image_trans -a GNU -k "$ecc_key_file" -f "SE_ReadKey_${i}_Pub" -v "$cortex_arch"
            fi
        done
    fi

    echo "    .end" >> "$asm_file"
    info_log "$LINENO" "Assembly key file generation complete."

    # --- 8. Setup Post-Build Script ---

    info_log "$LINENO" "Setting up post-build script..."
    post_build_source="$scripts_dir_abs/$crypto_scheme.sh"
    post_build_target="$common_scripts_dir_abs/postbuild.sh"
    debug_log "$LINENO" "post_build_source: $post_build_source"
    debug_log "$LINENO" "post_build_target: $post_build_target"

    if [ ! -f "$post_build_source" ]; then
        error_exit "$LINENO" "Post-build script source not found at '$post_build_source'"
    fi

    # On Windows, create a copy. On others, create a symbolic link.
    if [ "$is_windows" = true ]; then
        info_log "$LINENO" "Copying '$post_build_source' to '$post_build_target'"
        cp "$post_build_source" "$post_build_target"
    else
        info_log "$LINENO" "Creating symbolic link from '$post_build_source' to '$post_build_target'"
        # -f ensures we overwrite any existing link
        ln -sf "$post_build_source" "$post_build_target"
    fi

    info_log "$LINENO" "Pre-build script finished successfully."
    exit 0
}

# --- Execute Main Function ---
main "$@"
