# Refactoring Plan for Secure Packaging Script

This file tracks the step-by-step plan to refactor the secure packaging script.

### 1. Structure & Logging
- [x] Convert script to `#!/bin/sh` and add `set -e`, `set -u`. (Done)
- [x] Add a standard `main()` function structure. (Done)
- [x] Add unified logging functions (`info_log`, `debug_log`, `error_log`). (Done)
- [x] Add a `usage` function for clear parameter documentation. (Done)

### 2. Argument & Path Handling
- [ ] Define and implement the new, clear parameter list.
- [ ] Capture all incoming parameters into well-named variables.
- [ ] Convert all input paths to absolute, canonical paths.
- [ ] Dynamically determine `BUILD_MODE` from the input build directory.
- [ ] Dynamically construct the path to `SBSFU.elf` using `BUILD_MODE`.
- [ ] Add `debug_log` calls for every created variable and path.

### 3. Input Validation
- [ ] Create and implement a function to validate the existence of all essential input files and directories before processing begins.

### 4. Core Logic Integration
- [ ] Re-implement the `prepareimage` toolchain selection (Python/Exe).
- [ ] **Preserve the original `if [ $ret -eq 0 ]` nested structure for the packaging flow.**
- [ ] Inside the nested structure, replace old variables with the new, absolute path variables.
- [ ] Preserve the `echo "$command"` functionality, but wrap it in a `debug_log` call.

### 5. Cleanup
- [ ] Implement a `cleanup` function for removing temporary files upon success.
- [ ] Ensure the script exits with a clear success or failure message.
