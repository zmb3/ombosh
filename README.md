# ombosh.sh

Use the BOSH CLI against the Operations Manager director

This script requires the [`om`](https://github.com/pivotal-cf/om) CLI.

It assumes that the CLI named `om` and placed on your `$PATH`.
You can override the name of the CLI with the `-c` option.

For example: `./ombosh -c om-linux ...`

## Usage:

```
❯ source ./ombosh.sh -t opsman.example.com
Ops Manager Password:
Path to SSH private key for OM:

❯ bosh env
Using environment '10.0.0.21' as client 'ops_manager'

Name      p-bosh
UUID      e92983bf-50a5-4432-960c-f0ff1fda6e1b
Version   265.2.0 (00000000)
CPI       google_cpi
Features  compiled_package_cache: disabled
          config_server: enabled
          dns: disabled
          snapshots: disabled
User      ops_manager

Succeeded
```
