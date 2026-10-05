# oem-aa-mod Installer

Installer package for [oem-aa-mod](https://github.com/VitaliyKurokhtin/oem-aa-mod) — adds Android Auto support to Mazda CMU (MZD Connect).

`run.sh` is an all-in-one script that handles both **installing** and **uninstalling** the mod. It will prompt you to choose when run.

Releases are built automatically whenever a new upstream version is published. Download the latest `oem-aa-mod-<version>-installer.zip` from the [Releases](https://github.com/Bijan-A/oem-aa-mod-installer/releases) page.

## Requirements

- Firmware version **74.00.324**
- USB flash drive **32 GB or smaller**, formatted as **FAT32**
- USB keyboard

## Installation / Uninstallation

1. Extract the zip and copy all files to the **root directory** of your flash drive.

1. Safely eject the drive and plug it into your Mazda.

1. Plug keyboard in secondary USB port of your Mazda

1. In the car, navigate to the **Entertainment** menu and select the **USB Drive**.

1. Wait a couple of seconds — the diagnostic menu should launch automatically.

1. In the diagnostic menu, open a terminal (click 'Next', then 'Terminal') and run:

   ```sh
   cd /tmp/mnt/sda1
   ```

   > If nothing happens, try `cd /tmp/mnt/sdb1` instead — this depends on which USB port you used.

1. Run the script:

   ```sh
   sh run.sh
   ```

1. Follow the on-screen prompts to install or uninstall. Once complete, reboot the head unit.

## Credits

- [VitaliyKurokhtin/oem-aa-mod](https://github.com/VitaliyKurokhtin/oem-aa-mod) — the mod itself
