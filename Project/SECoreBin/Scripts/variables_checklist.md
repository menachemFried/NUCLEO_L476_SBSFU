# Script Variables Checklist

This file tracks all defined variables in the secure packaging script and verifies that each one is logged for debugging purposes.

| Variable Name             | Logged in Debug? | Notes                                    |
|---------------------------|:----------------:|------------------------------------------|
| `USERAPP_BUILD_DIR_REL`   |       [x]        | Parameter $1                             |
| `USERAPP_ELF_NAME`        |       [x]        | Parameter $2                             |
| `USERAPP_BIN_REL`         |       [x]        | Parameter $3                             |
| `FW_ID`                   |       [x]        | Parameter $4                             |
| `FW_VERSION`              |       [x]        | Parameter $5                             |
| `LOG_INFO_MODE`           |       [x]        | Parameter $6 (optional)                  |
| `LOG_DEBUG_MODE`          |       [x]        | Parameter $7 (optional)                  |
| `LOG_ERROR_MODE`          |       [x]        | Parameter $8 (optional)                  |
| `FORCE_BIGELF`            |       [x]        | Parameter $9 (optional)                  |
| `USERAPP_BIN_FILE_NAME`   |       [x]        | Derived from `USERAPP_BIN_REL`           |
| `USERAPP_BIN_DIR_REL`     |       [x]        | Derived from `USERAPP_BIN_REL`           |
| `USERAPP_BIN_DIR_ABS`     |       [ ]        | Intermediate variable, not logged        |
| `SCRIPT_DIR_ABS`          |       [x]        | Resolved from `$0`                       |
| `COMMON_DIR_ABS`          |       [x]        | Resolved from script path                |
| `USERAPP_BUILD_DIR_ABS`   |       [x]        | Resolved from `USERAPP_BUILD_DIR_REL`    |
| `LOG_DIR`                 |       [x]        | Constructed path                         |
| `LOG_INFO_FILE`           |       [ ]        | Internal variable, not logged directly   |
| `LOG_DEBUG_FILE`          |       [ ]        | Internal variable, not logged directly   |
| `LOG_ERROR_FILE`          |       [ ]        | Internal variable, not logged directly   |
| `BUILD_MODE`              |       [x]        | Derived from `USERAPP_BUILD_DIR_ABS`     |
| `KEYS_AND_IMAGES_DIR_ABS` |       [x]        | Constructed path                         |
| `BINARY_KEYS_DIR_ABS`     |       [x]        | Constructed path                         |
| `USERAPP_BIN_FILE_ABS`    |       [x]        | Constructed path                         |
| `USERAPP_ELF_FILE_ABS`    |       [x]        | Constructed path                         |
| `SBSFU_ELF_FILE_ABS`      |       [x]        | Constructed path                         |
| `USERAPP_BINARY_DIR_ABS`  |       [ ]        | Intermediate variable, not logged        |
| `EXEC_NAME`               |       [ ]        | Intermediate variable, not logged        |
| `SFU_FILE_ABS`            |       [x]        | Constructed path                         |
| `SFB_FILE_ABS`            |       [x]        | Constructed path                         |
| `SIGN_FILE_ABS`           |       [x]        | Constructed path                         |
| `HEADER_BIN_ABS`          |       [x]        | Constructed path                         |
| `BIGBINARY_ABS`           |       [x]        | Constructed path                         |
| `NONCE_FILE_ABS`          |       [x]        | Constructed path                         |
| `OEM_KEY_ABS`             |       [x]        | Constructed path                         |
| `MAGIC`                   |       [x]        | Constructed variable                     |
| `OFFSET`                  |       [x]        | Constant                                 |
| `ALIGNMENT`               |       [x]        | Constant                                 |
| `REF_USER_APP_ABS`        |       [x]        | Constructed path                         |
| `PARTIAL_BIN_ABS`         |       [x]        | Constructed path                         |
| `PARTIAL_SFU_ABS`         |       [x]        | Constructed path                         |
| `PARTIAL_SIGN_ABS`        |       [x]        | Constructed path                         |
| `PARTIAL_SFB_ABS`         |       [x]        | Constructed path                         |
| `PARTIAL_OFFSET_ABS`      |       [x]        | Constructed path                         |
