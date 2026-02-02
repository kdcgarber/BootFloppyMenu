![TRSNIC-SSD1306](/images/trs-80MotherboardKeyBoard3.jpg?rawtrue "Header")

# Notes on The Boot Floppy File 


The content in this section is a variation of the original FreHDDISK code from TJBChris ( Christopher Hyzer ).<br>
( https://github.com/TJBChris/FreHDDisk ) <br>
His code allows a TRS-80 to boot from a floppy or gotech without requiring a ROM upgrade to auto-boot to a FreHD menu for your TRSNIC or TRS-IO.<br>
Follow his github link to get lots of great information on his tool. What a great tool to have. Thanks for making that project available for others.<br>
Also, special thanks to Chris for pre-testing my version with his TRSNIC setup to validate that it works in another envrionment, not just mine.<br>

I use his m4-frehd-boot.dmk as the initial file to create my m4-frehd-bootDelay.dmk version.<br>
This new  version allows for the TRSNIC to start at the same time the m4 is turned on.<br>
The new dmk boots to a menu of choices, giving the TRSNIC time to get connected to the network and get an IP and connect to the SMB.<br>
When the TRSNIC is ready, a menu item can then be run to begin using the TRSNIC.<br>

The new program menu looks like this:

	1 FreHD                       - Launches the FreHD menu
	2 RetroStore                  - Launches the RetroStore Menu 
	3 IP                          - Shows the TRSNIC IP address 


<table>
  <tr>
    <td><img src="https://github.com/kdcgarber/trsnic-ssd1306/blob/main/images/MainMenu.jpg" width="200" height="132"></td>
    <td><img src="https://github.com/kdcgarber/trsnic-ssd1306/blob/main/images/FreHD.jpg" width="200" height="132"></td>
    <td><img src="https://github.com/kdcgarber/trsnic-ssd1306/blob/main/images/RetroStore.jpg" width="200" height="132"></td>
    <td><img src="https://github.com/kdcgarber/trsnic-ssd1306/blob/main/images/IP.jpg" width="200" height="132"></td>
  </tr>
</table>




Use the new dmk (m4-frehd-bootDelay.dmk)<br> 
I've included both the m4-frehd-bootDelay.dmk to be used with a floppy drive. <br> 
I've also included the m4-frehd-bootDelay_dmk.hfe which can be used with a gotech.<br>



### To modify and build your own m4-frehd-bootDelay.dmk I've included all the required files.
You dont need to build your own new file, unless you need to make changes.
The provided m4-frehd-bootDelay.dmk is all that is needed.<br>
But, If you want to follow what I've done, everthing is here to get that done.<br>

### Files and Descriptions

	• z80asm.exe                      Assembler executable used to compile a new  cmd file from the m4ga.asm file
	• Make-M4ga-DMK.sh                File to create a new m4-frehd-bootDelay.dmk

	• m4-frehd-boot.dmk               Default m4 frehd boot dmk file from TJBChris
	• m4-frehd-boot.hfe               Default m4 frehd boot hfe file for using on a gotech

	• m4-frehd-bootDelay.dmk          New m4 frehd boot dmk file based on the created cmd from the asm file
	• m4-frehd-bootDelay_dmk.hfe      New m4 frehd boot file for a gotech

	• m4ga.asm                        Assembler code file for new boot menu file to wait until the TRSNIC is up and running
	• m4ga.cmd                        Compiled Assembler file for new delayed boot menu file	
	• m4ga.lst:                       Source listing with address




### Example to compile the new m5ga.asm file that will be used in the new m4-frehd-bootDelay.dmk file
This is run from a DOS window in a directory that contains all the files listed above.<br>


	z80asm -cmd  m4ga.asm

	Z80 assembler, version 1.26
	copyright (c) 2011-2022 by Matthew Reed, all rights reserved.
	Unauthorized use, duplication, or distribution of this program
	is strictly prohibited by law.

	Registered to the TRS-80 Community
	 Assembling: m4ga.asm
 


### Example to create the new dmk file (m4-frehd-bootDelay.dmk)

I first used "Super Utility 4" in trs80gp to modify the data in the file.<br>
After a couple of iterations, I decided doing a simple sed to the code would do the same feature while also adding the CRD for the new code to ensure it's valid.<br>
This would help me speed up the .dmk build time and let me hack my way through this build quicker.<br>
I'm not a great z80 assembler code developer, but with a few samples and some help from copilot and gemini, it finally came together in a small enough package.<br>

I run this from an ubuntu shell window on my windows 11 pc.<br>
I built this script to inject the new compiled code into an existing default dsk.<br>
All of the new code is required to be within the 256 byte footprint in sector 0.<br>
The script then adds the correct CRC values so that it becomes a valid dsk for use on the M4.<br>

The CRC is calculated using python and perl to do the sed command.<br>

### example:

	./Make-M4ga-DMK.sh m4ga.cmd

	--- TRS-80 M4ga TRSnic DMK new code builder ----
	Source File:      m4ga.cmd
	Code Length:      252 bytes
	Padding Applied:  4 bytes (00)
	Target Hardware:  WD179x (Model 4)
	CRC: F1 76
	------------------------------------------------
	Target: Track 0, Sector 0 Boot Block
	This Is the code to replace 256 bytes after A1 A1 A1 FB
	------------------------------------------------
	00 CD C9 01 CD 25 43 CD 49 00 FE 1B C8 D6 31 38
	F6 28 29 3D 28 4E 3D 28 6A 18 EC 7E FE 03 C8 CD
	33 00 23 18 F6 21 C4 43 CD 1B 43 06 40 21 F6 43
	CD 1B 43 10 F8 21 AA 43 CD 1B 43 C9 CD C9 01 21
	A0 43 CD 1B 43 FE 14 3E 38 32 10 42 D3 EC 3E 04
	D3 C5 DB C4 FE FE 20 EF 21 00 50 06 FF 0E C4 ED
	B2 C3 00 50 3E 10 D3 EC 3E 03 D3 1F 3D CB 3F D3
	1F DB 1F DB 1F 21 00 51 06 7D 0E 1F ED A2 20 FC
	C3 00 51 CD 25 43 3E 10 D3 EC AF D3 1F 3E 04 D3
	1F DB 1F B7 CA 07 43 FE 3A 30 F6 CD 33 00 18 F1
	57 61 69 74 69 6E 67 2E 2E 03 31 20 46 72 65 48
	44 0D 32 20 52 65 74 6F 53 74 6F 72 65 0D 33 20
	49 50 3A 03 1C 83 BF 83 20 BF 83 BD 20 A7 93 8B
	20 BF 94 BF 20 83 BF 83 20 BF 83 83 0D 80 BF 80
	20 BF 83 BD 20 B4 B2 B9 20 BF 8A BF 20 B0 BF B0
	20 BF B0 B0 0D 03 8C 03 02 02 00 43 00 00 00 00
	F1 76
	------------------------------------------------
	Success! Saved to m4-frehd-bootDelay.dmk


That example run shows the output which indicates a success file creation.<br>
This also lists the "Padding Applied" of 4 bytes which indicates there are only 4 bytes not allocated for this code to reach the max available space.<br>
The code can only be a maximum of 256 bytes. When the code is compiled to the m4ga.cmd, this file needs to not exceed 256 bytes.<br>
Any file created that is less than 256 bytes is padded with 00H's.<br>
Any that are larger fail and tell the number of bytes over the 256byte limit.<br>


After running the .sh script, it will produce the m4-fred-bootDelay.dmk file that can be copied to a floppy as the auto boot loader.<br>
Or, since I use goteck I also have HxCFloppyEmulator to convert the .dmk to a .hfe for use on my gotech.<br>
https://hxc2001.com/download/floppy_drive_emulator/HxCFloppyEmulator_soft.zip<br><br>
<img src="https://github.com/kdcgarber/trsnic-ssd1306/blob/main/images/HxCFloppyEmulator.png" width="100" height="132">

<br>
<br>
<br>




### Example use of trs80gp
trs80gp -m4   -trsnic -frehd_dir \\\192.168.0.51\trsnic\ -d m4-frehd-bootDelay.dmk<br>

The boot code menu will come up if you test via trs80gp, and the FreHD will work also. <br>
The RetroStore and the IP address listing will not work.<br>



---

### Other testing to do
I added this menu to allow for a delay during the boot cycle of my M4GA.<br>
This allows the TRSNIC to initialize correctly before jumping to the FreHD.<br>
I then decided to see if I could get the RetroStore and the IP basic code to also work.<br>
The RetroStore seems to work fine.<br>
So now I have two choices and a new quicker way to get to the RetroStore.<br>

The IP seems to work, yet on my card it will report strangely different IP's that look valid but don't always match the LCD display, which is the correct value.<br>
I'm not sure why, but because it's not maybe the most needed feature, I'm pushing this out anyway.<br>
If anyone else notices this or maybe it's just my TRSNIC, let me know.<br>
I haven't tracked it down completely yet.<br>
The RetroStore "about" menu information does the same thing for me, showing serval IP's as you re-choose the "About" screen repeatedly.<br>
Other testing shows the basic sample code does the same thing. Here are a few screen shots.


<table>
  <tr>
    <td><img src="https://github.com/kdcgarber/trsnic-ssd1306/blob/main/images/IP-52.jpg" width="200" height="200"><br>The LCD displays the IP that works with the web server, so it's the correct value (192.168.68.52)</td>
    <td><img src="https://github.com/kdcgarber/trsnic-ssd1306/blob/main/images/IPBasic.jpg" width="200" height="200"><br>This is the test code, based on the sample code for the IP address from the TRSIO repo.</td>
    <td><img src="https://github.com/kdcgarber/trsnic-ssd1306/blob/main/images/IPOutput.jpg" width="200" height="200"><br>This is the output of 40 test runs, looping the same basic IP test code.  The output shows similar results to what I see using the RetroStore "About" menu to get the IP and using the IP choice on my boot app menu code.<br>
</td>
  </tr>
</table>


This is not the highest of importantce, since I have a working display. But, I'll take a look to see if I can narrow it down to what the issue is and resolve it also.<br>
But not today!<br>




	10 X=40
	20 FOR I=1 TO X
	30 OUT 236,16
	40 OUT 31,0: OUT 31,4
	50 C=INP(31): IF C=0 THEN GOTO 80 
	60 PRINT CHR$(C);
	70 GOTO 50
	80 PRINT "    ";
	90 NEXT I



<br>
<br>
<br>

---

### Other notes:

Everything from that first 00 through that 3B is the 256-byte sector data; the two bytes right after (86 E7) are the CRC for that sector<br><br>

<img src="https://github.com/kdcgarber/trsnic-ssd1306/blob/main/images/BlockToDeployTo.png" width="200" height="132">

<br>
It fits into this space<br>
- the code/data for sector 0 starts at: the 00 immediately after A1 A1 A1 FB<br>
- Start of data: 00<br>
- The code/data ends at: the 3B just before 86<br>
- End of data: 3B<br>
- The CRC that follows that data is: 86 E7<br>
Everything from that first 00 through that 3B is the 256-byte sector data; the two bytes right after (86 E7) are the CRC for that sector<br>
<br>
Look for that the start:  Insert those 256 bytes after A1 A1 A1 FB which is the start of  00 FE 14 and the end is that start of the crc value: 3B 86 <br>


