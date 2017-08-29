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
  local srcmd5=$(md5_dir "$srcdir")
  local dstmd5=$(md5_dir "$dstdir")

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
  if [[ ! $1 =~ ^(([a-zA-Z](-*[a-zA-Z0-9]*)*)\.)*[a-zA-Z](-*[a-zA-Z0-9]*)+\.[a-zA-Z](-*[a-zA-Z0-9]*)+$ ]]; then
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

  function try_again_later {

    local n=${#BASH_ARGV[@]}
    local b_args=( )
    if (( $n > 0 ))
    then
        # Get the last index of the args in BASH_ARGV.
        local n_index=$(( $n - 1 ))

        # Loop through the indexes from largest to smallest.
        for i in $(seq ${n_index} -1 0)
        do
          b_args+=('"'"${BASH_ARGV[$i]}"'"')
        done
    fi
    local try_again_run_in_minutes="$1"
    if [[ "$try_again_run_in_minutes" -gt 0 ]]; then
      for atno in $(atq | cut -f1); do
        if [[ $(at -c $atno | grep $2) ]]; then
          _w "removing at with number $atno"
          atrm $atno
        fi
      done
      local apwd=$(pwd)
      _w "starting $apwd/$2 ${b_args[@]} | at now + $try_again_run_in_minutes minute"
      echo "$apwd/$2 ${b_args[@]}" | at now + "$try_again_run_in_minutes" minute
    fi
    }

  local basen=$(basename $0)
  local pid_file="/var/run/$basen.pid"
  local force_stop_in_minutes=$2
  if [ -f $pid_file ]; then
    if [[ "$force_stop_in_minutes" -gt 0 ]]; then
      local time_of_pid_file=$(file_timestamp $pid_file)
      local time_now=$(date +"%s")
      local time_to_restart=$(($time_of_pid_file + $force_stop_in_minutes*60 - $time_now ))
      _w "time to force restart time_to_restart=(time_of_pid_file=$time_of_pid_file + force_stop_in_seconds=$force_stop_in_minutes*60 - time_now=$time_now )=$time_to_restart<0"
      if [[ "$time_to_restart" -lt "0" ]]; then
        _w "force restarting $(basename $0)"
        kill -9 $(cat $pid_file)
        rm $pid_file
        echo $$ > $pid_file
        trap pid_cleanup EXIT
      else
        try_again_later "$1" "$basen"
        _e "$basen currently running under pid $(cat $pid_file). force rerunuing in $time_to_restart seconds"
      fi
    else
      try_again_later "$1" "$basen"
      _e "$basen currently running under pid $(cat $pid_file). you can try: kill -9 $(cat $pid_file); rm $pid_file"
    fi
  else
    echo $$ > $pid_file
    trap pid_cleanup EXIT
  fi
}

function iptables_flush {
  iptables -F
  iptables -X
  iptables -t nat -F
  iptables -t nat -X
  iptables -t mangle -F
  iptables -t mangle -X
  iptables -P INPUT ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT ACCEPT
}

function iptables_show {
  iptables -t nat -L --line-numbers -n
  iptables -t filter -L --line-numbers -n
  iptables -t mangle -L --line-numbers -n
}

function yn {
  local choice=''
  while true; do
    read -p "${1?'Continue'} (y/n)?" choice
    case "$choice" in
      y|Y|yes|Yes|YES|tak ) return 0;;
      n|N|No|NO|no|ni ) return 1;;
      * ) echo "pls answer y|Y|yes|Yes|YES|tak|n|N|No|NO|no|ni";;
    esac
  done
}

