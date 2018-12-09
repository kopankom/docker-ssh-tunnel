#!/usr/bin/expect
set SSH_FILE [lindex $argv 0]
set SSH_PASSPHRASE [lindex $argv 1]
spawn ssh-add "/home/ssh/.ssh/$SSH_FILE"
expect "Enter passphrase for *"
send "$SSH_PASSPHRASE\n";
expect "Identity added: *"
interact
