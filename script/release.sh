#!/bin/bash
if test `uname` = 'Darwin'; then
  sed -i '' -e "s;github.com/PredixDev;github.com/PredixDev;" ./campaign.sh
else
  sed -i -e "s;github.com/PredixDev;github.com/PredixDev;" ./campaign.sh
fi
