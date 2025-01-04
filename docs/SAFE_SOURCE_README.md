
# Safe Source Script Utility

This Bash utility provides a robust mechanism to temporarily source other scripts and then revert any changes made to the environment, such as variables, functions, aliases, and exported environment variables. It is particularly useful for managing nested script sourcing and maintaining the integrity of the shell environment.

---

## Features

- **Snapshot Environment State**: Captures the current state of variables, functions, aliases, and exported variables before sourcing a script.
- **Nested Sourcing Support**: Allows multiple scripts to be sourced in sequence, with each script's changes tracked and reverted independently.
- **Full Reversion**: Reverts all changes made by the sourced scripts, including added or modified variables, functions, aliases, and exported variables.
- **Temporary File Cleanup**: Ensures that all temporary files used for tracking snapshots are cleaned up after use.

---

## How It Works

1. **Source a Script**:
   - `_SAFE_SOURCE_SCRIPT` takes a snapshot of the current environment and then sources the specified script.
   - Any changes made by the sourced script are tracked.

2. **Unsource a Script**:
   - `_SAFE_UNSOURCE` reverts all changes made by the most recently sourced script, restoring the environment to its previous state.

3. **Nested Sourcing**:
   - Multiple scripts can be sourced sequentially, and their changes are reverted in reverse order (last-in, first-out).

---

## Usage

### 1. `_SAFE_SOURCE_SCRIPT`

Safely source a script while tracking changes to the environment.

#### **Syntax**:
```bash
_SAFE_SOURCE_SCRIPT <script_path>
```

#### **Parameters**:
- `script_path`: Path to the script to be sourced.

#### **Example**:
```bash
_SAFE_SOURCE_SCRIPT script2.sh
```

---

### 2. `_SAFE_UNSOURCE`

Revert the changes made by the most recently sourced script.

#### **Syntax**:
```bash
_SAFE_UNSOURCE
```

#### **Parameters**:
- None.

#### **Example**:
```bash
_SAFE_UNSOURCE
```

---

### 3. Example Workflow

#### Create Test Scripts

**`script2.sh`**:
```bash
export VAR_IN_SCRIPT2="Hello from script2"
alias alias_script2='echo Script2 alias'
function func_script2() {
    echo "This is script2"
}
```

**`script3.sh`**:
```bash
export VAR_IN_SCRIPT3="Hello from script3"
alias alias_script3='echo Script3 alias'
function func_script3() {
    echo "This is script3"
}
```

#### Main Script Example
**`script1.sh`**:
```bash
#!/bin/bash
source safe_source.sh

# Safely source script2
_SAFE_SOURCE_SCRIPT script2.sh

# Safely source script3
_SAFE_SOURCE_SCRIPT script3.sh

# Test environment changes
echo "$VAR_IN_SCRIPT2"
echo "$VAR_IN_SCRIPT3"
alias_script2
alias_script3
func_script2
func_script3

# Revert script3 changes
_SAFE_UNSOURCE

# Revert script2 changes
_SAFE_UNSOURCE
```

#### Run the Main Script:
```bash
bash script1.sh
```

---

### Expected Behavior

1. **After Sourcing**:
   - Variables, aliases, and functions from `script2.sh` and `script3.sh` are available.
   - Example Output:
     ```plaintext
     Hello from script2
     Hello from script3
     Script2 alias
     Script3 alias
     This is script2
     This is script3
     ```

2. **After Unsourcing**:
   - `script3.sh` changes are reverted first, followed by `script2.sh`.
   - Example Output:
     ```plaintext
     Error: alias_script3: command not found
     Error: func_script3: command not found
     Error: alias_script2: command not found
     Error: func_script2: command not found
     ```

---

## Notes

- **Temporary Files**:
  - Temporary files are created in `/tmp` to track snapshots. These are automatically cleaned up after `_SAFE_UNSOURCE` is called.

- **Nested Sourcing**:
  - Changes made by each script are tracked separately and reverted in reverse order of sourcing.

- **Performance**:
  - Using `comm` and temporary files ensures efficient environment tracking and reversion.

---

## Troubleshooting

1. **Script Not Found**:
   - If the script specified in `_SAFE_SOURCE_SCRIPT` does not exist, you will see an error:
     ```plaintext
     Error: Script 'script2.sh' does not exist.
     ```

2. **No Snapshot to Unsource**:
   - If `_SAFE_UNSOURCE` is called without a prior `_SAFE_SOURCE_SCRIPT`, you will see:
     ```plaintext
     Error: No environment snapshot to unsource.
     ```

3. **Debugging**:
   - Add `set -x` at the top of your script to debug the sourcing and unsourcing process.

---

## License

This script is provided under the MIT License. Feel free to use and modify it for your needs.

---

Enjoy using the Safe Source Script Utility! 🎉
