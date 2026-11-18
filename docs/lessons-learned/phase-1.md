# Phase 1 Lessons Learned

- **Git and GitHub are different things.** Git is the version-control program on my machine. GitHub hosts the repository and links commits to my account through the commit email.
- **Commit emails are public and permanent.** Using GitHub's noreply address keeps a personal email out of the history of a public repository.
- **`.gitignore` must come before the first commit.** Ignoring a file later does not remove it from history.
- **Line endings matter across operating systems.** Windows uses CRLF and Linux uses LF. `.gitattributes` makes them consistent so scripts don't break on the Linux CI runners.
- **Verify the effect, not the file.** A misnamed config file and an unsaved editor both looked "done" until the behaviour was tested.
