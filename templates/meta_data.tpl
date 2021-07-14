#cloud-config
local-hostname: ${hostname}

growpart:
  mode: auto
  devices: ['/']
  ignore_growroot_disabled: false