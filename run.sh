#!/bin/sh
# oem-aa-mod installer/uninstaller for Mazda CMU
# created by Bijan
# https://github.com/VitaliyKurokhtin/oem-aa-mod

hwclock --hctosys

echo 1 > /sys/class/gpio/Watchdog\ Disable/value
mount -o rw,remount /

MYDIR=$(dirname "$(readlink -f "$0")")
mount -o rw,remount ${MYDIR}

mkdir -p "${MYDIR}/logs"

# --- Prompt user: Install or Uninstall ---
/jci/tools/jci-dialog --question \
  --title="oem-aa-mod" \
  --text="What would you like to do?" \
  --ok-label="Install" \
  --cancel-label="Uninstall"
CHOICE=$?

if [ $CHOICE -eq 0 ]
then
  # ============================================================
  # INSTALL
  # ============================================================
  exec > "${MYDIR}/logs/install.log" 2>&1
  echo "=== oem-aa-mod install start ==="

  /jci/tools/jci-dialog --info --title="oem-aa-mod" --text="Installing oem-aa-mod...\nDo not remove USB drive." --no-cancel &

  # --- Read use_protocol_v1_6 from the config being deployed ---
  # aap_service is only needed for GAL 1.6; default (missing file or key) is false.
  CONF="${MYDIR}/resources/libpatch.conf"
  USE_PROTOCOL_V16="false"
  if [ -f "${CONF}" ]
  then
    val=$(sed 's/#.*//' "${CONF}" \
            | grep -i '^[[:space:]]*use_protocol_v1_6[[:space:]]*=' \
            | tail -n1 | cut -d'=' -f2- | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    case "${val}" in
      true|1|yes|on) USE_PROTOCOL_V16="true" ;;
    esac
  fi
  echo "use_protocol_v1_6 = ${USE_PROTOCOL_V16} (from ${CONF})"

  # --- Backup and patch jciAAPA in sm.conf and sm_WCP.conf ---
  for conf in sm.conf sm_WCP.conf
  do
    if [ ! -e "/jci/sm/${conf}.orig" ]
    then
      cp -a "/jci/sm/${conf}" "/jci/sm/${conf}.orig"
      echo "Backed up ${conf}"
    else
      echo "${conf} backup already exists"
    fi

    if ! grep -q "libpatch-blmjciaapa" "/jci/sm/${conf}"
    then
      sed -i '/name="jciAAPA"/a\            <environ_var env_name="LD_PRELOAD" env_value="/data_persist/oem-aa-mod/libpatch-blmjciaapa.so"/>' "/jci/sm/${conf}"
      echo "Patched jciAAPA in ${conf}"
    else
      echo "jciAAPA already patched in ${conf}, skipping"
    fi

    if ! grep -q "libpatch-svcjcinavi" "/jci/sm/${conf}"
    then
      sed -i '/name="jcinavi"/a\            <environ_var env_name="LD_PRELOAD" env_value="/data_persist/oem-aa-mod/libpatch-svcjcinavi.so"/>' "/jci/sm/${conf}"
      echo "Patched jcinavi in ${conf}"
    else
      echo "jcinavi already patched in ${conf}, skipping"
    fi

    if [ "${USE_PROTOCOL_V16}" = "true" ]
    then
      if ! grep -q "libpatch-aap_service" "/jci/sm/${conf}"
      then
        sed -i '/name="aap_service"/a\            <environ_var env_name="LD_PRELOAD" env_value="/data_persist/oem-aa-mod/libpatch-aap_service.so"/>' "/jci/sm/${conf}"
        echo "Patched aap_service in ${conf}"
      else
        echo "aap_service already patched in ${conf}, skipping"
      fi
    else
      echo "use_protocol_v1_6 is false, skipping aap_service patch in ${conf}"
    fi
  done

  # --- Install libraries ---
  mkdir -p /data_persist/oem-aa-mod
  cp "${MYDIR}/libpatch-blmjciaapa.so" /data_persist/oem-aa-mod/
  echo "libpatch-blmjciaapa.so has been copied"
  cp "${MYDIR}/libpatch-svcjcinavi.so" /data_persist/oem-aa-mod/
  echo "libpatch-svcjcinavi.so has been copied"
  if [ "${USE_PROTOCOL_V16}" = "true" ]
  then
    cp "${MYDIR}/libpatch-aap_service.so" /data_persist/oem-aa-mod/
    echo "libpatch-aap_service.so has been copied"
  else
    echo "use_protocol_v1_6 is false, skipping libpatch-aap_service.so copy"
  fi
  cp "${MYDIR}/resources/libpatch.conf" /data_persist/oem-aa-mod/
  echo "libpatch.conf has been copied"
  chmod 0644 /data_persist/oem-aa-mod/libpatch-*.so

  # --- Backup and install XML configs ---
  for xml in aap_system_attributes.xml aap_system_attributes_UCP.xml
  do
    if [ ! -e "/etc/${xml}.orig" ]
    then
      cp -a "/etc/${xml}" "/etc/${xml}.orig"
      echo "Backed up ${xml}"
    else
      echo "${xml}.orig already exists, skipping backup"
    fi
    cp "${MYDIR}/resources/${xml}" "/etc/${xml}"
    echo "Installed ${xml}"
  done

  sync
  echo "=== oem-aa-mod install complete ==="

  killall -q jci-dialog
  /jci/tools/jci-dialog --info --title="oem-aa-mod" --text="Installation complete!\nYou can remove the USB drive.\nRebooting in 5 seconds..." --no-cancel &

else
  # ============================================================
  # UNINSTALL
  # ============================================================
  exec > "${MYDIR}/logs/uninstall.log" 2>&1
  echo "=== oem-aa-mod uninstall start ==="

  /jci/tools/jci-dialog --info --title="oem-aa-mod" --text="Uninstalling oem-aa-mod...\nDo not remove USB drive." --no-cancel &

  # --- Restore sm.conf and sm_WCP.conf ---
  for conf in sm.conf sm_WCP.conf
  do
    if [ -e "/jci/sm/${conf}.orig" ]
    then
      cp -a "/jci/sm/${conf}.orig" "/jci/sm/${conf}"
      rm "/jci/sm/${conf}.orig"
      echo "Restored ${conf} from backup"
    else
      echo "WARNING: ${conf}.orig not found; removing LD_PRELOAD lines manually"
      sed -i '/env_value="\/data_persist\/oem-aa-mod\//d' "/jci/sm/${conf}"
      echo "Removed LD_PRELOAD entries from ${conf}"
    fi
  done

  # --- Restore XML configs ---
  for xml in aap_system_attributes.xml aap_system_attributes_UCP.xml
  do
    if [ -e "/etc/${xml}.orig" ]
    then
      cp -a "/etc/${xml}.orig" "/etc/${xml}"
      rm "/etc/${xml}.orig"
      echo "Restored ${xml} from backup"
    else
      echo "WARNING: ${xml}.orig not found, skipping restore"
    fi
  done

  # --- Remove installed libraries and config ---
  rm -f /data_persist/oem-aa-mod/libpatch-blmjciaapa.so
  echo "Removed libpatch-blmjciaapa.so"
  rm -f /data_persist/oem-aa-mod/libpatch-svcjcinavi.so
  echo "Removed libpatch-svcjcinavi.so"
  rm -f /data_persist/oem-aa-mod/libpatch-aap_service.so
  echo "Removed libpatch-aap_service.so"
  rm -f /data_persist/oem-aa-mod/libpatch.conf
  echo "Removed libpatch.conf"
  rmdir /data_persist/oem-aa-mod 2>/dev/null && echo "Removed /data_persist/oem-aa-mod directory"

  sync
  echo "=== oem-aa-mod uninstall complete ==="

  killall -q jci-dialog
  /jci/tools/jci-dialog --info --title="oem-aa-mod" --text="Uninstall complete!\nYou can remove the USB drive.\nRebooting in 5 seconds..." --no-cancel &

fi

sleep 5
killall -q jci-dialog
reboot
exit 0
