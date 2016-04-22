#! /bin/bash

# This script runs through a checklist of common security features and outputs the user's security level.
# For best results, run this on your UDE and on your local machine.

cecho() {
  local code="\033["
  case "$1" in
    black  | bk) color="${code}0;30m";;
    red    |  r) color="${code}1;31m";;
    green  |  g) color="${code}1;32m";;
    yellow |  y) color="${code}1;33m";;
    blue   |  b) color="${code}1;34m";;
    purple |  p) color="${code}1;35m";;
    cyan   |  c) color="${code}1;36m";;
    gray   | gr) color="${code}0;37m";;
    *) local text="$1"
  esac
  [ -z "$text" ] && local text="$color$2${code}0m"
  printf "$text"
}

# Success or Fail
sof() {
  if $1; then
    echo -n "["
    cecho g "✓"
    echo -n "]"
  else
    echo -n "["
    cecho r "✗"
    echo -n "]"
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Begin user input
echo -n "Enter the password for your account (Note: this script does not save the password): "
IFS= read -rs PASSWD
echo
echo -n "Enter the path to your private ssh keys ($HOME/.ssh/): "
read user_ssh_location
echo

if [[ -n "$user_ssh_location" ]]; then
  ssh_location=$user_ssh_location
else
  ssh_location="$HOME/.ssh/"
fi

cecho y "Password Checks:"
echo
passwd_check=0
passwd_count=0
sudo -k
if sudo -lS &> /dev/null << EOF
$PASSWD
EOF
then
  sof true
  echo " Correct Password"
  ((passwd_check += 1))
  ((passwd_count += 1))

  # Check length of password
  if [[ ${#PASSWD} -lt 8 ]]; then
    sof false
    echo " Password is too short (8 or more is recommended)"
  else
    sof true
    echo " Password length is good"
    ((passwd_check += 1))
  fi
  ((passwd_count += 1))

  # Check if password contains numbers
  if [[ $PASSWD =~ [0-9] ]]; then
    sof true
    echo " Password contains numbers"
    ((passwd_check += 1))
  else
    sof false
    echo " Password does not contain numbers"
  fi
  ((passwd_count += 1))

  # Check if password contains letters
  if [[ $PASSWD =~ [A-Za-z] ]]; then
    sof true
    echo " Password contains letters"
    ((passwd_check += 1))
  else
    sof false
    echo " Password does not contain letters"
  fi
  ((passwd_count += 1))

  # Check if password contains digits
  if [[ $PASSWD =~ [^A-Za-z0-9] ]]; then
    sof true
    echo " Password contains punctuation"
    ((passwd_check += 1))
  else
    sof false
    echo " Password does not contain punctuation"
  fi
  ((passwd_count += 1))

else
  sof false
  echo ' Wrong password.'
  ((passwd_count += 1))
fi

echo
cecho b "Score: "
echo "[$passwd_check/$passwd_count]"
echo

cecho y "SSH Checks:"
echo
ssh_check=0
ssh_count=0

for file in $ssh_location/*; do
  # This file throws a grep error
  if [[ ${file#${ssh_location}} != '/ssh_auth_sock' ]]; then
    if [[ $(grep -E '(-----BEGIN RSA PRIVATE KEY-----)' $file) ]]; then
      ((ssh_count += 1))
      if [[ $(grep ENCRYPTED $file) ]]; then
        sof true
        echo " ${file#${ssh_location}} Encrypted"
        ((ssh_check += 1))
      else
        sof false
        echo " ${file#${ssh_location}} Not Encrypted"
      fi
    fi
  fi
done

echo
cecho b "Score: "
echo "[$ssh_check/$ssh_count]"
echo


cecho y "Encryption Checks:"
echo
encrypt_check=0
encrypt_count=0

if command_exists sw_vers; then
  CORESTORAGESTATUS="/private/tmp/corestorage.txt"
  ((encrypt_count+=1))
  response=`source ./external/filevault_2_encryption_check.sh`
  if [[ $response =~ "FileVault 2 Encryption Not Enabled" ]]; then
    sof false
    echo " FileVault 2 Encryption Not Enabled"
  elif [[ $response =~ "Unknown Version Of Mac OS X"]]
    sof false
    echo " Unknown Version Of Mac OS X"
  else
    sof true
    echo " FileVault 2 Encryption Enabled"
    ((encrypt_check+=1))
  fi
else
  ((encrypt_count+=1))
  if [ -d $HOME/.ecryptfs ]; then
    sof true
    echo " Home Encryption Enabled"
    ((encrypt_check+=1))
  else
    sof false
    echo " Home Encryption Disabled"
  fi
fi

echo
cecho b "Score: "
echo "[$encrypt_check/$encrypt_count]"
echo
