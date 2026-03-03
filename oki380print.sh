#!/bin/bash
PRINTER="OKI380_RAW"
FILE="$1"
if [ ! -f "$FILE" ]; then
    echo "Usage: drag and drop a text file onto this script"
    exit 1
fi
echo "===================================="
echo " Microline 380 Advanced Printer"
echo "===================================="
echo ""

# ── PITCH ────────────────────────────────────────────────────────────────────
PITCH_EXTRA_CMD=""

pitch_menu() {
    echo ""
    echo "Select Pitch:"
    echo "1) 10 CPI (Default)"
    echo "2) 12 CPI"
    echo "3) 15 CPI"
    echo "4) 17.1 CPI (Compressed)"
    echo "5) 20 CPI"
    echo "6) PS (Proportional Spacing)"
    echo "0) Add extras (direction, spacing...)"
    read -p "Pitch [1]: " PITCH

    if [ "$PITCH" = "0" ]; then
        echo ""
        echo "── Pitch Extras ───────────────────"
        echo "1) Unidirectional printing on"
        echo "2) Unidirectional printing off (bidirectional)"
        echo "3) Cancel compressed (DC2)"
        echo "4) Cancel proportional"
        echo "5) Set character spacing (ESC SP n)"
        read -p "Add extra: " PITCH_EXTRA
        case "$PITCH_EXTRA" in
            1) PITCH_EXTRA_CMD="${PITCH_EXTRA_CMD}\x1bU\x31";;   # Unidirectional on
            2) PITCH_EXTRA_CMD="${PITCH_EXTRA_CMD}\x1bU\x30";;   # Bidirectional
            3) PITCH_EXTRA_CMD="${PITCH_EXTRA_CMD}\x12";;         # Cancel compressed
            4) PITCH_EXTRA_CMD="${PITCH_EXTRA_CMD}\x1bp\x30";;   # Cancel proportional
            5) read -p "Character spacing (0-127): " CSPACE
               PITCH_EXTRA_CMD="${PITCH_EXTRA_CMD}\x1b\x20$(printf "\\x$(printf '%02x' $CSPACE)")";;
        esac
        echo ""
        echo "✓ Extra added. Pick another extra or select a pitch."
        pitch_menu
    else
        case "$PITCH" in
            2) PITCH_CMD="\x1bM";;
            3) PITCH_CMD="\x1bg";;
            4) PITCH_CMD="\x0f";;
            5) PITCH_CMD="\x1b\x0f";;
            6) PITCH_CMD="\x1bp\x31";;
            *) PITCH_CMD="\x1bP";;
        esac
    fi
}

pitch_menu

# ── FONT ─────────────────────────────────────────────────────────────────────
FONT_EXTRA_CMD=""
QUALITY_CMD="\x1bx\x31"

font_menu() {
    echo ""
    echo "Select Font:"
    echo "1) Courier (Default)"
    echo "2) Swiss"
    echo "3) Roman"
    echo "4) Orator"
    echo "5) Prestige"
    echo "6) Gothic"
    echo "7) Utility (Draft)"
    echo "0) Add extras (bold, italic, shadow...)"
    read -p "Font [1]: " FONT

    if [ "$FONT" = "0" ]; then
        echo ""
        echo "── Font Extras ────────────────────"
        echo "1) Bold on"
        echo "2) Italic on"
        echo "3) Outline on"
        echo "4) Shadow on"
        echo "5) Outline + Shadow on"
        echo "6) Double-strike on"
        read -p "Add extra: " FONT_EXTRA
        case "$FONT_EXTRA" in
            1) FONT_EXTRA_CMD="${FONT_EXTRA_CMD}\x1bE";;
            2) FONT_EXTRA_CMD="${FONT_EXTRA_CMD}\x1b\x34";;
            3) FONT_EXTRA_CMD="${FONT_EXTRA_CMD}\x1bq\x01";;
            4) FONT_EXTRA_CMD="${FONT_EXTRA_CMD}\x1bq\x02";;
            5) FONT_EXTRA_CMD="${FONT_EXTRA_CMD}\x1bq\x03";;
            6) FONT_EXTRA_CMD="${FONT_EXTRA_CMD}\x1bG";;
        esac
        echo ""
        echo "✓ Extra added. Pick another extra or select a font."
        font_menu
    else
        case "$FONT" in
            2) FONT_CMD="\x1bk\x01";;
            3) FONT_CMD="\x1bk\x02";;
            4) FONT_CMD="\x1bk\x03";;
            5) FONT_CMD="\x1bk\x04";;
            6) FONT_CMD="\x1bk\x05";;
            7) QUALITY_CMD="\x1bx\x30"; FONT_CMD="";;
            *) FONT_CMD="\x1bk\x00";;
        esac
    fi
}

font_menu

# ── SIZE ─────────────────────────────────────────────────────────────────────
SIZE_EXTRA_CMD=""

size_menu() {
    echo ""
    echo "Select Size:"
    echo "1) Normal (Default)"
    echo "2) Double Width"
    echo "3) Double Height"
    echo "4) Double Width + Height"
    echo "0) Add extras (super/subscript...)"
    read -p "Size [1]: " SIZE

    if [ "$SIZE" = "0" ]; then
        echo ""
        echo "── Size Extras ────────────────────"
        echo "1) Superscript on"
        echo "2) Subscript on"
        echo "3) Cancel super/subscript"
        read -p "Add extra: " SIZE_EXTRA
        case "$SIZE_EXTRA" in
            1) SIZE_EXTRA_CMD="${SIZE_EXTRA_CMD}\x1bS\x30";;
            2) SIZE_EXTRA_CMD="${SIZE_EXTRA_CMD}\x1bS\x31";;
            3) SIZE_EXTRA_CMD="${SIZE_EXTRA_CMD}\x1bT";;
        esac
        echo ""
        echo "✓ Extra added. Pick another extra or select a size."
        size_menu
    else
        case "$SIZE" in
            2) SIZE_CMD="\x1bW\x31";;
            3) SIZE_CMD="\x1bw\x31";;
            4) SIZE_CMD="\x1bW\x31\x1bw\x31";;
            *) SIZE_CMD="\x1bW\x30\x1bw\x30";;
        esac
    fi
}

size_menu

# ── LINE SPACING ─────────────────────────────────────────────────────────────
SPACING_EXTRA_CMD=""

spacing_menu() {
    echo ""
    echo "Select Line Spacing:"
    echo "1) 1/6 inch — 6 LPI (Default)"
    echo "2) 1/8 inch — 8 LPI"
    echo "0) Add extras (custom spacing...)"
    read -p "Spacing [1]: " SPACING

    if [ "$SPACING" = "0" ]; then
        echo ""
        echo "── Spacing Extras ─────────────────"
        echo "1) Set n/60 inch spacing"
        echo "2) Set n/180 inch spacing"
        echo "3) Skip over perforation on"
        echo "4) Skip over perforation off"
        read -p "Add extra: " SPACING_EXTRA
        case "$SPACING_EXTRA" in
            1) read -p "n (e.g. 12 = 1/5\"): " SVAL
               SPACING_EXTRA_CMD="${SPACING_EXTRA_CMD}\x1bA$(printf "\\x$(printf '%02x' $SVAL)")";;
            2) read -p "n (e.g. 30 = 1/6\"): " SVAL
               SPACING_EXTRA_CMD="${SPACING_EXTRA_CMD}\x1b\x33$(printf "\\x$(printf '%02x' $SVAL)")";;
            3) SPACING_EXTRA_CMD="${SPACING_EXTRA_CMD}\x1bN";;   # Skip perf on
            4) SPACING_EXTRA_CMD="${SPACING_EXTRA_CMD}\x1bO";;   # Skip perf off
        esac
        echo ""
        echo "✓ Extra added. Pick another extra or select a spacing."
        spacing_menu
    else
        case "$SPACING" in
            2) SPACING_CMD="\x1b\x30";;
            *) SPACING_CMD="\x1b\x32";;
        esac
    fi
}

spacing_menu

# ── PRINT ─────────────────────────────────────────────────────────────────────
echo ""
echo "Printing $FILE..."
(
printf "\x1b@"               # Reset printer
printf "$QUALITY_CMD"        # LQ or Utility
printf "$PITCH_CMD"          # Pitch
printf "$PITCH_EXTRA_CMD"    # Pitch extras (direction, spacing etc.)
printf "$FONT_CMD"           # Font
printf "$FONT_EXTRA_CMD"     # Font extras (bold, italic, shadow etc.)
printf "$SIZE_CMD"           # Size
printf "$SIZE_EXTRA_CMD"     # Size extras (super/subscript)
printf "$SPACING_CMD"        # Line spacing
printf "$SPACING_EXTRA_CMD"  # Spacing extras (custom, skip perf)
cat "$FILE"
printf "\x1b@"               # Reset after job
) | lpr -P "$PRINTER" -o raw -o document-format=text/plain
echo "✅ Done!"
