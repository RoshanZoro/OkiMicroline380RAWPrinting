# OKI Microline 380 — Advanced Print Script

A bash script for Linux that provides a full interactive menu for printing to the OKI Microline 380 dot matrix printer over USB, using raw escape codes to control fonts, pitch, style effects, size, and line spacing directly via the printer's Epson LQ emulation.

---

## Table of Contents

- [Requirements](#requirements)
- [Setting Up the Printer](#setting-up-the-printer)
  - [Find Your Printer's USB Path](#find-your-printers-usb-path)
  - [Register the Printer with CUPS](#register-the-printer-with-cups)
  - [Verify the Setup](#verify-the-setup)
- [Installation](#installation)
- [Usage](#usage)
- [Menu Reference](#menu-reference)
  - [Pitch](#pitch)
  - [Font](#font)
  - [Size](#size)
  - [Line Spacing](#line-spacing)
  - [Extras System](#extras-system)
- [Escape Code Reference](#escape-code-reference)
- [Notes and Limitations](#notes-and-limitations)
- [Troubleshooting](#troubleshooting)

---

## Requirements

- Linux with CUPS installed (`cups`, `lpr`)
- OKI Microline 380 connected via USB
- Bash 4.0 or later
- A plain text file to print

---

## Setting Up the Printer

The ML380 must be registered with CUPS as a **raw queue** — meaning CUPS passes data directly to the printer without any filtering or driver processing. This is essential because the script sends its own escape codes, and any CUPS processing would corrupt or interfere with them.

> **Important:** Do not use the `-m` flag on macOS. Both common options fail:
>
> - `-m raw` is explicitly blocked on macOS and will return:
>   `lpadmin: Raw queues are no longer supported on macOS.`
> - `-m everywhere` attempts to auto-detect the printer over the network and will return:
>   `lpadmin: Unable to connect to ":0": Can't assign requested address`
>
> Omitting `-m` entirely is the correct approach on macOS. CUPS will create the queue without a filter chain, which is exactly what is needed for raw escape code printing.

### Find Your Printer's USB Path

Before the URI can be discovered, the printer must first be added through the macOS GUI. macOS does not expose the USB device URI until a printer entry exists in the system.

**Step 1 — Add the printer via System Settings:**

1. Make sure the printer is plugged in and powered on
2. Open **System Settings → Printers & Scanners**
3. Click the **Add Printer, Scanner or Fax...** button
4. A new window appears listing detected devices — select **USB Print** from the list
5. You will see fields for Name, Location, and Use
6. Next to **Use**, click **Select Software...**
7. Search for OKI in the list. Select **Oki ML 380 Foomatic/epson** if available, otherwise **Oki 24-pin series** as a fallback
8. Click **Add**

> **Note:** The driver selected here does not affect how this script prints — the raw queue (`OKI380_RAW`) bypasses it entirely and sends escape codes directly to the printer. However, selecting the correct driver means you can still print normally through the standard macOS print dialog using the GUI queue, with full access to print settings. The raw script is simply faster and gives you direct control over the printer's features.

**Step 2 — Retrieve the URI:**

Once the printer has been added via the GUI, run:

```bash
lpstat -v
```

You will see output similar to:

```
device for _USB_Print: usb:///USB%20Print?location=14100000
```

The part you need is the URI — everything from `usb://` onwards:

```
usb:///USB%20Print?location=14100000
```

The `_USB_Print` name on the left is the auto-detected name macOS assigned. You will replace this with your own queue name (`OKI380_RAW`) in the next step.

The `location=` value at the end of the URI corresponds to the physical USB port the printer is connected to. If you move it to a different port, this value may change and you will need to re-register the printer with the new URI.

---

### Register the Printer with CUPS

Once you have the URI, register the printer using `lpadmin`:

```bash
sudo lpadmin -p OKI380_RAW \
  -E \
  -v "usb:///USB%20Print?location=14100000"
```

**What each flag does:**

| Flag | Meaning |
|------|---------|
| `-p OKI380_RAW` | Sets the printer queue name. You can name this anything, but the script expects `OKI380_RAW` by default. |
| `-E` | Enables the printer and accepts jobs immediately. Without this the queue exists but will not print. |
| `-v "usb://..."` | The device URI found in the previous step. Replace this with your actual URI. |

> No `-m` flag is used. This is intentional — omitting it leaves CUPS with no filter chain, which means data is passed through to the printer exactly as sent by the script.

---

### Verify the Setup

Check the printer is registered and enabled:

```bash
lpstat -v
```

You should see your printer listed with its URI:

```
device for OKI380_RAW: usb:///USB%20Print?location=14100000
```

To also confirm it is accepting jobs:

```bash
lpstat -p OKI380_RAW
```

Expected output:

```
printer OKI380_RAW is idle. enabled since ...
```

Send a quick test to confirm end-to-end:

```bash
echo "Test print" | lpr -P OKI380_RAW -o raw
```

---

## Installation

Download or copy the script, then make it executable:

```bash
chmod +x oki380print.sh
```

If you want to call it from anywhere on your system:

```bash
sudo cp oki380print.sh /usr/local/bin/oki380print
```

---

## Usage

Drag and drop a plain text file onto the script, or call it from the terminal:

```bash
./oki380print.sh myfile.txt
```

The script will walk you through the following menus interactively before sending the job to the printer.

---

## Menu Reference

### Pitch

Controls characters per inch (CPI). Higher CPI means smaller, more tightly packed characters.

| Option | Setting | Escape Code |
|--------|---------|-------------|
| 1 | 10 CPI (default) | `ESC P` |
| 2 | 12 CPI | `ESC M` |
| 3 | 15 CPI | `ESC g` |
| 4 | 17.1 CPI (compressed) | `SI` (0x0F) |
| 5 | 20 CPI | `ESC SI` |
| 6 | Proportional spacing | `ESC p 1` |
| 0 | Extras submenu | — |

---

### Font

Selects the base typeface. All options except Utility use LQ (Letter Quality) mode.

| Option | Font | Escape Code |
|--------|------|-------------|
| 1 | Courier (default) | `ESC k 0` |
| 2 | Swiss | `ESC k 1` |
| 3 | Roman | `ESC k 2` |
| 4 | Orator | `ESC k 3` |
| 5 | Prestige | `ESC k 4` |
| 6 | Gothic | `ESC k 5` |
| 7 | Utility / Draft | `ESC x 0` |
| 0 | Extras submenu | — |

> **Note:** The font LEDs on the printer's front panel do not update when the font is set via software escape codes. This is a hardware limitation of the ML380 — the LEDs only reflect panel and menu selections. The font is still applied correctly to the print output.

---

### Size

Controls character scaling.

| Option | Setting | Escape Code |
|--------|---------|-------------|
| 1 | Normal (default) | `ESC W 0` + `ESC w 0` |
| 2 | Double width | `ESC W 1` |
| 3 | Double height | `ESC w 1` |
| 4 | Double width + height | `ESC W 1` + `ESC w 1` |
| 0 | Extras submenu | — |

---

### Line Spacing

Controls the vertical gap between lines.

| Option | Setting | Escape Code |
|--------|---------|-------------|
| 1 | 1/6 inch — 6 LPI (default) | `ESC 2` |
| 2 | 1/8 inch — 8 LPI | `ESC 0` |
| 0 | Extras submenu | — |

---

### Extras System

Every menu section has an extras submenu accessible by typing `0`. Extras **stack** — you can add as many as you like before making your main selection. The menu loops back after each extra is added, showing a confirmation, until you pick a numbered option to proceed.

**Example flow — bold italic Roman at 12 CPI with unidirectional printing:**

```
Pitch: 0
  → Add extra: 1 (unidirectional on)     ✓ added, loops back
Pitch: 2                                  → 12 CPI selected

Font: 0
  → Add extra: 1 (bold on)               ✓ added, loops back
Font: 0
  → Add extra: 2 (italic on)             ✓ added, loops back
Font: 3                                   → Roman selected
```

#### Pitch Extras

| Option | Effect | Escape Code |
|--------|--------|-------------|
| 1 | Unidirectional printing on (slower, higher quality) | `ESC U 1` |
| 2 | Bidirectional printing (default, faster) | `ESC U 0` |
| 3 | Cancel compressed mode | `DC2` (0x12) |
| 4 | Cancel proportional spacing | `ESC p 0` |
| 5 | Set custom character spacing (0–127) | `ESC SP n` |

#### Font Extras

| Option | Effect | Escape Code |
|--------|--------|-------------|
| 1 | Bold on | `ESC E` |
| 2 | Italic on | `ESC 4` |
| 3 | Outline on | `ESC q 1` |
| 4 | Shadow on | `ESC q 2` |
| 5 | Outline + Shadow on | `ESC q 3` |
| 6 | Double-strike on | `ESC G` |

> Bold and italic can be combined freely with any LQ font. Using these with Utility/Draft mode will have little or no visible effect.

#### Size Extras

| Option | Effect | Escape Code |
|--------|--------|-------------|
| 1 | Superscript on | `ESC S 0` |
| 2 | Subscript on | `ESC S 1` |
| 3 | Cancel super/subscript | `ESC T` |

#### Spacing Extras

| Option | Effect | Escape Code |
|--------|--------|-------------|
| 1 | Custom n/60 inch line spacing | `ESC A n` |
| 2 | Custom n/180 inch line spacing | `ESC 3 n` |
| 3 | Skip over perforation on | `ESC N` |
| 4 | Skip over perforation off | `ESC O` |

---

## Embedding Escape Codes in Text Files

The script menu applies settings to the **entire document**. If you want to change style mid-document — for example making a single word or paragraph bold while the rest is normal — you can embed escape codes directly inside your `.txt` file as raw bytes.

The printer reads these codes as instructions as it encounters them while printing, so you can turn effects on and off anywhere in the text.

### How to do it with Python

The cleanest way to create files with embedded codes is a short Python script:

```python
ESC = '\x1b'

BOLD_ON   = ESC + 'E'
BOLD_OFF  = ESC + 'F'

ITALIC_ON  = ESC + '4'
ITALIC_OFF = ESC + '5'

text = 'This is normal text. ' + BOLD_ON + 'This is bold.' + BOLD_OFF + ' Back to normal.\n'

with open('myfile.txt', 'wb') as f:
    f.write(text.encode('latin-1'))
```

Print the resulting file with the script as normal, selecting **no bold or italic from the menu** — the formatting is already controlled inside the file itself.

### Common inline codes

| Effect | On | Off |
|--------|----|-----|
| Bold | `ESC + 'E'` | `ESC + 'F'` |
| Italic | `ESC + '4'` | `ESC + '5'` |
| Underline | `ESC + '-' + '1'` | `ESC + '-' + '0'` |
| Double-strike | `ESC + 'G'` | `ESC + 'H'` |
| Outline | `ESC + 'q' + '\x01'` | `ESC + 'q' + '\x00'` |
| Shadow | `ESC + 'q' + '\x02'` | `ESC + 'q' + '\x00'` |
| Double width | `ESC + 'W' + '1'` | `ESC + 'W' + '0'` |
| Superscript | `ESC + 'S' + '0'` | `ESC + 'T'` |
| Subscript | `ESC + 'S' + '1'` | `ESC + 'T'` |

### Combining effects

Effects stack — you can combine them freely:

```python
ESC = '\x1b'

text = (
    'Normal text here.\n'
    + ESC + 'E'           # bold on
    + ESC + '4'           # italic on
    + 'Bold and italic.\n'
    + ESC + 'F'           # bold off
    + ESC + '5'           # italic off
    + 'Back to normal.\n'
)

with open('myfile.txt', 'wb') as f:
    f.write(text.encode('latin-1'))
```

### Important notes

- Always save the file in **binary mode** (`'wb'`) — this ensures the escape bytes are written exactly as-is without any encoding conversion
- Use **`latin-1`** encoding, not UTF-8 — latin-1 maps byte values directly which is what the printer expects
- If you open the file in a text editor you will see garbled characters where the escape codes are — this is normal
- If you also select bold or italic from the script menu, it will apply to the whole document on top of your inline codes — for mixed formatting, leave those menu options off and control everything from within the file

All codes use Epson LQ emulation. ESC = 0x1B.

| Function | Decimal | Hex |
|----------|---------|-----|
| Reset printer | 27 64 | `1B 40` |
| LQ mode | 27 120 49 | `1B 78 31` |
| Draft/Utility mode | 27 120 48 | `1B 78 30` |
| 10 CPI | 27 80 | `1B 50` |
| 12 CPI | 27 77 | `1B 4D` |
| 15 CPI | 27 103 | `1B 67` |
| 17.1 CPI | 15 | `0F` |
| 20 CPI | 27 15 | `1B 0F` |
| Proportional on | 27 112 49 | `1B 70 31` |
| Proportional off | 27 112 48 | `1B 70 30` |
| Courier | 27 107 0 | `1B 6B 00` |
| Swiss | 27 107 1 | `1B 6B 01` |
| Roman | 27 107 2 | `1B 6B 02` |
| Orator | 27 107 3 | `1B 6B 03` |
| Prestige | 27 107 4 | `1B 6B 04` |
| Gothic | 27 107 5 | `1B 6B 05` |
| Bold on | 27 69 | `1B 45` |
| Bold off | 27 70 | `1B 46` |
| Italic on | 27 52 | `1B 34` |
| Italic off | 27 53 | `1B 35` |
| Double-strike on | 27 71 | `1B 47` |
| Double-strike off | 27 72 | `1B 48` |
| Outline on | 27 113 1 | `1B 71 01` |
| Shadow on | 27 113 2 | `1B 71 02` |
| Outline+Shadow on | 27 113 3 | `1B 71 03` |
| Outline/Shadow off | 27 113 0 | `1B 71 00` |
| Double width on | 27 87 49 | `1B 57 31` |
| Double width off | 27 87 48 | `1B 57 30` |
| Double height on | 27 119 49 | `1B 77 31` |
| Double height off | 27 119 48 | `1B 77 30` |
| Superscript | 27 83 48 | `1B 53 30` |
| Subscript | 27 83 49 | `1B 53 31` |
| Cancel super/sub | 27 84 | `1B 54` |
| 1/6 inch spacing | 27 50 | `1B 32` |
| 1/8 inch spacing | 27 48 | `1B 30` |
| Unidirectional on | 27 85 49 | `1B 55 31` |
| Unidirectional off | 27 85 48 | `1B 55 30` |
| Skip perforation on | 27 78 | `1B 4E` |
| Skip perforation off | 27 79 | `1B 4F` |

---

## Notes and Limitations

- **Font LEDs** on the front panel do not reflect software font changes — this is a hardware limitation. The pitch LEDs do update correctly. The font is still applied to print output.
- **Utility/Draft mode** ignores most style extras (bold, italic, outline, shadow). Use LQ fonts for styled output.
- **Unidirectional printing** is noticeably slower but improves print quality and alignment, especially useful with Orator or Prestige fonts.
- **Each job resets the printer** at start and end via `ESC @`. Settings do not persist between jobs.
- **USB port changes** will alter the `location=` value in the device URI. If the printer stops being found after moving it to a different USB port, re-run `lpstat -v` or `lpinfo -v` to find the new URI and re-register with `lpadmin`.
- The script prints **plain text files only**. Binary files, PDFs, or files with embedded formatting will not print correctly.

---

## Troubleshooting

**Printer not found by lpstat**
Run `lpinfo -v` to discover connected USB devices. Make sure the printer is powered on and the USB cable is connected before running the command.

**Job sent but nothing prints**
Check the CUPS queue with `lpq -P OKI380_RAW`. If jobs are held or stopped, check `lpstat -p OKI380_RAW` for error details. Try re-registering the printer with `lpadmin`.

**Garbled output or strange characters**
This usually means CUPS is applying a filter. Confirm the printer was registered without a `-m` flag. You can verify by checking `lpoptions -p OKI380_RAW` — there should be no driver or PPD listed.

**Output is correct but font looks wrong**
Check that LQ mode is active. Utility/Draft mode overrides font selection. Make sure you did not select option 7 (Utility) in the font menu if you want styled output.

**Script fails with permission error on lpr**
Make sure your user is in the `lpadmin` group:
```bash
sudo usermod -aG lpadmin $USER
```
Then log out and back in.

**USB URI changes after reboot**
On some systems the `location=` value is stable, on others it changes. If this is a recurring issue, try using a `usb://OKI/` style URI or create a udev rule to assign a persistent symlink to the device.
