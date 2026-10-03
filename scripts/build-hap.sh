#!/bin/zsh
set -euo pipefail

deveco_studio_home="${DEVECO_STUDIO_HOME:-/Applications/DevEco-Studio.app}"
hvigorw="${deveco_studio_home}/Contents/tools/hvigor/bin/hvigorw"
sdk_home="${deveco_studio_home}/Contents/sdk"

if [[ ! -x "${hvigorw}" || ! -d "${sdk_home}" ]]; then
  print -u2 "DevEco Studio was not found at ${deveco_studio_home}."
  print -u2 "Set DEVECO_STUDIO_HOME to your DevEco-Studio.app location and retry."
  exit 1
fi

DEVECO_SDK_HOME="${sdk_home}" "${hvigorw}" --mode module \
  -p module=entry@default -p product=default assembleHap
