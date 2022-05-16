==========================
# Create ssh-keygen
  ls -al ~/.ssh
  ssh-keygen -q -t rsa -N '' -m PEM -t rsa -b 4096 -C test -f ./id_rsa <<<y >/dev/null 2>&1
  eval `ssh-agent`
  ssh-add ~/.ssh/id_rsa
  ssh-add -l