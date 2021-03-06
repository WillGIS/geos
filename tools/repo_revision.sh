#!/bin/sh

LC_ALL="C" # what for ?

[ -z "$top_srcdir" ] && top_srcdir="."
rev_file=$top_srcdir'/geos_revision.h'

read_rev() {

    if test -d $top_srcdir"/.svn"; then
      read_rev_svn
    elif test -d $top_srcdir"/.git"; then
      read_rev_git
    else
      echo "Can't fetch local revision (neither .svn nor .git found)" >&2
      echo 0
    fi
}

read_rev_git() {

  # TODO: test on old systems, I think I saw some `which`
  #       implementations returning "nothing found" or something
  #       like that, making the later if ( ! $svn_exe ) always false
  #
  git_exe=`which git`;
  if test -z "$git_exe"; then
    echo "Can't fetch SVN revision: no git executable found" >&2
    echo 0;
  fi

  last_commit=`cd ${top_srcdir} && ${git_exe} log -1`

  if test -z "$last_commit"; then
    echo "Can't fetch last commit info from git log" >&2
    echo 0
    return
  fi

  svnrev=`echo "$last_commit" | grep git-svn | cut -d@ -f2 | cut -d' ' -f1`
  if test -n "$svnrev"; then
    # Last commit has SVN metadata, we'll use that
    echo r$svnrev
    return
  fi

  # Last commit has no SVN metadata, we'll use sha
  sha=`cd ${top_srcdir} && ${git_exe} describe --always`
  echo $sha
}

read_rev_svn() {

  # TODO: test on old systems, I think I saw some `which`
  #       implementations returning "nothing found" or something
  #       like that, making the later if ( ! $svn_exe ) always false
  #
  svn_exe=`which svn`
  if test -z "$svn_exe"; then
    echo "Can't fetch SVN revision: no svn executable found" >&2
    echo 0;
  fi

  svn_info=`"${svn_exe}" info | grep 'Last Changed Rev:' | cut -d: -f2`

  if test -z "$svn_info"; then
    echo "Can't fetch SVN revision with `svn info`" >&2
    echo 0
  else
    echo r${svn_info}
  fi
}

write_defn() {
  rev=$1
  oldrev=0

  # Do not override the file if new detected
  # revision isn't zero nor different from the existing one
  if test -f $rev_file; then
    oldrev=`grep GEOS_REVISION ${rev_file} | awk '{print $2}'`
    if test "$rev" = 0 -o "$rev" = "$oldrev"; then
      echo "Not updating existing rev file at $oldrev" >&2
      return;
    fi
  fi

  echo "#define GEOS_REVISION \"$rev\"" | tee $rev_file
  echo "Wrote rev '$rev' in file '$rev_file'" >&2
}

# Read the svn revision number
svn_rev=`read_rev`

# Write it
write_defn $svn_rev
