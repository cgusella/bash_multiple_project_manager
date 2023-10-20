#!/bin/bash

# ---------------- GLOBAL VARIABLES ----------------
WORKING_DIR=$(pwd)
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
HEIGHT=$(tput cols)
WIDTH=$(tput lines)
TOP_EMPTY_LINES="\\n\\n"
TITLE="Git multi-project manager"
DESCRIPTION=$TOP_EMPTY_LINES"Press 'esc' or Cancel button to exit.\\nIf you do not select any project then the application will be closed.\\nP.S. The changes are local.\\n\\nSelect (using whitespace) the projects you want to work with between:"


# ---------------- GLOBAL FUNCTIONS ----------------
get_git_directories () {
	COUNT=0
	DIRS=""
	for i in *; do
		if [[ -d ./$i/.git ]]; then
			DIRS+="$i project off "
			COUNT=$(($COUNT+1))
		fi
	done
	DIRS="$COUNT $DIRS"
	echo $DIRS
}

get_listed_projects () {
	NAME_LIST="\\n"
	for i in $PROJECTS; do
		cd $WORKING_DIR/$i
		BRANCH=$(git branch --show-current)
		NAME_LIST="$NAME_LIST '$i' in branch '$BRANCH'\\n"
	done
	echo $NAME_LIST
}

create_new_branch () {
	BRANCH_NAME=$(whiptail --title "$TITLE" --inputbox $TOP_EMPTY_LINES"Give the new branch name" $WIDTH $HEIGHT  3>&1 1>&2 2>&3)
	if [[ $? == 1 ]]; then return 1; fi # when cancel is pressed, then you return to the git operation menu
	
	INTERRUPT_PROGRAM_FOR_SOME_PROBLEM=0
	for i in $PROJECTS; do
		cd $WORKING_DIR/$i
		git branch $BRANCH_NAME
		PROBLEM_CREATING_NEW_BRANCH=$?
		
		if [[ $PROBLEM_CREATING_NEW_BRANCH -ne 0 ]]; then 
			whiptail --msgbox "Some problems for creating '$BRANCH_NAME' on '$i'. See logs in temrinal for more details." $WIDTH $HEIGHT --nocancel
			INTERRUPT_PROGRAM_FOR_SOME_PROBLEM=1
		else
			echo New branch $BRANCH_NAME on $BOLD$i$NORMAL
		fi
	done
	
	if [[ $INTERRUPT_PROGRAM_FOR_SOME_PROBLEM -ne 0 ]]; then exit; fi
	
	if (whiptail --yesno $TOP_EMPTY_LINES"Do you want to checkout now to '$BRANCH_NAME'?" $WIDTH $HEIGHT  3>&1 1>&2 2>&3); then
		checkout_selected_branches $BRANCH_NAME
	fi	
}

delete_branch () {
	BRANCH_NAME=$(whiptail --title "$TITLE" --inputbox $TOP_EMPTY_LINES"Give the branch name to delete" $WIDTH $HEIGHT  3>&1 1>&2 2>&3)
	if [[ $? == 1 ]]; then return 1; fi  # when cancel is pressed, then you return to the git operation menu
	for i in $PROJECTS; do
		cd $WORKING_DIR/$i
		echo Removing branch on $BOLD$i$NORMAL
		git branch -D $BRANCH_NAME
	done
	whiptail --msgbox $TOP_EMPTY_LINES"'$BRANCH_NAME' deleted" $WIDTH $HEIGHT --nocancel
}

checkout_selected_branches () {
	for i in $PROJECTS; do
		echo ----------- checkout $BOLD$i$NORMAL -----------
		cd $WORKING_DIR/$i
		git checkout $1
		if [[ $? -eq 1 ]]; then
			if (whiptail --yesno $TOP_EMPTY_LINES"The branch '$1' does not exists in project '$i'.\nDo you want to create it?" $WIDTH $HEIGHT 3>&1 1>&2 2>&3); then
				git branch $1
			fi
			break
		fi
	done
	whiptail --msgbox $TOP_EMPTY_LINES"Checkout branch '$1'" $WIDTH $HEIGHT --nocancel
}

checkout_branch () {
	BRANCH_NAME=$(whiptail --title "$TITLE" --inputbox $TOP_EMPTY_LINES"Give the branch name you want to checkout in" $WIDTH $HEIGHT  3>&1 1>&2 2>&3)
	if [[ $? == 1 ]]; then return 1; fi  # when cancel is pressed, then you return to the git operation menu
	checkout_selected_branches $BRANCH_NAME
	return 0
}

update_projects () {
	for i in $PROJECTS; do
		echo ----------- update $BOLD$i$NORMAL -----------
		cd $WORKING_DIR/$i
		git fetch --all
		git pull
		echo
	done
	whiptail --msgbox $TOP_EMPTY_LINES"Update complete" $WIDTH $HEIGHT --nocancel
}

clean_git_folder () {
	for i in $PROJECTS; do
		DIR=$WORKING_DIR/$i
		
		cd $DIR
		echo ----------- prune $BOLD$i$NORMAL -----------
		LOCAL_BRANCHES=$(git branch --list | tr -d '*')
		if [[ $? -ne 0 ]]; then exit; fi

		REMOTE_BRANCHES=$(git branch -r --list)

		for LOCAL_BRANCH in $LOCAL_BRANCHES; do
			TO_DELETE=0
		  	for REMOTE_BRANCH in $REMOTE_BRANCHES; do
				if [[ $REMOTE_BRANCH == "origin/$LOCAL_BRANCH" ]]; then
				  TO_DELETE=1
				  break
				fi
			done
			if [[ $TO_DELETE -eq 0 ]]; then
				git branch -D $LOCAL_BRANCH
			fi
		done
	done
	whiptail --msgbox $TOP_EMPTY_LINES"End prune operation." $WIDTH $HEIGHT --nocancel
}

commit_and_push () {
	COMMIT_MSG=$(whiptail --title "$TITLE" --inputbox $TOP_EMPTY_LINES"Insert commit message" $WIDTH $HEIGHT  3>&1 1>&2 2>&3)
	if [[ $? == 1 ]]; then return 1; fi  # when cancel is pressed, then you return to the git operation menu
	for i in $PROJECTS; do
		echo ----------- committing $BOLD$i$NORMAL -----------
		cd $WORKING_DIR/$i
		git diff --exit-code > /dev/null
		EXIT_CODE_DIFF=$?
		if [ $EXIT_CODE_DIFF -eq 1 ]; then
			GIT_BRANCH=$(git branch --show-current)
			CHANGES=$(git diff --name-only)
			TEXT="You are on branch: '$GIT_BRANCH'.\\nMessage commit: '$COMMIT_MSG'.\\nOn project '$i'\\n
You are committing only the changes not staged for commit:\\n
$CHANGES \\n
		 	Confirm?"
			if (whiptail --yesno "$TEXT" $WIDTH $HEIGHT  3>&1 1>&2 2>&3); then
				git add -u
				git commit -m "$COMMIT_MSG"
				git push
				# if the branch is present only in local machine, then it needs to push on remote with set-upstream
				if [[ $? -ne 0 ]]; then
					git push --set-upstream origin $GIT_BRANCH
				fi
				echo
			else
				echo no
			fi
		else
			whiptail --msgbox $TOP_EMPTY_LINES"Nothing to commit on project '$i' on branch '$GIT_BRANCH'" $WIDTH $HEIGHT --nocancel
		fi
	done
	whiptail --msgbox $TOP_EMPTY_LINES"Commit and push done." $WIDTH $HEIGHT --nocancel
}

#-------------------  START PROGRAM  -------------------

while true
do
	DIRS=$(get_git_directories)
	PROJECTS=$(whiptail --separate-output --title "$TITLE" --checklist "$DESCRIPTION" $WIDTH $HEIGHT $DIRS 3>&1 1>&2 2>&3)

	# exit if cancel is pressed or there are no selected projects
	if [[ $? == 1 || -z $PROJECTS ]]; then exit; fi
	

	NAME_LIST=$(get_listed_projects $PROJECTS)
	MENU_DESCRIPTION=$TOP_EMPTY_LINES"Project selected: $NAME_LIST\\n\\nSelect git operation:"
	
	while true
	do
		OPERATION=$(whiptail --title "$TITLE" --menu "$MENU_DESCRIPTION" $WIDTH $HEIGHT  6 "new branch" "git branch" "delete branch" "git branch -D" checkout "git checkout" update "git fetch --all & git pull" "prune untrucked branches" "" "commit and push" "git commit & git push" 3>&1 1>&2 2>&3)
		if [[ $? == 1 ]]; then break; fi

		case $OPERATION in
#		----------------------- NEW BRANCH  -----------------------
		
			"new branch")
				create_new_branch	
				if [[ $? == 1 ]]; then continue; fi  # when cancel is pressed, then you return to the git operation menu		
				exit 0
				;;
#		----------------------- DELETE BRANCH  -----------------------
			"delete branch")
				delete_branch
				if [[ $? == 1 ]]; then continue; fi  # when cancel is pressed, then you return to the git operation menu
				exit 0
				;;
#		----------------------- CHECKOUT BRANCH  -----------------------
			"checkout")
				checkout_branch
				if [[ $? == 1 ]]; then continue; fi  # when cancel is pressed, then you return to the git operation menu
				exit 0
				;;
#		----------------------- UPDATE PROJECTS  -----------------------
			"update")
				update_projects
				exit 0
				;;
#		----------------------- PRUNE PROJECTS  -----------------------
			"prune untrucked branches")
				clean_git_folder
				if [[ $? == 1 ]]; then continue; fi  # when cancel is pressed, then you return to the git operation menu
				exit 0
				;;
			
#		----------------------- COMMIT AND PUSH  -----------------------
			"commit and push")
				commit_and_push
				if [[ $? == 1 ]]; then continue; fi  # when cancel is pressed, then you return to the git operation menu
				exit 0
				;;
		esac
	done
done
