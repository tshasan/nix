# Desktop monitor: Alienware AW3226Q

Measured on `desktop` on 2026-11-27: GNOME 51.1, GDM 51.0, NVIDIA 615.78.08,
RTX 4070 SUPER, connector `DP-3`, ddcutil 3.0.2, edid-decode 1.32.0.

**Status key:** **Read** = read straight from the monitor or driver ·
**Derived** = calculated from read values · **Inferred** = reasoning that
nobody has measured yet.

---

## The finding: one line rate, one honest mode

The monitor draws scan lines at **a single fixed rate, about 386 kHz**, and
gets every refresh rate by adding blank lines. Three separate sources agree:

| Source | Value | Status |
|---|---|---|
| EDID Display Range Limits | H **386–386 kHz** (one value, not a range), V 48–165 Hz | Read |
| DisplayID 4K@165 timing | 4000 px/line × 2338 lines @ 1543 MHz = **385.75 kHz** | Read |
| DDC/CI VCP `0xAC` (horizontal frequency) | raw `58920`, "max" `5` | Read |

ddcutil prints `0xAC` as "58920 Hz", but the field is 24 bits wide and ddcutil
puts the high byte in the "max" slot: `5 × 65536 + 58920 = 386,600 Hz`.
That's the scaler's own measurement of the incoming line rate, and it matches the EDID
to within 0.2 %. (`0xAE` reads `16500` = 165.00 Hz.)

What this means (**Derived**):

- **VRR works by changing the vertical blank only.** A 165 Hz frame is 2338
  lines (2160 active + 178 blank). At the 48 Hz floor the same line rate
  gives ~8036 lines per frame, so ~5900 of them are blank. The panel never
  scans more slowly, it just waits longer.
- **4K@165 is the panel's native mode. Every other mode gets converted.**
  The 4K@60 timing in the base EDID runs at 133 kHz, and the CTA 4K@120 (VIC
  118) at 270 kHz. Neither matches the 386 kHz the panel scans at, so the
  scaler has to buffer and re-time them. TFTCentral measured **1.3 ms** total
  lag at 165 Hz, ~5.6 ms at 120 Hz and **~25 ms at 60 Hz**, which fits a
  frame being buffered.
- **The EDID marks the slow mode as preferred.** The first DTD in the
  base block, which the spec treats as preferred, is **4K@60**. The
  DisplayID block holding the 165 Hz timings has no preferred flag at all
  (edid-decode: `DisplayID expects at least one preferred timing`, so
  conformity FAILs). The kernel and mutter both report `3840×2160@60
  preferred`. Anything that falls back to "preferred" gets the ~25 ms mode:
  the GDM greeter, a fresh user, or a deleted `monitors.xml`.

**So:** for 60 fps content (video, capped games), stay at 4K@165 with VRR
on. Don't switch the mode to 60 Hz. The panel handles low frame rates with
blank lines (LFC below 48 Hz), and the converted 60 Hz mode is the laggy one.

**Applied:** the GDM greeter now gets the session's mode (4K@164.991 VRR,
1.25×). GDM 51 reads greeter config from `/var/lib/gdm/seat0/config`, which
had no `monitors.xml`. `modules/files/gnome/monitors-desktop.xml` is linked
there by tmpfiles from `modules/hosts/desktop/configuration.nix`.
**Inferred** until checked at the next logout: the greeter should come up at
165 Hz.

---

## Identity

| | | |
|---|---|---|
| Model | Alienware AW3226Q, Dell `DEL` 0xA2F0 (41712) | Read |
| Serial | `158XPL4` (binary serial field holds ASCII `LXO1`) | Read |
| Built | week 43 of 2026 | Read |
| Panel | 31.5″ LG Display RGB-stripe Tandem WOLED (white subpixel removed) | Review |
| Scaler | Realtek (`0xC8` = 0x09, controller 0x2738), firmware **65.2** | Read |
| DDC/CI | MCCS 2.1 on `/dev/i2c-6`; reports `type(LCD)` but `0xB6` = OLED | Read |
| Subpixel layout | `0xB2` = **RGB vertical stripe**, which confirms the `rgba`/`rgb` font setting in `home.nix` | Read |
| Geometry | 697 × 392 mm, **139.9 PPI**, so 1.25× is ~112 effective PPI | Derived |
| Inputs | 1× DP 1.4 (DSC), 2× HDMI 2.1 FRL; USB-C is data/15 W only, no video | Review |

## Link budget

| Mode | 8 bpc | 10 bpc |
|---|---|---|
| 4K@165 (1543 MHz) | 37.0 Gbps | 46.3 Gbps |
| 4K@120 (1188 MHz) | 28.5 Gbps | 35.6 Gbps |
| 1440p@165 (699.5 MHz) | 16.8 Gbps | 21.0 Gbps |
| 4K@60 (533 MHz) | 12.8 Gbps | 16.0 Gbps |

DP 1.4 HBR3 ×4 carries 25.92 Gbps, so **4K@165 over DP always uses DSC**,
at either bit depth (**Derived**). HDMI 2.1 FRL 48G carries ~42.7 Gbps,
enough for 4K@165 **8-bit without DSC** but not 10-bit. Mutter currently
scans out `XBGR2101010` (10-bit) over DP with DSC. Staying on DP is right.
NVIDIA's Linux HDMI FRL support is the less-travelled path, and 8-bit would
cost HDR quality.

## Colour (EDID primaries, CIE 1931 / 1976)

| | x | y |
|---|---|---|
| Red | 0.6826 | 0.3115 |
| Green | 0.2509 | 0.7031 |
| Blue | 0.1533 | 0.0527 |
| White | 0.3134 | 0.3291 (D65) |

| Coverage | xy | u′v′ |
|---|---|---|
| sRGB | 99.9 % | 99.7 % |
| DCI-P3 | 99.0 % | 98.8 % |
| Adobe RGB | 90.5 % | 93.9 % |
| BT.2020 | 75.3 % | 78.7 % |

All three primaries sit at or outside DCI-P3 (**Derived**). The gamut is 142 %
of sRGB by area. Without a clamp, SDR content looks oversaturated. The
monitor is set to the **sRGB preset** (`0x14` = 0x01), which TFTCentral rates
"excellent" for SDR accuracy, and brightness and contrast stay adjustable in
it. Keep it there for SDR.

## HDR

- EDID HDR static metadata: PQ + SDR gamma, max **417.7 nits**, max frame
  average 265 nits, min ~0. The AMD FreeSync v3 block (Premium Pro) repeats
  the same 98 / 2 codes. Mutter offers colour modes 0 (SDR), 1 and 2 (HDR).
  The session is in mode 0.
- 418 nits matches **DisplayHDR True Black 400** (~422 measured). The
  monitor's **Peak 1000** mode reaches ~1006 nits in small windows, but the
  EDID never advertises it. If the EDID stays the same in Peak 1000, mutter
  tone-maps to 418 nits and the extra headroom goes unused (**Inferred**).
  Test: switch the OSD HDR mode, then run
  `cmp /sys/class/drm/card1-DP-3/edid <saved copy>`.
- Toggle with the `hdr-on` / `hdr-off` aliases (desktop `home.nix`) or
  Settings → Displays → HDR. Both keep 4K@165 VRR at 1.25×. `hdr-off` also
  puts the OSD back on the sRGB preset. Use the **DisplayHDR True Black**
  mode: it matches the 418 nits the EDID tells mutter to tone-map for.
- A Dolby VSVDB (v4, YUV422 12-bit) is present: Dolby Vision, unused on Linux.
- Colorimetry block: BT.2020 RGB/YCC and xvYCC, but no sRGB bit (edid-decode warns).

## VRR

- Range 48–165 Hz (EDID and AMD VSDB). Mutter reports `min-refresh-rate 48`
  and the session mode is `3840x2160@164.991+vrr`. The connector reports
  `vrr_capable = 1`.
- On the desktop the CRTC reads `VRR_ENABLED = 0`. Mutter turns it on for
  fullscreen clients (**Inferred** from the Arch wiki; confirm with
  `drm_info | grep VRR_ENABLED` while a fullscreen game runs).
- The review notes visible VRR flicker in very dark scenes. The OSD's "VRR
  Anti-flicker" removes it at a small smoothness cost.

## DDC/CI

Current state: brightness 100, contrast 66, preset sRGB, sharpness 50, RGB
gain 100/100/100, input DP-1 (`0x0F`), display mode Standard (`0xDC` = 0x00),
speaker muted.

**Safe baseline:** `display-reset` restores the GNOME side (4K@165 VRR,
1.25×, SDR) and these OSD values: display mode Standard, brightness 100,
contrast 75 (factory), sharpness 50, then preset sRGB. Input, volume, and the vendor
codes are left alone. Write the preset **last** with a pause before it. In one
combined `setvcp` of every value, it came back as 6500 K (`0x05`), but no
single write reproduced that, and preset-last held over three runs.

The firmware answers *every* VCP code, unsupported ones included (zeros or
`0xFFFF` max). Trust only the codes in the capabilities string:
`02 03 04 05 08 10 12 14 16 18 1A 52 60 62 63 87 AC AE B2 B6 C8 C9 CA CC D6
DC DF E0 E2 E3 E5 E8 E9 EA EC ED EF F0 F1 F2 F4 F5 FD`.

Dell's vendor codes (`0xE0`–`0xFD`) are undocumented, and Dell has said it
won't publish them. Raw readings for later diffing:

| Code | Listed values | Current (mh ml sh sl) |
|---|---|---|
| E0 | 03 | 00 1f 00 00 |
| E2 | 00 22 20 21 0E 12 0B 1B 14 27 23 24 30 3A 31 40 3E | 00 ff 00 **0b** |
| E3 | — | ff ff 00 00 |
| E5 | — | 00 ff 00 00 |
| E8 | — | ff ff 00 11 |
| E9 | 00 01 02 21 22 24 29 2A 2D 2E | 00 ff 00 00 |
| EA | FE F6 F5 | ff ff 00 0d |
| EC | 7F FF02 | 00 00 90 18 |
| ED | 0400 0800 03FF | 00 00 25 0a |
| EF | 8800 | 88 ff 88 00 |
| F0 | 0A 0F 10 11 31 32 34 36 39 3A 3D 3E | 00 ff 00 ff |
| F1 | — | ff ff 00 9a |
| F2 | — | ff ff 00 00 |
| F4 | 10–17 30–33 40–47 70 80 90 A0 AD B0 | ff ff 00 **30** |
| F5 | (long list) | read error |
| FD | — | 00 ff 00 62 |

On other Dell models, `E2` follows the OSD preset (read-only) and `F0`
selects preset modes such as ComfortView. To map them here, change one OSD
setting and re-run `ddcutil -t getvcp E2 F0 F4 E8 EA`. Avoid writing
unmapped codes.

What public reverse-engineering says about Dell's codes (2026-11-27; none of it from Dell):

| Code | Claimed meaning | Source model | Here |
|---|---|---|---|
| E0 | "Restore manufacturer-specific defaults" (written as `1`, then `0C` save, to unbrick a pixel-refresh loop) | AW3225QF | `0x00`. **Never write.** |
| E2 | OSD preset readback; `setvcp` fails verification | Dell community | `0x0B` while the OSD is on sRGB |
| E7 | KVM switch | U4025QW | not listed (no KVM) |
| E8 | PBP/PIP sub-input; takes input codes like `0x60` | U4025QW | `0x11`, the HDMI-1 code (**Inferred**) |
| E9 | PBP/PIP layout; `0` = off. Reads time out for 2–4 s after a write | U4025QW, U4919DW | `0x00`; listed layouts `01 02 21 22 24 29 2A 2D 2E` |
| F0–F2 | private registers, meaning unknown | U4025QW | F0 `0xFF`, F1 `0x9A`, F2 `0x00` |

E3, E5, EA, EC, ED, EF, F4, and FD appear in no public source found.
Sampled 20 s apart at idle, every vendor code held still, so none of them is a
live sensor (temperature, hours, or panel-refresh countdown). `0xC0` (display
usage time) isn't in the capabilities string, and its reading of `1` is filler.

`0x02` reads `0x02` ("new control values pending"), and `0x52` keeps returning
`0xCC` (OSD language). Reading `0x52` doesn't drain its queue, so the
change-report mechanism isn't usable. Map codes by diffing reads instead.

## OLED care

- Power use follows content: at 200 nits full white this panel draws
  **97.9 W**, against 53.3 W for an RGWB Tandem WOLED (review), so a dark theme
  roughly halves panel power on white-heavy screens.
- Pixel shift is always on and can't be disabled. The only manual care is
  OSD pixel refresh. The firmware has no logo, taskbar, or static-area
  dimming. GNOME's screen blank does that job.
- Burn-in is covered by the 3-year warranty.
- Firmware 65.2: check Dell's support page (it needs a browser). A later
  update reportedly added a "CPC Edge Dimming" toggle.

## Raw EDID

```
00 ff ff ff ff ff ff 00 10 ac f0 a2 4c 58 4f 31 2b 24 01 04 b5 46 27 78 3b f4 65 ae 4f 40 b4 27
0d 50 54 a5 4b 00 71 4f 81 80 a9 c0 d1 c0 01 01 01 01 01 01 01 01 4d d0 00 a0 f0 70 3e 80 30 20
35 00 b9 88 21 00 00 1a 00 00 00 ff 00 31 35 38 58 50 4c 34 0a 20 20 20 20 20 00 00 00 fc 00 41
57 33 32 32 36 51 0a 20 20 20 20 20 00 00 00 fd 0c 30 a5 83 83 9b 01 0a 20 20 20 20 20 20 02 a3
02 03 4c f1 52 76 61 60 5f 5e 5d 3f 22 21 20 1f 13 12 10 04 03 02 01 e3 05 c3 01 e6 06 05 01 62
4d 02 e2 00 ea 74 1a 00 00 03 03 30 a5 00 a0 62 02 4d 03 a5 00 00 00 00 89 00 23 09 07 07 83 01
00 00 e9 01 46 d0 00 81 00 00 00 00 a4 9c 80 a0 70 38 59 40 30 20 35 00 b9 88 21 00 00 1a 00 00
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 34
70 12 79 03 00 03 01 64 bb 5a 02 04 ff 0e 9f 00 2f 80 1f 00 6f 08 b1 00 02 00 04 00 6e c2 00 04
ff 09 9f 00 2f 80 1f 00 9f 05 54 00 02 00 04 00 55 5e 00 04 ff 09 9f 00 2f 80 1f 00 9f 05 28 00
02 00 04 00 a3 9c 00 04 7f 07 9f 00 2f 80 1f 00 37 04 58 00 02 00 04 00 3d 11 01 04 ff 09 9f 00
2f 80 1f 00 9f 05 76 00 02 00 04 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 eb 90
```

Decode with `nix shell nixpkgs#edid-decode -c edid-decode --check /sys/class/drm/card1-DP-3/edid`.

## Re-collect

```
nix shell nixpkgs#edid-decode -c edid-decode --check /sys/class/drm/card1-DP-3/edid
ddcutil capabilities
ddcutil getvcp known
ddcutil -t getvcp AC AE E2 F0 F4
nix shell nixpkgs#drm_info -c drm_info | grep -E 'VRR_ENABLED|vrr_capable|Format'
```

Sources: [TFTCentral review](https://tftcentral.co.uk/reviews/alienware-aw3226q) ·
[VideoCardz launch](https://videocardz.com/newz/alienware-launches-32-inch-4k-tandem-woled-monitor-for-699-and-560hz-qd-oled-model) ·
[Dell community on vendor VCP codes](https://www.dell.com/community/Monitors/DDM-Linux-standard-command-to-switch-Preset-Modes/m-p/7846533) ·
[Arch wiki: VRR](https://wiki.archlinux.org/title/Variable_refresh_rate) ·
[atkinson/monitor SPEC (U4025QW)](https://github.com/atkinson/monitor) ·
[ScriptGod1337/kvm (DDM traffic log)](https://github.com/ScriptGod1337/kvm) ·
[AW3225QF pixel-refresh fix (E0)](https://github.com/Coleslaw3557/aw3225qf-pixel-refresh-fix)
