# bash_multiple_project_manager

**Description:**
Manage multiple git projects in a Debian-based Linux terminal.

## Notice
This script uses the `whiptail` command, which is native in all Debian-based Linux distros. Please check if your system has `whiptail` installed by running the following command in a terminal:

```bash
whiptail --help
```

## What it does

This application allows you to choose from all the git projects you have inside a specific folder. Simultaneously, for the selected projects, you can:

* Add a new branch
* Delete a branch
* Checkout a branch
* Update projects
* Prune all non-local branches
* Commit and push.

Unlike other options, the fifth one enables you to clean your local repositories from branches that exist in the remote repository but not locally. This is useful when you want to remove unused branches from the local project. However, please be cautious: if you create a local branch and then launch the prune command, you will delete it.

## How to use it

This bash script manages git projects within a specified folder.

To use it:

1. Save this script inside the folder containing the git projects you want to manage.
2. Make the script executable by running: 

```bash
chmod +x git-multi-project-manager.sh
```

3. Launch the script.

## Tips
Since there is no vertical scrollbar, if you have many projects to display, you may need to enlarge your terminal window.

While not a perfect solution, I am actively working on improving this.

All changes are local, so you are not affecting any files in remote repositories.
