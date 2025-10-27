# Branch-restore
When a git branch is deleted, no commits are deleted with it. They can become inaccessible if they aren't part of any branch anymore, but they are still there in the .git directory. This script helps to restore them by printing the hashes of those commits, that:
- do not have children,
- do not have a branch head pointing to them.
You can use that hash with `git checkout` command to check that commit. If you create a new branch based on that commit, then both this particular commit and all its parent commits will become easily accessible again.

## Installation
First, download the script. You can do this by running this command.
`curl --output branch-restore.sh https://raw.githubusercontent.com/surmavagit/branch-restore/refs/heads/main/branch-restore.sh`
If you're only going to use it once, save it directly to the repository that you need - you can delete it later.
Otherwise add it to your PATH or create an alias to be able to call it easily in any repository.

## Usage
The script should be run directly in the git repository that you're analysing.
It creates a 'branch-restore' directory for temporary files. It will not run if such a directory already exists.
The hashes of the recovered commits are printed to stdout.
The script comes with a `--help` option.

## Examples
Print all the details of commits to be restored:
`./branch-restore.sh | xargs -n1 git cat-file -p`

Select a commit with fzf (preview shows its details) and switch to that commit:
`./branch-restore.sh | fzf --preview='git cat-file -p {}' | xargs git checkout`

Select a commit with fzf, preview shows if there is a branch pointing at it or not:
`./branch-restore.sh -a | fzf --preview='grep -rl {} .git/refs/heads/ | xargs basename 2>/dev/null || echo no branch'`

## PostScriptum
This script offers almost the same functionality as `git fsck --no-reflogs`. Unlike the latter, it prints only the hashes themselves, without the phrase 'dangling commit' prepended to the results.
