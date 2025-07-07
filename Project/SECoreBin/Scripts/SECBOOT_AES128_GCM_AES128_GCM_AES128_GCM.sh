#!/bin/sh
# ==============================================================================
#
# POST-BUILD SCRIPT for SECBOOT_AES128_GCM_WITH_AES128_GCM
#
# This script is designed to be run after the build process of the SBSFU project.
# It performs the following tasks:
# 1. Validates input arguments and assigns them to relative variables.
# 2. Converts all paths to absolute paths and logs them.
# 3. Validates the project structure.
# 4. Defines all file variables with absolute paths and logs them.
# 5. Selects the appropriate prepareimage tool based on the platform.
# 6. Executes the main flow of the script, which includes:
#    - Encrypting the binary file.
#    - Signing the binary file.
#    - Packing the SFB file.
#    - Creating the header binary file.
#    - Merging to create the big binary file.
#    - Optionally generating a partial image if a reference user app exists.
# 7. Handles errors and provides verbose output for debugging.
#
# arg1 is the build directory
# arg2 is the elf file path+name
# arg3 is the bin file path+name
# arg4 is the firmware Id (1/2/3)
# arg5 is the version

# arg9 when present forces "bigelf" generation
#
# ==============================================================================

# --- 1. SCRIPT CONFIGURATION ---

# Step 1: Default to console output only
LOG_INFO_MODE=1
LOG_DEBUG_MODE=1
LOG_ERROR_MODE=1

# Convert project directory to absolute path immediately
PROJECT_DIR_REL="$1"

if [ ! -d "$PROJECT_DIR_REL" ]; then
    echo "[ERROR] Project directory '$PROJECT_DIR_REL' does not exist."
    exit 1
fi

PROJECT_DIR_ABS=$(cd "$PROJECT_DIR_REL" && pwd)

# Initialize log files in Output directory under absolute project path
OUTPUT_DIR="${PROJECT_DIR_ABS}/Output"
LOG_INFO_FILE="${OUTPUT_DIR}/info.log"
LOG_DEBUG_FILE="${OUTPUT_DIR}/debug.log"
LOG_ERROR_FILE="${OUTPUT_DIR}/error.log"

mkdir -p "$OUTPUT_DIR"
: > "$LOG_INFO_FILE"
: > "$LOG_DEBUG_FILE"
: > "$LOG_ERROR_FILE"

# Step 2: Now update logging modes from parameters (if provided)
LOG_INFO_MODE=${6:-$LOG_INFO_MODE}
LOG_DEBUG_MODE=${7:-$LOG_DEBUG_MODE}
LOG_ERROR_MODE=${8:-$LOG_ERROR_MODE}

# --- 2. HELPER FUNCTION ---


# --- Logging Functions ---
debug_log() {
    local message="[LINE $1 - DEBUG] $2"
    case $LOG_DEBUG_MODE in
        1) echo -e "$message";;
        2) echo -e "$message" >> "$LOG_DEBUG_FILE";;
        3) echo -e "$message" | tee -a "$LOG_DEBUG_FILE";;
        *) ;;
    esac
}

info_log() {
    local message="[LINE $1 - INFO] $2"
    case $LOG_INFO_MODE in
        1) echo -e "$message";;
        2) echo -e "$message" >> "$LOG_INFO_FILE";;
        3) echo -e "$message" | tee -a "$LOG_INFO_FILE";;
        *) ;;
    esac
}

error_log() {
    local message="[LINE $1 - ERROR] $2"
    case $LOG_ERROR_MODE in
        1) echo -e "$message";;
        2) echo -e "$message" >> "$LOG_ERROR_FILE";;
        3) echo -e "$message" | tee -a "$LOG_ERROR_FILE";;
        *) ;;
    esac
}


# --- 3. SCRIPT BODY ---
info_log $LINENO "--- Post-Build Script Started ---"

# --- STEP A: VALIDATION AND INITIAL VARIABLE ASSIGNMENT ---
info_log $LINENO "Validating arguments and assigning initial relative variables..."

if [ "$#" -lt 8 ]; then
  error_log $LINENO "ERROR: At least 8 arguments are required."
  error_log $LINENO "Usage: $0 <build_dir> <elf_file> <bin_file> <fw_id> <version> <log_info_mode> <log_debug_mode> <log_error_mode> [<force_bigelf>]"
  exit 1
fi

# Store and log relative arguments
PROJECT_DIR_REL="$1"
debug_log $LINENO "Relative Arg 1 (Project Dir): \"$PROJECT_DIR_REL\""
ELF_FILE="$2"
debug_log $LINENO "Relative Arg 2 (ELF File): \"$ELF_FILE\""
BIN_FILE_REL="$3"
debug_log $LINENO "Relative Arg 3 (BIN File): \"$BIN_FILE_REL\""
FW_ID="$4"
debug_log $LINENO "Relative Arg 4 (FW ID): \"$FW_ID\""
VERSION="$5"
debug_log $LINENO "Relative Arg 5 (Version): \"$VERSION\""

if [ "$#" -eq 9 ]; then
  FORCE_BIGELF=1
  debug_log $LINENO "Relative Arg 6 detected: 'force_bigelf' is enabled."
else
  FORCE_BIGELF=0
fi

# --- STEP B: CONVERT ALL PATHS TO ABSOLUTE AND LOG THEM ---
debug_log $LINENO "Converting all paths to absolute and logging them..."

COMMON_ABS_DIR=$(cd "$(dirname "$(dirname "$0")")" && pwd)
debug_log $LINENO "Common Directory (Absolute): \"$COMMON_ABS_DIR\""

PROJECT_DIR_ABS=$(cd "$PROJECT_DIR_REL" && pwd)
debug_log $LINENO "Project Build Directory (Absolute): \"$PROJECT_DIR_ABS\""


BIN_NAME="${3##*/}"
debug_log $LINENO "bin file name: \"$BIN_NAME\""


BIN_DIR_REL="$(dirname "$3")"
debug_log $LINENO "bin file Directory (Reletive): \"$BIN_DIR_REL\""



BIN_FILE_ABS=$(cd "$BIN_DIR_REL" && pwd)/"$BIN_NAME"
debug_log $LINENO "BIN File (Absolute): \"$BIN_FILE_ABS\""



BINARY_OUTPUT_DIR_ABS=$(cd "$PROJECT_DIR_ABS/../Binary" && pwd)
debug_log $LINENO "Binary Output Directory (Absolute): \"$BINARY_OUTPUT_DIR_ABS\""

KEYS_AND_IMAGES_DIR_ABS=$(cd "$COMMON_ABS_DIR/KeysAndImages_Util" && pwd)
debug_log $LINENO "Keys/Images Util Directory (Absolute): \"$KEYS_AND_IMAGES_DIR_ABS\""

SBSFU_ELF_ABS=$(cd "$COMMON_ABS_DIR/Debug" && pwd)/SBSFU.elf
debug_log $LINENO "SBSFU ELF (Absolute): \"$SBSFU_ELF_ABS\""

REF_USER_APP_ABS="$PROJECT_DIR_ABS/RefUserApp.bin"
debug_log $LINENO "Reference User App (Absolute): \"$REF_USER_APP_ABS\""


# --- STEP C: PROJECT STRUCTURE VALIDATION ---
info_log $LINENO "Validating project structure using absolute paths..."
if [ ! -d "$KEYS_AND_IMAGES_DIR_ABS" ]; then
  info_log $LINENO "ERROR: Required directory for 'prepareimage' tool does not exist at "$KEYS_AND_IMAGES_DIR_ABS"."
  exit 1
fi


if [ ! -d "$COMMON_ABS_DIR"/Binary_Keys ]; then
  info_log $LINENO Common Directory "$COMMON_ABS_DIR"/Binary_Keys does not exist.
  exit 1
fi


if [ ! -d "$COMMON_ABS_DIR"/Scripts ]; then
  info_log $LINENO Common Directory "$COMMON_ABS_DIR"/Scripts does not exist.
  exit 1
fi


info_log $LINENO "Project structure validation successful."

# --- STEP D: DEFINE FILE VARIABLES AND LOG THEM ---
info_log $LINENO "Defining all file variables with absolute paths and logging them..."

EXEC_NAME=$(basename "$BIN_FILE_ABS" .bin)
debug_log $LINENO "Executable Name: \"$EXEC_NAME\""
SFU_FILE_ABS="${BINARY_OUTPUT_DIR_ABS}/${EXEC_NAME}.sfu"
debug_log $LINENO "SFU File (Absolute): \"$SFU_FILE_ABS\""
SFB_FILE_ABS="${BINARY_OUTPUT_DIR_ABS}/${EXEC_NAME}.sfb"
debug_log $LINENO "SFB File (Absolute): \"$SFB_FILE_ABS\""
SIGN_FILE_ABS="${BINARY_OUTPUT_DIR_ABS}/${EXEC_NAME}.sign"
debug_log $LINENO "SIGN File (Absolute): \"$SIGN_FILE_ABS\""
HEADER_BIN_ABS="${BINARY_OUTPUT_DIR_ABS}/${EXEC_NAME}sfuh.bin"
debug_log $LINENO "Header BIN File (Absolute): \"$HEADER_BIN_ABS\""
BIGBINARY_ABS="${BINARY_OUTPUT_DIR_ABS}/SBSFU_${EXEC_NAME}.bin"
debug_log $LINENO "Big Binary File (Absolute): \"$BIGBINARY_ABS\""
NONCE_FILE_ABS="${COMMON_ABS_DIR}/Binary_Keys/nonce.bin"
debug_log $LINENO "Nonce File (Absolute): \"$NONCE_FILE_ABS\""
OEM_KEY_ABS="${COMMON_ABS_DIR}/Binary_Keys/OEM_KEY_COMPANY${FW_ID}_key_AES_GCM.bin"
debug_log $LINENO "OEM Key File (Absolute): \"$OEM_KEY_ABS\""
MAGIC="SFU${FW_ID}"
debug_log $LINENO "Magic: \"$MAGIC\""

OFFSET=512
debug_log $LINENO "Offset: \"$OFFSET\""
ALIGNMENT=16
debug_log $LINENO "Alignment: \"$ALIGNMENT\""


PARTIAL_BIN_ABS="${BINARY_OUTPUT_DIR_ABS}/Partial${EXEC_NAME}.bin"
debug_log $LINENO "Partial BIN File (Absolute): \"$PARTIAL_BIN_ABS\""
PARTIAL_SFU_ABS="${BINARY_OUTPUT_DIR_ABS}/Partial${EXEC_NAME}.sfu"
debug_log $LINENO "Partial SFU File (Absolute): \"$PARTIAL_SFU_ABS\""
PARTIAL_SIGN_ABS="${BINARY_OUTPUT_DIR_ABS}/Partial${EXEC_NAME}.sign"
debug_log $LINENO "Partial SIGN File (Absolute): \"$PARTIAL_SIGN_ABS\""
PARTIAL_SFB_ABS="${BINARY_OUTPUT_DIR_ABS}/Partial${EXEC_NAME}.sfb"
debug_log $LINENO "Partial SFB File (Absolute): \"$PARTIAL_SFB_ABS\""
PARTIAL_OFFSET_ABS="${BINARY_OUTPUT_DIR_ABS}/Partial${EXEC_NAME}.offset"
debug_log $LINENO "Partial Offset File (Absolute): \"$PARTIAL_OFFSET_ABS\""


# --- STEP E: SELECT PREPAREIMAGE TOOL ---
info_log $LINENO "Detecting platform to select prepareimage tool..."
PREPARE_IMAGE_CMD="python"
PREPARE_IMAGE_SCRIPT="\"${KEYS_AND_IMAGES_DIR_ABS}/prepareimage.py\""


# test if window executable usable


if uname | grep -i -e windows -e mingw >/dev/null 2>&1 && [ -f "${KEYS_AND_IMAGES_DIR_ABS}/win/prepareimage/prepareimage.exe" ]; then
    info_log $LINENO "Windows environment detected. Using prepareimage.exe"
    PREPARE_IMAGE_CMD="${KEYS_AND_IMAGES_DIR_ABS}/win/prepareimage/prepareimage.exe"
    PREPARE_IMAGE_SCRIPT=""
else
    info_log $LINENO "Linux/macOS or no .exe found. Using python script."
fi
debug_log $LINENO "Prepareimage command set to: $PREPARE_IMAGE_CMD"
debug_log $LINENO "Prepareimage script set to: $PREPARE_IMAGE_SCRIPT"

# --- STEP F: MAIN EXECUTION FLOW (with nested ifs) ---
debug_log $LINENO "Ensuring Binary output directory exists..."
mkdir -p "$BINARY_OUTPUT_DIR_ABS"
ret=$?
if [ $ret -eq 0 ]; then
  # Convert paths to Unix format for the tool
  info_log $LINENO "Converting paths to UNIX format for the tool..."
  BIN_FILE_UNIX=$(echo "$BIN_FILE_ABS" | sed 's/\\/\//g')
  debug_log $LINENO "UNIX-formatted BIN File: \"$BIN_FILE_UNIX\""
  SFU_FILE_UNIX=$(echo "$SFU_FILE_ABS" | sed 's/\\/\//g')
  debug_log $LINENO "UNIX-formatted SFU File: \"$SFU_FILE_UNIX\""
  SIGN_FILE_UNIX=$(echo "$SIGN_FILE_ABS" | sed 's/\\/\//g')
  debug_log $LINENO "UNIX-formatted SIGN File: \"$SIGN_FILE_UNIX\""
  SFB_FILE_UNIX=$(echo "$SFB_FILE_ABS" | sed 's/\\/\//g')
  debug_log $LINENO "UNIX-formatted SFB File: \"$SFB_FILE_UNIX\""
  HEADER_BIN_UNIX=$(echo "$HEADER_BIN_ABS" | sed 's/\\/\//g')
  debug_log $LINENO "UNIX-formatted Header BIN File: \"$HEADER_BIN_UNIX\""
  BIGBINARY_UNIX=$(echo "$BIGBINARY_ABS" | sed 's/\\/\//g')
  debug_log $LINENO "UNIX-formatted Big Binary File: \"$BIGBINARY_UNIX\""
  OEM_KEY_UNIX=$(echo "$OEM_KEY_ABS" | sed 's/\\/\//g')
  debug_log $LINENO "UNIX-formatted OEM Key File: \"$OEM_KEY_UNIX\""
  NONCE_UNIX=$(echo "$NONCE_FILE_ABS" | sed 's/\\/\//g')
  debug_log $LINENO "UNIX-formatted Nonce File: \"$NONCE_UNIX\""
  SBSFU_ELF_UNIX=$(echo "$SBSFU_ELF_ABS" | sed 's/\\/\//g')
  debug_log $LINENO "UNIX-formatted SBSFU ELF File: \"$SBSFU_ELF_UNIX\""

  info_log $LINENO "1. Encrypting binary..."
  command="\"$PREPARE_IMAGE_CMD\"\"$PREPARE_IMAGE_SCRIPT\" enc -k \"$OEM_KEY_UNIX\" -n \"$NONCE_UNIX\" \"$BIN_FILE_UNIX\" \"$SFU_FILE_UNIX\""
  debug_log $LINENO "EXECUTING: $command"
  "$PREPARE_IMAGE_CMD""$PREPARE_IMAGE_SCRIPT" enc -k "$OEM_KEY_UNIX" -n "$NONCE_UNIX" "$BIN_FILE_UNIX" "$SFU_FILE_UNIX" > "$PROJECT_DIR_ABS"/output.txt
  ret=$?
if [ $ret -eq 0 ]; then
  info_log $LINENO "2. Signing binary..."
  command="\"$PREPARE_IMAGE_CMD\"\"$PREPARE_IMAGE_SCRIPT\" sign -k \"$OEM_KEY_UNIX\" -n \"$NONCE_UNIX\" \"$BIN_FILE_UNIX\" \"$SIGN_FILE_UNIX\""
  debug_log $LINENO "EXECUTING: $command"
  "$PREPARE_IMAGE_CMD""$PREPARE_IMAGE_SCRIPT" sign -k "$OEM_KEY_UNIX" -n "$NONCE_UNIX" "$BIN_FILE_UNIX" "$SIGN_FILE_UNIX" > "$PROJECT_DIR_ABS"/output.txt
  ret=$?
    if [ $ret -eq 0 ]; then
      info_log $LINENO "3. Packing SFB file..."
      command="\"$PREPARE_IMAGE_CMD\"\"$PREPARE_IMAGE_SCRIPT\" pack -m \"$MAGIC\" -k \"$OEM_KEY_UNIX\" -r 112 -v \"$VERSION\" -n \"$NONCE_UNIX\" -f \"$SFU_FILE_UNIX\" -t \"$SIGN_FILE_UNIX\" \"$SFB_FILE_UNIX\" -o \"$OFFSET\""
      debug_log $LINENO "EXECUTING: $command"
      "$PREPARE_IMAGE_CMD""$PREPARE_IMAGE_SCRIPT" pack -m "$MAGIC" -k "$OEM_KEY_UNIX" -r 112 -v "$VERSION" -n "$NONCE_UNIX" -f "$SFU_FILE_UNIX" -t "$SIGN_FILE_UNIX" "$SFB_FILE_UNIX" -o "$OFFSET" >> "$PROJECT_DIR_ABS"/output.txt
      ret=$?
      if [ $ret -eq 0 ]; then
        info_log $LINENO "4. Creating header binary..."
        command="\"$PREPARE_IMAGE_CMD\"\"$PREPARE_IMAGE_SCRIPT\" header -m \"$MAGIC\" -k \"$OEM_KEY_UNIX\" -r 112 -v \"$VERSION\" -n \"$NONCE_UNIX\" -f \"$SFU_FILE_UNIX\" -t \"$SIGN_FILE_UNIX\" -o \"$OFFSET\" \"$HEADER_BIN_UNIX\""
        debug_log $LINENO "EXECUTING: $command"
        "$PREPARE_IMAGE_CMD""$PREPARE_IMAGE_SCRIPT" header -m "$MAGIC" -k "$OEM_KEY_UNIX" -r 112 -v "$VERSION" -n "$NONCE_UNIX" -f "$SFU_FILE_UNIX" -t "$SIGN_FILE_UNIX" -o "$OFFSET" "$HEADER_BIN_UNIX" >> "$PROJECT_DIR_ABS"/output.txt
        ret=$?
        if [ $ret -eq 0 ]; then
          info_log $LINENO "5. Merging to create big binary..."
          command="\"$PREPARE_IMAGE_CMD\"\"$PREPARE_IMAGE_SCRIPT\" merge -v 0 -e 1 -i \"$HEADER_BIN_UNIX\" -s \"$SBSFU_ELF_UNIX\" -u \"$ELF_FILE\" \"$BIGBINARY_UNIX\""
          debug_log $LINENO "EXECUTING: $command"
          "$PREPARE_IMAGE_CMD""$PREPARE_IMAGE_SCRIPT" merge -v 0 -e 1 -i "$HEADER_BIN_UNIX" -s "$SBSFU_ELF_UNIX" -u "$ELF_FILE" "$BIGBINARY_UNIX" >> "$PROJECT_DIR_ABS"/output.txt
          ret=$?
          if [ $ret -eq 0 ]; then
            # Partial image generation if reference userapp exists
            info_log $LINENO "Checking for partial image generation..."
            if [ -f "$REF_USER_APP_ABS" ]; then
              info_log $LINENO "Reference user app found. Starting partial image generation."

              PARTIAL_BIN_UNIX=$(echo "$PARTIAL_BIN_ABS" | sed 's/\\/\//g')
              debug_log $LINENO "UNIX-formatted Partial BIN File: \"$PARTIAL_BIN_UNIX\""
              PARTIAL_OFFSET_UNIX=$(echo "$PARTIAL_OFFSET_ABS" | sed 's/\\/\//g')
              debug_log $LINENO "UNIX-formatted Partial Offset File: \"$PARTIAL_OFFSET_UNIX\""
              PARTIAL_SFU_UNIX=$(echo "$PARTIAL_SFU_ABS" | sed 's/\\/\//g')
              debug_log $LINENO "UNIX-formatted Partial SFU File: \"$PARTIAL_SFU_UNIX\""
              PARTIAL_SIGN_UNIX=$(echo "$PARTIAL_SIGN_ABS" | sed 's/\\/\//g')
              debug_log $LINENO "UNIX-formatted Partial SIGN File: \"$PARTIAL_SIGN_UNIX\""
              PARTIAL_SFB_UNIX=$(echo "$PARTIAL_SFB_ABS" | sed 's/\\/\//g')
              debug_log $LINENO "UNIX-formatted Partial SFB File: \"$PARTIAL_SFB_UNIX\""
              REF_USER_APP_UNIX=$(echo "$REF_USER_APP_ABS" | sed 's/\\/\//g')
              debug_log $LINENO "UNIX-formatted Reference User App File: \"$REF_USER_APP_UNIX\""

              info_log $LINENO "6a. Creating diff..."
              command="\"$PREPARE_IMAGE_CMD\"\"$PREPARE_IMAGE_SCRIPT\" diff -1 \"$REF_USER_APP_UNIX\" -2 \"$BIN_FILE_UNIX\" \"$PARTIAL_BIN_UNIX\" -a \"$ALIGNMENT\" --poffset \"$PARTIAL_OFFSET_UNIX\""
              debug_log $LINENO "EXECUTING: $command"
              "$PREPARE_IMAGE_CMD""$PREPARE_IMAGE_SCRIPT" diff -1 "$REF_USER_APP_UNIX" -2 "$BIN_FILE_UNIX" "$PARTIAL_BIN_UNIX" -a "$ALIGNMENT" --poffset "$PARTIAL_OFFSET_UNIX" >> "$PROJECT_DIR_ABS"/output.txt
              ret=$?
              if [ $ret -eq 0 ]; then
                info_log $LINENO "6b. Encrypting partial binary..."
                command="\"$PREPARE_IMAGE_CMD\"\"$PREPARE_IMAGE_SCRIPT\" enc -k \"$OEM_KEY_UNIX\" -n \"$NONCE_UNIX\" \"$PARTIAL_BIN_UNIX\" \"$PARTIAL_SFU_UNIX\""
                debug_log $LINENO "EXECUTING: $command"
                "$PREPARE_IMAGE_CMD""$PREPARE_IMAGE_SCRIPT" enc -k "$OEM_KEY_UNIX" -n "$NONCE_UNIX" "$PARTIAL_BIN_UNIX" "$PARTIAL_SFU_UNIX" >> "$PROJECT_DIR_ABS"/output.txt
                ret=$?
                if [ $ret -eq 0 ]; then
                  info_log $LINENO "6c. Signing partial binary..."
                  command="\"$PREPARE_IMAGE_CMD\"\"$PREPARE_IMAGE_SCRIPT\" sign -k \"$OEM_KEY_UNIX\" -n \"$NONCE_UNIX\" \"$PARTIAL_BIN_UNIX\" \"$PARTIAL_SIGN_UNIX\""
                  debug_log $LINENO "EXECUTING: $command"
                  "$PREPARE_IMAGE_CMD""$PREPARE_IMAGE_SCRIPT" sign -k "$OEM_KEY_UNIX" -n "$NONCE_UNIX" "$PARTIAL_BIN_UNIX" "$PARTIAL_SIGN_UNIX" >> "$PROJECT_DIR_ABS"/output.txt
                  ret=$?
                  if [ $ret -eq 0 ]; then
                    info_log $LINENO "6d. Packing partial SFB..."
                    command="\"$PREPARE_IMAGE_CMD\"\"$PREPARE_IMAGE_SCRIPT\" pack -m \"$MAGIC\" -k \"$OEM_KEY_UNIX\" -r 112 -v \"$VERSION\" -n \"$NONCE_UNIX\" -f \"$SFU_FILE_UNIX\" -t \"$SIGN_FILE_UNIX\" -o 512 --pfw \"$PARTIAL_SFU_UNIX\" --ptag \"$PARTIAL_SIGN_UNIX\" --poffset \"$PARTIAL_OFFSET_UNIX\" \"$PARTIAL_SFB_UNIX\""
                    debug_log $LINENO "EXECUTING: $command"
                    "$PREPARE_IMAGE_CMD""$PREPARE_IMAGE_SCRIPT" pack -m "$MAGIC" -k "$OEM_KEY_UNIX" -r 112 -v "$VERSION" -n "$NONCE_UNIX" -f "$SFU_FILE_UNIX" -t "$SIGN_FILE_UNIX" -o 512 --pfw "$PARTIAL_SFU_UNIX" --ptag "$PARTIAL_SIGN_UNIX" --poffset "$PARTIAL_OFFSET_UNIX" "$PARTIAL_SFB_UNIX" >> "$PROJECT_DIR_ABS"/output.txt
                    ret=$?
                  fi
                fi
              fi
            fi
          else
            info_log $LINENO "No reference user app found. Skipping partial image generation."
          fi
        fi
        # Merged ELF generation
        if [ $ret -eq 0 ] && [ "$FORCE_BIGELF" -eq 1 ]; then
          info_log $LINENO "Force big ELF flag is set. Starting merged ELF generation."
          PROGRAMMER_TOOL="STM32_Programmer_CLI"
          if uname | grep -i -e windows -e mingw >/dev/null 2>&1; then
            if [ -f "C:/Program Files/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin/STM32_Programmer_CLI.exe" ]; then
                PROGRAMMER_TOOL="C:/Program Files/STMicroelectronics/STM32Cube/STM32CubeProgrammer/bin/STM32_Programmer_CLI.exe"
            else
                info_log $LINENO "WARNING: STM32_Programmer_CLI.exe not found in default location. Make sure it is in your PATH."
            fi
          else
            if ! which STM32_Programmer_CLI >/dev/null 2>&1; then
              info_log $LINENO "WARNING: STM32_Programmer_CLI not found in PATH."
            fi
          fi
          info_log $LINENO "Using programmer tool: $PROGRAMMER_TOOL"
          command="$PROGRAMMER_TOOL -ms \"$ELF_FILE\" \"$HEADER_BIN_UNIX\" \"$SBSFU_ELF_UNIX\""
          debug_log $LINENO "EXECUTING: $command"
          "$PROGRAMMER_TOOL" -ms "$ELF_FILE" "$HEADER_BIN_UNIX" "$SBSFU_ELF_UNIX" >> "$PROJECT_DIR_ABS"/output.txt
          ret=$?
        fi
      fi
    fi
  fi
fi

# --- FINAL ERROR HANDLING ---
if [ $ret -ne 0 ]; then
  echo ""
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "!!! [FATAL ERROR] The script has failed."
  echo "!!! The last executed command failed:"
  echo "!!!   $command"
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1
fi

# --- CLEANUP (if successful) ---
info_log $LINENO "Cleaning up temporary files..."
rm -f "$SIGN_FILE_ABS"
rm -f "$SFU_FILE_ABS"
rm -f "$HEADER_BIN_ABS"

if [ -f "$REF_USER_APP_ABS" ]; then
  info_log $LINENO "Cleaning up partial image temporary files..."
  rm -f "$PARTIAL_BIN_ABS"
  rm -f "$PARTIAL_SFU_ABS"
  rm -f "$PARTIAL_SIGN_ABS"
  rm -f "$PARTIAL_OFFSET_ABS"
fi

info_log $LINENO "--- Post-Build Script Finished Successfully ---"
exit 0
