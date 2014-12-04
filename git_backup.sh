#!/usr/bin/env sh
# -*- coding: UTF8 -*-

filename=$1
cwd=$(pwd)

usage() 
{
cat << EOF
Usage: $0 [-d] [-i] [arg]

Backup the file given by arg with git versioning.

OPTIONS:

    -d    delete all the backups for the current directory
    -i    add untracked files to .gitignore

EOF
}

git_exception()
{
    echo "fatal: Not a git repository (or any of the parent directories): .git"
    exit 1
}

git_backup_db_exception()
{
    if grep $cwd $HOME/.git_backup.log; then
        return 0
    else
    cat << EOF
$cwd is not present in $HOME/.git_backup.log, this local repository
don't seem to be created by $0
EOF
        exit 1
    fi
}

add_to_gitignore()
{
    git status -s | awk '{if ($1 == "??") print $2}' >> .gitignore
}

main()
{
    if [ -d .git ]; then
        echo "Git repository in $cwd already initialized"
    else
        git init
        echo $(date +%s) $cwd >> $HOME/.git_backup.log
    fi

    add_to_gitignore
    sed -i "/^$filename$/d" .gitignore

    git add $filename
    git status -s
    message=$(git status -s)
    git commit -m "$message" $filename
}

# default for options
DELETE=0
IGNORE=0

# parse the options
while getopts ':dih' opt ; do
  case $opt in
    d) DELETE=1;;
    i) IGNORE=1;;
    h) usage ; exit 0;;
    ?) echo "Invalid option: -$OPTARG"; usage; exit 1;;
  esac
done

if [ $DELETE -eq 1 ]; then
    if [ -d .git ]; then
        git_backup_db_exception
        /bin/rm -rf $cwd/.git $cwd/.gitignore
        cat $HOME/.git_backup.log | grep -v "$cwd"  > /dev/shm/.git_backup.log.tmp
        /bin/mv /dev/shm/.git_backup.log.tmp $HOME/.git_backup.log
        echo "All backups deleted for directory $cwd"
        exit 0
    else
        git_exception
    fi
fi

if [ $IGNORE -eq 1 ]; then
    if [ -f .gitignore ]; then
        add_to_gitignore
        echo "All untracked files added to .gitignore"
        exit 0
    else
        git_exception
    fi
fi

main
