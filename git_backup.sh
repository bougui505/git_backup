#!/usr/bin/env sh
# -*- coding: UTF8 -*-

filename=$1
cwd=$(pwd)

if [ -d .git ]; then
    echo "Git repository in $cwd already initialized"
else
    git init
fi

git status -s | grep -e "^\?\?" | cut -c 4- >> .gitignore
sed -i "/^$filename$/d" .gitignore

git add -A
git status -s
message=$(git status -s)
git commit -a -m "$message"
