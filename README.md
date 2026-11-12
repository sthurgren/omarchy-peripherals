# Omarchy Peripherals

An [Omarchy](https://omarchy.org/) bar widget that shows the battery levels of wireless mice, keyboards, headsets and other devices reported by UPower.

- The bar icon shows the device with the lowest battery and turns red when it runs low.
- Click the icon to see each device with its level.
- The widget hides itself when no devices are connected.
- Data comes from UPower over D-Bus, with no polling.

Logitech HID++ devices (MX Keys, MX Master and others) only report coarse levels. UPower maps these to fixed percentages, so the widget shows levels (Full, High, Good, Low, Critical) instead of percentages.

## Install

```bash
omarchy plugin add https://github.com/sthurgren/omarchy-peripherals.git --enable
```

Update with `omarchy plugin update sthurgren.peripherals`.

## Low battery notifications (optional)

`extras/peripheral-battery-notify` sends an Omarchy notification when a device reaches a low or critical battery level, once per level. It runs as a systemd user service:

```bash
systemctl --user enable --now ~/.config/omarchy/plugins/sthurgren.peripherals/extras/peripheral-battery-notify.service
```

If you use a Logitech companion app such as OpenLogi, turn off its own low battery notices to avoid duplicates.

## Requirements

- Omarchy with the Quickshell-based shell
- UPower
- BlueZ, for Bluetooth device batteries

## License

MIT
