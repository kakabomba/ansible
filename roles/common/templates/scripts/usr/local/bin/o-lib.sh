#!/usr/bin/env bash

function 2lines { cat | xargs | sed -e 's/ /\n/g'; }

function 2spaces { cat | xargs; }

function strip_new_lines { echo "$*" | sed '/^\s*$/d'; }

function _e { echo "$*" 1>&2; logger -p local0.error "$*"; exit 1; }

function _w { echo "$*" 1>&2; logger -p local0.warning "$*"; }

function _n { echo "$*" 1>&2; logger -p local0.notice "$*"; }

function _d { echo "$*" 1>&2; logger -p local0.debug "$*"; }

function is_dir {
  if [ ! -e "$1" ]; then
    _w "$1" dont exists
    echo "0"
  elif [ ! -d "$1" ]; then
    _w "$1" is not directory
    echo "0"
  else
    echo "1"
  fi
}

function rm_in_dir_if_exists {
  if [ ! ""$(echo "$*" | xargs) ]; then
     _w nothing passed to rm_in_dir_if_exists
     return 1
  fi
  for f in $*; do
      local ft=$(echo $f | sed -e 's#/$##')
      _n removing $ft
      if [ $(is_dir $f) ]; then
          rm -rf $f/*
      fi
  done
}


function lower { cat | tr '[:upper:]' '[:lower:]'; }

function join_by { cat | 2spaces | sed -e "s/ /$1/g"; }


function md5_dir {
  find $1 -xtype f -print0 | xargs -0 sha1sum | cut -b-40 | sort | sha1sum
}

function md5_file {
  sha1sum $1 | cut -b-40
}


function sync_dirs {

  local srcdir=$(echo $1 | sed -e 's#/$##')
  local dstdir=$(echo $2 | sed -e 's#/$##')

  _n "syncing $srcdir and $dstdir"

  if [ ! $(is_dir $srcdir) ]; then
    return 2
  fi
  if [ ! $(is_dir $dstdir) ]; then
    return 2
  fi
  local srcmd5=md5_dir $srcdir
  local dstmd5=md5_dir $dstdir

  if [[ "$srcmd5" == "$dstmd5" ]]; then
    _n "md5 are the same: $srcmd5"
    return 1
  else
    _n "md5 differ for md5($srcdir)=$srcmd5!=md5($dstdir)=$dstmd5, syncing"
    rsync -r --force --del $srcdir/ $dstdir/
    return 0
  fi
}

function host_is_up {
  if [[ $(nmap -sP --max-retries=1 $1 | grep '1 host up') == '' ]]; then
    return 0
  else
    return 1
  fi
}

function is_fqdn {
  if [[ ! $1 =~ ^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)*[a-zA-Z](-?[a-zA-Z0-9])+\.[a-zA-Z]{2,}$ ]]; then
    return 1
  else
    return 0
  fi
}

#TODO complete email regexp
function is_email {
  if [[ ! $1 =~ @ ]]; then
    return 1
  else
    return 0
  fi
}

function file_timestamp {
  local tm=$(stat $1 | grep "^Change: " | sed -e 's/^Change: //g')
  date -d "$tm" +"%s"
}

function pid_cleanup {
  local basen=$(basename $0)
  local pid_file="/var/run/$basen.pid"
  rm $pid_file
}

function run_script_only_once {
  local basen=$(basename $0)
  local pid_file="/var/run/$basen.pid"
  if [ -f $pid_file ]; then
    _e "$basen currently running under pid $(cat $pid_file). you can try: kill -9 $(cat $pid_file); rm $pid_file"
  else
    echo $$ > $pid_file
    trap pid_cleanup EXIT
  fi
}
