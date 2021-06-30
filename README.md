# smartos-netboot-server

This repo configures a SmartOS zone to serve platform images for booting
via iPXE. It's primarily intended to support [netboot.xyz][1], but it can
also be used to provide netboot for a local environment.

[1]: https://netboot.xyz

## Using

In order to netboot from this server, chain load `/smartos.ipxe`. You can boot
from Joyent's netboot server by loading
<https://netboot.smartos.org/smartos.ipxe> or
<https://netboot.joyent.com/smartos.ipxe>.

## Set up

To set up a new server, clone this repository into a base-64-lts@19.4.0 or
later SmartOS zone (generally at `/opt/netboot`) and run `tools/setup.sh`.
This setup is configured for Joyent's usage (e.g., Joyent domains forLet's
Encrypt), but you can fork and customize as necessary. We'll accept pull
requests to make it more generic provided that the default behavior still
works for us non-interactively.

Note: As setup begins, `triton.cns.status` metadata key is set to `down`
to prevent joining the CNS name during setup. Once setup is complete, it is
left in a `down` state so that you can pre-load any images before making the
server available.

## Adding platform images

You can use `tools/fetch_pi.sh` to install a new platform by its timestamp.

Once per day, a cron job runs that looks for new images. We publish new images
every two weeks, but sometimes they might be late.

### Additional Images

You can add additional images (e.g., experimental features) by naming the
directory `<something>-<platform_version>`. These will be added to the menu
after release images, but there's no automatic management mechanism. They need
to be added to, and removed from, the directory manually.
