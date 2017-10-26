#!/bin/bash

if test "`whoami`" != "root";then exit;fi
mkdir -p /opt/bin
git clone https://github.com/muonium/deploy
cd deploy && cp deploy /opt/bin && cd - &>/dev/null
chmod 700 /opt/bin/deploy
echo "export PATH=$PATH:/opt/bin" >> /root/.bashrc
export PATH=$PATH:/opt/bin
exit
