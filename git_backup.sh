#!/usr/bin/env sh
# -*- coding: UTF8 -*-

filename=$1
cwd=$(pwd)

usage() 
{
cat << EOF
Usage: $0 [-d] [arg]

Backup the file given by arg with git versioning.

OPTIONS:

    -d    delete all the backups for the current directory

EOF
}

# default for options
DELETE=0

# parse the options
while getopts ':dh' opt ; do
  case $opt in
    d) DELETE=1;;
    h) usage ; exit 0;;
    ?) echo "Invalid option: -$OPTARG"; usage; exit 1;;
  esac
done

if [ $DELETE -eq 1 ]; then
    if [ -d .git ]; then
        /bin/rm -rf $cwd/{.git,.gitignore}
        cat $HOME/.git_backup.log | grep -v "$cwd"  > /dev/shm/.git_backup.log.tmp
        /bin/mv /dev/shm/.git_backup.log.tmp $HOME/.git_backup.log
        echo "All backups deleted for directory $cwd"
        exit 0
    else
        echo "fatal: Not a git repository (or any of the parent directories): .git"
        exit 1
    fi
fi

if [ -d .git ]; then
    echo "Git repository in $cwd already initialized"
else
    git init
    echo $(date +%s) $cwd >> $HOME/.git_backup.log
fi

git status -s | grep -e "^\?\?" | cut -c 4- >> .gitignore
sed -i "/^$filename$/d" .gitignore

git add $filename
git status -s
message=$(git status -s)
git commit -m "$message" $filename
