#!/usr/bin/env sh
# -*- coding: UTF8 -*-

filename=$1
cwd=$(pwd)

usage() 
{
cat << EOF
Usage: $0 [-d] [-i] [-x arg] [arg]

Backup the file given by arg with git versioning.

OPTIONS:

    -d              Delete all the backups for the current directory
    -i              Add untracked files to .gitignore
    -x filename     Permanently remove 'filename' from backup. The git
                    history is removed too. The local file 'filename'
                    is not removed.
    -a              Backup all files already under version control for 
                    the current directory
    -A              Backup all files already under version control for
                    all directories listed in $HOME/.git_backup.log
EOF
}

git_exception()
{
    echo "fatal: Not a git repository: .git"
    exit 1
}

git_backup_db_exception()
{
    if grep -E "$cwd$" $HOME/.git_backup.log; then
        return 0
    else
    cat << EOF
$cwd is not present in $HOME/.git_backup.log, this local repository
do not seem to be created by $0
EOF
        exit 1
    fi
}

add_to_gitignore()
{
    git status -s | awk '{if ($1 == "??") print $2}' >> .gitignore
}

delete_backuped_file()
{
    git_backup_db_exception
    filename=$1
    if [ -f $filename ]; then
        git rm --cached $filename
        backup_all_files
        git filter-branch --tree-filter "/bin/rm -f $filename"
        /bin/rm -rf .git/refs/original
        add_to_gitignore
    else
        echo "No such file $filename or $filename is not a regular file!"
    fi
}

backup_all_files()
{
    message=$(git status -s)
    git commit -a -m "$message"
}

backup_all()
{
    cwd=$(pwd)
    for x in $(cat $HOME/.git_backup.log | awk '{print $2}'); do
        if [ -d $x ]; then
            cd $x
            echo "############"
            pwd
            if [ -d .git ]; then
                message=$(git status -s)
                git commit -a -m "$message"
            else
                git_exception
            fi
        else
            echo "$x is present in $HOME/.git_backup.log but absent from the disk"
            echo "delete entry $x from $HOME/.git_backup.log"
            cat $HOME/.git_backup.log | grep -Ev "$x$"  > /dev/shm/.git_backup.log.tmp
            /bin/mv /dev/shm/.git_backup.log.tmp $HOME/.git_backup.log
        fi
    done
    exit 0
}

main()
{
    if [ -d .git ]; then
        echo "Git repository in $cwd already initialized"
    else
        git init
        echo $(date +%s) $cwd >> $HOME/.git_backup.log
    fi
    git_backup_db_exception
    add_to_gitignore
    sed -i "/^$filename$/d" .gitignore

    git add $filename
    git status -s
    message=$(git status -s $filename)
    git commit -m "$message" $filename
}

# default for options
DELETE=0
IGNORE=0
XFILE=0
ALL=0
ALLDIRS=0

# parse the options
while getopts ':dix:aAh' opt ; do
  case $opt in
    d) DELETE=1;;
    i) IGNORE=1;;
    x) XFILE=$OPTARG;;
    a) ALL=1;;
    A) ALLDIRS=1;;
    h) usage ; exit 0;;
    ?) echo "Invalid option: -$OPTARG or argument required"; usage; exit 1;;
  esac
done

if [ $DELETE -eq 1 ]; then
    if [ -d .git ]; then
        git_backup_db_exception
        /bin/rm -rf $cwd/.git $cwd/.gitignore
        echo "delete entry $cwd from $HOME/.git_backup.log"
        cat $HOME/.git_backup.log | grep -Ev "$cwd$"  > /dev/shm/.git_backup.log.tmp
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

if [ $XFILE != 0 ]; then
    if [ -d .git ]; then
        delete_backuped_file $XFILE
        exit 0
    else
        git_exception
    fi
fi

if [ $ALL -eq 1 ]; then
    git_backup_db_exception
    if [ -d .git ]; then
        backup_all_files
        exit 0
    else
        git_exception
    fi
fi

if [ $ALLDIRS -eq 1 ]; then
    backup_all
fi

main
