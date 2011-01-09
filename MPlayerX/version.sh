#!/bin/bash

git rev-list HEAD | sort > config.git-hash
LOCALVER=`wc -l config.git-hash | awk '{print $1}'`

if [ $LOCALVER \> 1 ] ; then
    VER=`git rev-list origin/master | sort | join config.git-hash - | wc -l | awk '{print $1}'`

    if [ $VER != $LOCALVER ] ; then
        VER="$VER+$(($LOCALVER-$VER))"
    fi
    
	## 1028 is the base of the svn version
    VER=`expr ${VER} + 1028`
    
    if git status | grep -q "modified:" ; then
        VER="${VER}.1"
    else
    	VER="${VER}.0"
    fi
    echo $VER

else
    VER="unknown"
fi
rm -f config.git-hash