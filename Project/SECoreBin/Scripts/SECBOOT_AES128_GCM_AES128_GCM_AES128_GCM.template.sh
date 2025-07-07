# ==============================================================================
#
# ORIGINAL STMICROELECTRONICS SCRIPT - FOR REFERENCE ONLY
#
# This file contains the original script, broken down into functional parts.
# Each part is commented out and will be replaced step-by-step with
# the new, refactored implementation.
#
# ==============================================================================

# ==============================================================================
# Part A: Parameter & Variable Definition
# ==============================================================================
#A# #!/bin/bash -
#A# #Post build for SECBOOT_AES128_GCM_WITH_AES128_GCM
#A# # arg1 is the build directory
#A# # arg2 is the elf file path+name
#A# # arg3 is the bin file path+name
#A# # arg4 is the firmware Id (1/2/3)
#A# # arg5 is the version
#A# # arg6 when present forces "bigelf" generation
#A# projectdir=$1
#A# FileName=${3##*/}
#A# execname=${FileName%.*}
#A# elf=$2
#A# bin=$3
#A# fwid=$4
#A# version=$5
#A#
#A# SecureEngine=${0%/*}
#A#
#A# userAppBinary=$projectdir"/../Binary"
#A#
#A# sfu=$userAppBinary"/"$execname".sfu"
#A# sfb=$userAppBinary"/"$execname".sfb"
#A# sign=$userAppBinary"/"%execname".sign"
#A# headerbin=$userAppBinary"/"$execname"sfuh.bin"
#A# bigbinary=$userAppBinary"/SBSFU_"$execname".bin"
#A# elfbackup=$userAppBinary"/SBSFU_"$execname".elf"
#A#
#A# nonce=$SecureEngine"/../Binary/nonce.bin"
#A# magic="SFU"$fwid
#A# oemkey=$SecureEngine"/../Binary/OEM_KEY_COMPANY"$fwid"_key_AES_GCM.bin"
#A# partialbin=$userAppBinary"/Partial"$execname".bin"
#A# partialsfb=$userAppBinary"/Partial"$execname".sfb"
#A# partialsfu=$userAppBinary"/Partial"$execname".sfu"
#A# partialsign=$userAppBinary"/Partial"$execname".sign"
#A# partialoffset=$userAppBinary"/Partial"$execname".offset"
#A# ref_userapp=$projectdir"/RefUserApp.bin"
#A# offset=512
#A# alignment=16

# ==============================================================================
# Part B: Complex Path Calculation
# ==============================================================================
#B#
#B# current_directory=`pwd`
#B# cd "$SecureEngine/../../"
#B# SecureDir=`pwd`
#B# cd "$current_directory"
#B# sbsfuelf="$SecureDir/2_Images_SBSFU/STM32CubeIDE/Debug/SBSFU.elf"
#B# current_directory=`pwd`
#B# cd "$1/../../../../../../Middlewares/ST/STM32_Secure_Engine/Utilities/KeysAndImages"
#B# basedir=`pwd`
#B# cd "$current_directory"

# ==============================================================================
# Part C: Toolchain Selection
# ==============================================================================
#C# # test if window executable usable
#C# prepareimage=$basedir"/win/prepareimage/prepareimage.exe"
#C# uname | grep -i -e windows -e mingw >/dev/null > /dev/null 2>&1
#C# if [ $? -eq 0 ] && [  -e "$prepareimage" ]; then
#C#   echo "prepareimage with windows executable"
#C#   PATH=$basedir"\\win\\prepareimage":$PATH > /dev/null 2>&1
#C#   cmd=""
#C#   prepareimage="prepareimage.exe"
#C# else
#C#   # line for python
#C#   echo "prepareimage with python script"
#C#   prepareimage=$basedir/prepareimage.py
#C#   cmd="python"
#C# fi

# ==============================================================================
# Part D: Create Output Directory
# ==============================================================================
#D#
#D# # Make sure we have a Binary sub-folder in UserApp folder
#D# if [ ! -e $userAppBinary ]; then
#D# mkdir $userAppBinary
#D# fi

# ==============================================================================
# Part E.1: Main Packaging - Encrypt
# ==============================================================================
#E.1#
#E.1# command=$cmd" "$prepareimage" enc -k "$oemkey" -n "$nonce" "$bin" "$sfu
#E.1# $command > $projectdir"/output.txt"
#E.1# ret=$?

# ==============================================================================
# Part E.2: Main Packaging - Sign
# ==============================================================================
#E.2# if [ $ret -eq 0 ]; then
#E.2#   command=$cmd" "$prepareimage" sign -k "$oemkey" -n "$nonce" "$bin" "$sign
#E.2#   $command >> $projectdir"/output.txt"
#E.2#   ret=$?

# ==============================================================================
# Part E.3: Main Packaging - Pack
# ==============================================================================
#E.3#   if [ $ret -eq 0 ]; then
#E.3#     command=$cmd" "$prepareimage" pack -m "$magic" -k "$oemkey"  -r 112 -v "$version" -n "$nonce" -f "$sfu" -t "$sign" "$sfb" -o "$offset
#E.3#     $command >> $projectdir"/output.txt"
#E.3#     ret=$?

# ==============================================================================
# Part E.4: Main Packaging - Header
# ==============================================================================
#E.4#     if [ $ret -eq 0 ]; then
#E.4#       command=$cmd" "$prepareimage" header -m "$magic" -k  "$oemkey" -r 112 -v "$version"  -n "$nonce" -f "$sfu" -t "$sign" -o "$offset" "$headerbin
#E.4#       $command >> $projectdir"/output.txt"
#E.4#       ret=$?

# ==============================================================================
# Part E.5: Main Packaging - Merge
# ==============================================================================
#E.5#       if [ $ret -eq 0 ]; then
#E.5#         command=$cmd" "$prepareimage" merge -v 0 -e 1 -i "$headerbin" -s "$sbsfuelf" -u "$elf" "$bigbinary
#E.5#         $command >> $projectdir"/output.txt"
#E.5#         ret=$?

# ==============================================================================
# Part F.1: Partial Image (Optional) - Diff
# ==============================================================================
#F.1#         #Partial image generation if reference userapp exists
#F.1#         if [ $ret -eq 0 ] && [ -e "$ref_userapp" ]; then
#F.1#           echo "Generating the partial image .sfb"
#F.1#           echo "Generating the partial image .sfb" >> $projectdir"/output.txt"
#F.1#           command=$cmd" "$prepareimage" diff -1 "$ref_userapp" -2 "$bin" "$partialbin" -a "$alignment" --poffset "$partialoffset
#F.1#           $command >> $projectdir"/output.txt"
#F.1#           ret=$?

# ==============================================================================
# Part F.2: Partial Image (Optional) - Encrypt
# ==============================================================================
#F.2#           if [ $ret -eq 0 ]; then
#F.2#             command=$cmd" "$prepareimage" enc -k "$oemkey" -i "$nonce" "$partialbin" "$partialsfu
#F.2#             $command >> $projectdir"/output.txt"
#F.2#             ret=$?

# ==============================================================================
# Part F.3: Partial Image (Optional) - Sign
# ==============================================================================
#F.3#             if [ $ret -eq 0 ]; then
#F.3#               command=$cmd" "$prepareimage" sign -k "$oemkey" -n "$nonce" "$partialbin" "$partialsign
#F.3#               $command >> $projectdir"/output.txt"
#F.3#               ret=$?

# ==============================================================================
# Part F.4: Partial Image (Optional) - Pack
# ==============================================================================
#F.4#               if [ $ret -eq 0 ]; then
#F.4#                 command=$cmd" "$prepareimage" pack -m "$magic" -k "$oemkey" -r 112 -v "$version" -i "$nonce" -f "$sfu" -t "$sign" -o "$offset" --pfw "$partialsfu" --ptag "$partialsign" --poffset  "$partialoffset" "$partialsfb
#F.4#                 $command >> $projectdir"/output.txt"
#F.4#                 ret=$?
#F.4#               fi
#F.3#             fi
#F.2#           fi
#F.1#         fi

# ==============================================================================
# Part G: Merged ELF Generation (Optional)
# ==============================================================================
#G#         if [ $ret -eq 0 ] && [ $# = 6 ]; then
#G#           echo "Generating the global elf file SBSFU and userApp"
#G#           echo "Generating the global elf file SBSFU and userApp" >> $projectdir"/output.txt"
#G#           uname | grep -i -e windows -e mingw > /dev/null 2>&1
#G#           if [ $? -eq 0 ]; then
#G#             # Set to the default installation path of the Cube Programmer tool
#G#             # If you installed it in another location, please update PATH.
#G#             PATH="C:\\Program Files (x86)\\STMicroelectronics\\STM32Cube\\STM32CubeProgrammer\\bin":$PATH > /dev/null 2>&1
#G#             programmertool="STM32_Programmer_CLI.exe"
#G#           else
#G#             which STM32_Programmer_CLI > /dev/null
#G#             if [ $? = 0 ]; then
#G#               programmertool="STM32_Programmer_CLI"
#G#             else
#G#               echo "fix access path to STM32_Programmer_CLI"
#G#             fi
#G#           fi
#G#           command=$programmertool" -ms "$elf" "$headerbin" "$sbsfuelf
#G#           $command >> $projectdir"/output.txt"
#G#           ret=$?
#G#         fi
#E.5#       fi
#E.4#     fi
#E.3#   fi
#E.2# fi

# ==============================================================================
#
# NEW SCRIPT IMPLEMENTATION
#
# ==============================================================================

#!/bin/sh
set -e
set -u

# --- Global Variables ---
LOG_INFO_MODE=1
LOG_DEBUG_MODE=1
LOG_ERROR_MODE=1
LOG_INFO_FILE=""
LOG_DEBUG_FILE=""
LOG_ERROR_FILE=""

# --- Function Definitions ---

usage() {
    echo "Usage: $0 <UserApp Build Dir> <UserApp ELF> <UserApp BIN> <FW ID> <FW Version> [Log-I] [Log-D] [Log-E] [ForceBigELF]"
    echo "  - UserApp Build Dir:  Path to the UserApp build directory (e.g., 'Debug')."
    echo "  - UserApp ELF File:   Path to the UserApp ELF file."
    echo "  - UserApp BIN File:   Path to the UserApp BIN file (the firmware to package)."
    echo "  - FW ID:              The firmware slot identifier (e.g., 1, 2, or 3)."
    echo "  - FW Version:         The version number for the firmware header."
    echo "  - Log Modes (Opt):    1=Console, 2=File, 3=Both. Defaults to 1."
    echo "  - ForceBigELF (Opt):  Any value to force generation of merged ELF."
}

_log() {
    line_num="$1"
    log_type="$2"
    message="$3"
    log_mode="$4"
    log_file="$5"

    formatted_message="[LINE $line_num - $log_type] $message"
    case "$log_mode" in
        1) echo "$formatted_message";;
        2) echo "$formatted_message" >> "$log_file";;
        3) echo "$formatted_message" | tee -a "$log_file";;
    esac
}

info_log()  { _log "$1" "INFO"  "$2" "$LOG_INFO_MODE"  "$LOG_INFO_FILE"; }
debug_log() { _log "$1" "DEBUG" "$2" "$LOG_DEBUG_MODE" "$LOG_DEBUG_FILE"; }
error_log() { _log "$1" "ERROR" "$2" "$LOG_ERROR_MODE" "$LOG_ERROR_FILE"; }

error_exit() {
    error_log "$1" "$2"
    exit 1
}

main() {
    # --- 1. Argument Parsing ---
    if [ "$#" -lt 8 ]; then
        usage
        error_exit "$LINENO" "Missing mandatory arguments."
    fi

    USERAPP_BUILD_DIR_REL="$1"
    USERAPP_ELF_NAME="$2"
    USERAPP_BIN_REL="$3"
    FW_ID="$4"
    FW_VERSION="$5"
    LOG_INFO_MODE=${6:-1}
    LOG_DEBUG_MODE=${7:-1}
    LOG_ERROR_MODE=${8:-1}

    if [ "$#" -ge 9 ]; then
    FORCE_BIGELF=1
    else
    FORCE_BIGELF=0
    fi


    FORCE_BIGELF=${9:-0}

    # Resolve Middle Parameters
    USERAPP_BIN_FILE_NAME="${3##*/}"
    USERAPP_BIN_DIR_REL="$(dirname "$3")"
    USERAPP_BIN_DIR_ABS="$(cd "$USERAPP_BIN_DIR_REL" && pwd)"


    # --- 2. Path and Logging Setup ---

    # Resolve absolute paths
    SCRIPT_DIR_ABS="$(cd "$(dirname "$0")" && pwd)"
    COMMON_DIR_ABS="$(cd "$SCRIPT_DIR_ABS/../../Common" && pwd)"
    USERAPP_BUILD_DIR_ABS="$(cd "$USERAPP_BUILD_DIR_REL" && pwd)"

    # Setup logging files
    LOG_DIR="$USERAPP_BUILD_DIR_ABS/Output"
    mkdir -p "$LOG_DIR"
    LOG_INFO_FILE="$LOG_DIR/postbuild_Info.log"
    LOG_DEBUG_FILE="$LOG_DIR/postbuild_Debug.log"
    LOG_ERROR_FILE="$LOG_DIR/postbuild_Error.log"

    : > "$LOG_INFO_FILE"
    : > "$LOG_DEBUG_FILE"
    : > "$LOG_ERROR_FILE"

    info_log "$LINENO" "Post-build for secure firmware started."
    debug_log "$LINENO" "--- Input Parameters ---"
    debug_log "$LINENO" "1: UserApp Build Dir (Rel): $USERAPP_BUILD_DIR_REL"
    debug_log "$LINENO" "2: UserApp ELF Name:        $USERAPP_ELF_NAME"
    debug_log "$LINENO" "3: UserApp BIN (Rel):       $USERAPP_BIN_REL"
    debug_log "$LINENO" "4: Firmware ID:             $FW_ID"
    debug_log "$LINENO" "5: Firmware Version:        $FW_VERSION"
    debug_log "$LINENO" "6: Log Info Mode:           $LOG_INFO_MODE"
    debug_log "$LINENO" "7: Log Debug Mode:          $LOG_DEBUG_MODE"
    debug_log "$LINENO" "8: Log Error Mode:          $LOG_ERROR_MODE"

	 if [ "$#" -ge 9 ]; then
    	debug_log "$LINENO" "9: Force BigELF:            $FORCE_BIGELF"
    fi

    debug_log "$LINENO" "--- MIDDLE Parameters ---"
    debug_log "$LINENO" "UserApp BIN Name:        $USERAPP_BIN_FILE_NAME"
    debug_log "$LINENO" "UserApp BIN Dir (Rel):   $USERAPP_BIN_DIR_REL"


    # --- 3. Define and Validate All Paths ---

    # Dynamically determine the build mode (e.g., 'Debug') from the build directory path
    BUILD_MODE=$(basename "$(pwd)")

    # Toolchain and Keys
    KEYS_AND_IMAGES_DIR_ABS="$COMMON_DIR_ABS/KeysAndImages_Util"
    BINARY_KEYS_DIR_ABS="$COMMON_DIR_ABS/Binary_Keys"

    # Input files
    USERAPP_BIN_FILE_ABS="$(cd "$USERAPP_BIN_DIR_REL" && pwd)/$USERAPP_BIN_FILE_NAME"
    USERAPP_ELF_FILE_ABS="$USERAPP_BUILD_DIR_ABS/$USERAPP_ELF_NAME"
    SBSFU_ELF_FILE_ABS="$COMMON_DIR_ABS/$BUILD_MODE/SBSFU.elf"

    # Output files
    USERAPP_BINARY_DIR_ABS="$(dirname "$USERAPP_BUILD_DIR_ABS")/Binary"
    mkdir -p "$USERAPP_BINARY_DIR_ABS"

    EXEC_NAME=$(basename "$USERAPP_BIN_FILE_ABS" .bin)
    SFU_FILE_ABS="$USERAPP_BINARY_DIR_ABS/${EXEC_NAME}.sfu"
    SFB_FILE_ABS="$USERAPP_BINARY_DIR_ABS/${EXEC_NAME}.sfb"
    SIGN_FILE_ABS="$USERAPP_BINARY_DIR_ABS/${EXEC_NAME}.sign"
    HEADER_BIN_ABS="$USERAPP_BINARY_DIR_ABS/${EXEC_NAME}sfuh.bin"
    BIGBINARY_ABS="$USERAPP_BINARY_DIR_ABS/SBSFU_${EXEC_NAME}.bin"

    # Keys and constants
    NONCE_FILE_ABS="$BINARY_KEYS_DIR_ABS/nonce.bin"
    OEM_KEY_ABS="$BINARY_KEYS_DIR_ABS/OEM_KEY_COMPANY${FW_ID}_key_AES_GCM.bin"
    MAGIC="SFU${FW_ID}"
    OFFSET=512
    ALIGNMENT=16

    # Partial update files (optional)
    REF_USER_APP_ABS="$USERAPP_BUILD_DIR_ABS/RefUserApp.bin"
    PARTIAL_BIN_ABS="$USERAPP_BINARY_DIR_ABS/Partial${EXEC_NAME}.bin"
    PARTIAL_SFU_ABS="$USERAPP_BINARY_DIR_ABS/Partial${EXEC_NAME}.sfu"
    PARTIAL_SIGN_ABS="$USERAPP_BINARY_DIR_ABS/Partial${EXEC_NAME}.sign"
    PARTIAL_SFB_ABS="$USERAPP_BINARY_DIR_ABS/Partial${EXEC_NAME}.sfb"
    PARTIAL_OFFSET_ABS="$USERAPP_BINARY_DIR_ABS/Partial${EXEC_NAME}.offset"

    debug_log "$LINENO" "--- Resolved Paths & Variables ---"
    debug_log "$LINENO" "Script Dir (Abs):              $SCRIPT_DIR_ABS"
    debug_log "$LINENO" "Common Dir (Abs):              $COMMON_DIR_ABS"
    debug_log "$LINENO" "UserApp Build Dir (Abs):       $USERAPP_BUILD_DIR_ABS"
    debug_log "$LINENO" "Log Directory:                 $LOG_DIR"
    debug_log "$LINENO" "Build Mode:                    $BUILD_MODE"
    debug_log "$LINENO" "Keys & Images Dir:             $KEYS_AND_IMAGES_DIR_ABS"
    debug_log "$LINENO" "Binary Keys Dir:               $BINARY_KEYS_DIR_ABS"
    debug_log "$LINENO" "UserApp BIN:                   $USERAPP_BIN_FILE_ABS"
    debug_log "$LINENO" "UserApp ELF:                   $USERAPP_ELF_FILE_ABS"
    debug_log "$LINENO" "SBSFU ELF:                     $SBSFU_ELF_FILE_ABS"
    debug_log "$LINENO" "Nonce:                         $NONCE_FILE_ABS"
    debug_log "$LINENO" "OEM Key:                       $OEM_KEY_ABS"
    debug_log "$LINENO" "Magic:                         $MAGIC"
    debug_log "$LINENO" "Offset:                        $OFFSET"
    debug_log "$LINENO" "Alignment:                     $ALIGNMENT"
    debug_log "$LINENO" "Output Dir:                    $USERAPP_BINARY_DIR_ABS"
    debug_log "$LINENO" "Exec Name:                     $EXEC_NAME"
    debug_log "$LINENO" "Output SFU:                    $SFU_FILE_ABS"
    debug_log "$LINENO" "Output SFB:                    $SFB_FILE_ABS"
    debug_log "$LINENO" "Output SIGN:                   $SIGN_FILE_ABS"
    debug_log "$LINENO" "Output Header:                 $HEADER_BIN_ABS"
    debug_log "$LINENO" "Output BigBinary:              $BIGBINARY_ABS"
    debug_log "$LINENO" "Ref UserApp (Opt):             $REF_USER_APP_ABS"
    debug_log "$LINENO" "Partial BIN:                   $PARTIAL_BIN_ABS"
    debug_log "$LINENO" "Partial SFU:                   $PARTIAL_SFU_ABS"
    debug_log "$LINENO" "Partial SIGN:                  $PARTIAL_SIGN_ABS"
    debug_log "$LINENO" "Partial SFB:                   $PARTIAL_SFB_ABS"
    debug_log "$LINENO" "Partial Offset:                $PARTIAL_OFFSET_ABS"
}

main "$@"
