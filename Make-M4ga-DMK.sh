#!/bin/bash

# ==============================================================================
# The script will take the my new code and first create the needed CRC value
# Then it will subsitute the old code in the dmk and add the new.
# TRS-80 Model 4 (WD179x) File-Based Sector Builder
# Use: ./Make-M4ga-DMK.sh m4ga-v1.cmd
#
# using python to generate the CRC
# using perl to do the sed corretly.
# ==============================================================================

# --- Check for File Argument ---
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <filename.hex>"
    exit 1a
fi

INPUT_FILE="$1"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' not found."
    exit 1
fi


# --- Data Extraction from File ---
# Read the file, remove any characters that aren't hex (0-9, A-F),
DATA_READ_IN=$(hexdump -v -e '1/1 "%02X "' "$INPUT_FILE")
# Slice off the first 12 bytes
DATA_READ_IN=$(echo "$DATA_READ_IN" | cut -d' ' -f13-)
CODE_BYTES_COUNT=$(wc -w <<< "$DATA_READ_IN")


# Sector limit check (TRS-80 sectors are typically 256 bytes)
if [ $CODE_BYTES_COUNT -gt 256 ]; then
    echo "Error: Input file contains $CODE_BYTES_COUNT bytes. Max is 256."
    exit 1
fi

# Generate 00 padding to fill the remainder of the 256-byte sector
REQUIRED_PADDING=$(( 256 - CODE_BYTES_COUNT ))
PADDING=""
if [ $REQUIRED_PADDING -gt 0 ]; then
    PADDING=$(printf '00%.0s ' $(seq 1 $REQUIRED_PADDING))
fi



#------   CRC   ---------------------------------------------------
# WD179x CRC includes sync bytes + DA
FBData="FB ${DATA_READ_IN} ${PADDING}"

#Remove spaces from the input string
CLEAN_DATA=$(echo "$FBData" | tr -d '[:space:]')

#generate the CRC using python
crc=$(python3 -c "
data = bytes.fromhex('$CLEAN_DATA')
crc = 0xCDB4
poly = 0x1021
for byte in data:
    crc ^= (byte << 8)
    for _ in range(8):
        if crc & 0x8000:
            crc = ((crc << 1) ^ poly) & 0xFFFF
        else:
            crc = (crc << 1) & 0xFFFF
print(f'{(crc >> 8) & 0xFF:02X} {crc & 0xFF:02X}')
")


echo ""
echo "--- TRS-80 M4ga TRSnic DMK new code builder ----"
echo "Source File:      $INPUT_FILE"
echo "Code Length:      $CODE_BYTES_COUNT bytes"
echo "Padding Applied:  $REQUIRED_PADDING bytes (00)"
echo "Target Hardware:  WD179x (Model 4)"
printf "CRC: %s\n" "$crc"
echo "------------------------------------------------"



# Combine everything that goes AFTER the 'A1 A1 A1 FB' sync marker
# Total length: 256 bytes (data+padding) + 2 bytes (CRC) = 258 bytes total.
COMBINED_PAYLOAD="${DATA_READ_IN} ${PADDING} ${crc}"

echo "Target: Track 0, Sector 0 Boot Block"
echo "This Is the code to replace 256 bytes after A1 A1 A1 FB"
echo "------------------------------------------------"

# Format the output into 16-byte rows
# 'sed' adds the spaces, 'fold' handles the 16-byte (48 char) width
echo "${COMBINED_PAYLOAD}" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]' | sed 's/../& /g' | fold -w 48
echo ""
echo "------------------------------------------------"
#echo "Total bytes in block: $(wc -w <<< "$COMBINED_PAYLOAD") (256 data + 2 CRC)"



#This is the original code fom TJBChris to be updated
CodeTOReplace="00 FE 14 21 B7 43 01 00 3C CD 34 43 3E 38 32 10 
42 D3 EC 3E 04 D3 C5 DB C4 FE FE 20 0C 21 00 50 
06 FF 0E C4 ED B2 C3 00 50 21 48 43 01 40 3C CD 
34 43 18 FE F5 C5 E5 7E B7 28 09 02 03 23 ED 43 
DE 43 18 F3 E1 C1 F1 C9 45 52 52 4F 52 20 4C 4F 
41 44 49 4E 47 20 46 52 45 48 44 20 52 4F 4D 2E 
20 20 43 48 45 43 4B 20 43 41 42 4C 45 20 43 4F 
4E 4E 45 43 54 49 4F 4E 53 20 41 4E 44 20 45 4E 
53 55 52 45 20 20 20 20 46 52 45 48 44 2E 52 4F 
4D 20 49 53 20 50 52 45 53 45 4E 54 20 4F 4E 20 
53 44 20 43 41 52 44 2F 4E 45 54 57 4F 52 4B 20 
53 48 41 52 45 2E 00 4C 4F 41 44 49 4E 47 20 46 
52 45 48 44 20 52 4F 4D 2E 20 20 4C 4F 56 45 2C 
20 2D 54 4A 42 43 48 52 49 53 2E 2E 2E 00 00 00 
02 02 00 43 00 00 00 00 00 00 00 00 00 00 00 00 
00 00 00 00 20 20 20 34 20 20 20 20 20 20 20 3B 
86 E7"

# Strip all whitespace to create a single continuous string
CleanedCode=$(echo "$CodeTOReplace" | tr -d '[:space:]')



# now that I have both the old and new a a string array 
#I'll sed replace the original(m4-frehd-boot.dmk) with the new file (m4-frehd-bootDelay.dmk)

source_file="m4-frehd-boot.dmk"
#output_file="m4-frehd-bootDelay-$(date +%Y%m%d-%H%M).dmk"
output_file="m4-frehd-bootDelay.dmk"

# Convert Hex strings to Perl-style byte sequences (\x00\x01...)
# This ensures Perl treats them as raw binary, not literal text.
search_pattern=$(echo "$CleanedCode" | sed 's/../\\x&/g')
replace_pattern=$(echo "$COMBINED_PAYLOAD" | tr -d ' '| sed 's/../\\x&/g')



#doing th sed type replace with perl\
# -0777: Slurp mode (reads the whole binary file at once)
# -pe: Loop and print
# s///g: Global search and replace

perl -0777 -pe "s/$search_pattern/$replace_pattern/g" "$source_file" > "$output_file"

#Verification
if [ $? -eq 0 ]; then
    echo "Success! Saved to $output_file"
    
    # Check if the file size changed (usually a bad sign for disk images)
    orig_size=$(stat -c%s "$source_file")
    new_size=$(stat -c%s "$output_file")
    
    if [ "$orig_size" -ne "$new_size" ]; then
        echo "Warning: File size changed from $orig_size to $new_size bytes."
        echo "Ensure your search and replace hex strings are the same length."
    fi
else
    echo "Error: Replacement failed."
fi
echo ""