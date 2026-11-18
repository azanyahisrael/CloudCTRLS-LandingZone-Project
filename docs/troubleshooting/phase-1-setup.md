# Phase 1 Troubleshooting Log

## 1. Git identity did not save

- **Symptom:** after running `git config --global user.name ...`, `git config --global --list` failed with `unable to read config file 'C:/Users/XLOUBS/.gitconfig': No such file or directory`.
- **Diagnosis:** `git config --list --show-origin` showed only the system-wide config (`C:/Program Files/Git/etc/gitconfig`). No user-level config existed, so the commands had not run in this machine's terminal.
- **Resolution:** re-ran the commands in the VS Code terminal for this project. `--show-origin` then showed `user.name` coming from the global config file.
- **Lesson:** `--show-origin` shows *where* each setting comes from, which separates "not set" from "set somewhere else".

## 2. `.gitattributes` had no effect

- **Symptom:** line-ending rules were written but not applied.
- **Diagnosis:** the file was saved as `.gitattribute` (no `s`). Git only reads the exact filename and gives no warning for a misnamed one.
- **Resolution:** renamed it to `.gitattributes`, then confirmed with `git check-attr eol -- test.sh test.ps1 test.bat`.
- **Lesson:** verify the behaviour a config file should produce, not just that the file exists.

## 3. Edits did not appear on disk

- **Symptom:** after editing `.gitignore` and `.gitattributes`, the files on disk were unchanged.
- **Diagnosis:** the edits were unsaved in VS Code (white dot on the editor tab).
- **Resolution:** saved the files. Auto Save (File > Auto Save) prevents this.
