#!/bin/bash

# Generated by POWSCRIPT (https://github.com/coderofsalvation/powscript)
#
# Unless you like pain: edit the .pow sourcefiles instead of this file

# powscript general settings
set -e                                # halt on error
set +m                                #
SHELL="$(echo $0)"                    # shellname
shopt -s lastpipe                     # flexible while loops (maintain scope)
shopt -s extglob                      # regular expressions
path="$(pwd)"
if [[ "$BASH_SOURCE" == "$0"  ]];then #
  SHELLNAME="$(basename $SHELL)"      # shellname without path
  selfpath="$( dirname "$(readlink -f "$0")" )"
  tmpfile="/tmp/$(basename $0).tmp.$(whoami)"
else
  selfpath="$path"
  tmpfile="/tmp/.dot.tmp.$(whoami)"
fi
#
# generated by powscript (https://github.com/coderofsalvation/powscript)
#

map () 
{ 
    local arr="$1";
    shift;
    local func="$1";
    shift;
    eval "for i in \"\${!$arr[@]}\"; do $func \"\$@\" \"\$i\" \"\${$arr[\$i]}\"; done"
}

math () 
{ 
    if [[ -n "$2" ]]; then
        which bc &> /dev/null && { 
            echo "scale=$2;$1" | bc
        } || echo "bc is not installed";
    else
        echo $(($1));
    fi
}



INVALID_ANS="Invalid answer"

print_kv(){
  local k="${1}"
  local v="${2}"
  echo "$k" "->" "$v"
}

print_map(){
  local m="${1}"
  map "$m" print_kv
}

div_rup(){
  local a="${1}"
  local b="${2}"
  a="$(math "$a")"
  b="$(math "$b")"
  math "(a + b - 1) / b"
}

ask_ans(){
  local ret="${1}"
  local msg="${2}"
  if [[ $# -le 1 ]]; then
    echo "Too few parameters"
    exit
  fi
  echo -ne "$msg"" : "
  read ans
  eval "$ret=$ans"
}

ask_yn(){
  local ret="${1}"
  local msg="${2}"
  if [[ $# -le 1 ]]; then
    echo "Too few parameters"
    exit
  fi
  while true; do
    echo -ne "$msg"" y/n : "
    read ans
    if [[ "$ans" == "y" ]]; then
      eval "$ret=true"
      break
    else
      if [[ "$ans" == "n" ]]; then
        eval "$ret=false"
        break
      else
        echo -e "$INVALID_ANS"
      fi
    fi
  done
}

ask_if_correct(){
  local ret="${1}"
  ask_yn "$ret" "Is this correct?"
}

default_wait=1
wait_and_clear(){
  local v="${1}"
  if [[ $# == 0 ]]; then
    sleep "$default_wait"
  else
    sleep "$v"
  fi
  clear
}

tell_press_enter(){
  echo "Press enter to continue"
  read
}

install_with_retries(){
  local package_name="${1}"
  if [[ $# == 0 ]]; then
    echo "Too few parameters"
    exit
  fi
  retries=5
  retries_left="$retries"
  while true; do
    echo "Installing ""$package_name"" package"
    arch-chroot "${config["mount_path"]}" pacman --noconfirm -S "$package_name"
    if [[ $? == 0 ]]; then
      break
    else
      retries_left="${[$retries_left - 1]}"
    fi
    if [[ "$retries_left" == 0 ]]; then
      echo "Package install failed ""$retries"" times"
      ask_yn change_name "Do you want to change package name before continuing retry?"
      if [[ "$change_name" ]]; then
        ask_new_name_end=false
        while [[ ! "$ask_new_name_end" ]]; do
          ask_ans package_name "Please enter new package name : "
          ask_if_correct ask_new_name_end
        done
      fi
      retries_left="$retries"
    fi
  done
}


declare -A config
config["a"]=4

print_config(){
  echo "${config["a"]}"
}

echo "$(div_rup config["a"] 3)"
print_config

config["ip_addr"]="$(ip route get 8.8.8.8 | awk "$awk_cmd")"
config["port"]=40001

end=false
while [[ "$end" == false ]]; do
  pass="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)"
  #
  echo "Transfer the PUBLIC key to the server using one of the following commands"
  echo "cat PUBKEY | gpg -c | nc ${config["ip_addr"]} ${config["port"]} # enter passphrase $pass when prompted"
  echo "or"
  echo "cat PUBKEY | gpg --batch --yes --passphrase $pass -c | nc ${config["ip_addr"]} ${config["port"]}"
  #
  nc -lp "${config["port"]}" > pub_key.gpg
  echo "File received"
  echo "Decrypting file"
  gpg --batch --yes --passphrase "$pass" --decrypt pub_key.gpg > pub_key
  if [[ $? == 0 ]]; then
    echo "SHA256 hash of decrypted file :" "$(sha256sum pub_key)"
    #
    ask_end=false
    while [[ "$ask_end" == false ]]; do
      ask_ans match "Does the hash match the hash of the original file?"
      ask_if_correct ask_end
    done
    if [[ $=~ == true ]]; then
      break
    else
      :
    fi
  else
    echo "Decryption failed"
  fi
done

# wait for all async child processes (because "await ... then" is used in powscript)
[[ $ASYNC == 1 ]] && wait


# cleanup tmp files
if ls /tmp/$(basename $0).tmp.darren* &>/dev/null; then
  for f in /tmp/$(basename $0).tmp.darren*; do rm $f; done
fi

exit 0

