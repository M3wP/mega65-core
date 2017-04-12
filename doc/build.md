## This is the 'build' documentation file.

# Table of Contents:

[Introduction](#introduction)  
[Downloading Repository](#downloading-repository)  
[Dependancies](#dependancies)  
[Compiling](#compiling)  
[Modifying the design using ISE](#modifying-the-design-using-ise)  
[Programming the FPGA via USB](#programming-the-fpga-via-usb)  
[Programming the FPGA via sdcard](#programming-the-fpga-via-sdcard)  
[Appendix A - installing cbmconvert](#appendix-a---installing-cbmconvert)  

## Introduction

Thanks for justburn for his contributions on getting this file started!

The overall process from go-to-whoa takes about 60 minutes.

Basically you:

1. download the repository from github (5 mins),
1. compile the design into a bitstream (40 mins),
1. copy bitstream onto fpga board (5 mins).

Detailed instructions are below.

## Downloading Repository

The following is assumed:

1. you have linux, say, Ubuntu 15
1. you have git installed
```
$> sudo apt-get install git
```

Make a working directory for your project, we refer to that working directory as ```$GIT_ROOT```
```
$> cd $GIT_ROOT
```
Clone the following two git repositories into your working directory
```
$GIT_ROOT$> git clone https://github.com/MEGA65/mega65-core.git
$GIT_ROOT$> git clone https://github.com/gardners/Ophis.git
$GIT_ROOT$> 
```
You should now have two directories in your working directory, ie ```mega65-core``` and ```Ophis```.

Change directory into the ```mega65-core``` working directory.
```
$GIT_ROOT$> cd mega65-core
$GIT_ROOT$/mega65-core>
```

Currently, the MASTER branch (the default branch checked-out when downloaded from github) is what you should compile.  

If you want to try a different (development) branch, do the following: ie to see/use the example banana branch, type ```$GIT_ROOT$/mega65-core> git checkout banana```. To revert back to the MASTER branch, type ```git checkout master```.

You may want to type ```git status``` or ```git branch``` to check what branch you have checked out.  

To make sure that you have the latest files from the github repository, all you have to do is type:
``` 
$GIT_ROOT$/mega65-core> git pull
```

## Dependancies

To build this project you will need to have the following:

1. you have ```gcc``` installed (i have ver 5.2.1) (for compiling c.*)
1. you have ```make``` installed (i have 4.0) (for the makefile)
1. you have ```python``` installed (I have ver 2.7.10) (for some scripts)
1. you have ```libpng12-dev``` installed (for the image manipulation)
1. you have ```cbmconvert``` installed (i have ver 2.1.2) (to make a D81 image)
1. you have Xilinx ISE 14.7 WebPACK installed, with a valid licence

For instructions on installing ```cmbconvert```, please refer to [Appendix A](#appendix-a---installing-cbmconvert).  


## Compiling

Overview of the compile process:  

1. determine what target FPGA you will compile for
1. pre-compile BEFORE running the ISE build
1. run the ISE build
1. optionally: see design run in fpga hardware (to do)
1. optionally: see design run in ghdl simulator (to do)

The current workflow includes the ability to target different hardware. You can choose to compile for any of the supported targets by placing a special file in the toplevel directory as described below:

* The default target is the Nexys4(DDR) fpga development board. As this is the default, there is nothing for you to do in this step.

* An alternate target is the Nexys4(non-DDR) fpga development board. You can compile for this target by placing a file in the toplevel directory called ```nonddr```. The easy way to do this is to  
```$GIT_ROOT$/mega65-core> touch nonddr```

In the toplevel mega65-core directory: type the following:
```
$GIT_ROOT$/mega65-core> ./compile.sh
$GIT_ROOT$/mega65-core> 
```
The ```compile.sh``` script performs three main tasks:  

1. creates some subdirectories to allow the ISEv14.7 (Project Navigator) to place its build artefacts in, and  
1. calls the ```make``` command in the ```./src``` directory, which pre-compiles files used in the design, and then  
1. issues several commands to build the design using ISE commands.  

NOTE that steps 1 and 2 above are required to compile the design using either the provided ```compile.sh``` script, or by using the ISE application.  
NOTE that step 2 above is required to pre-build some of the vhdl-files. The design will not build without these files.

The image below may be useful to understand which file builds what file during the pre-compile.   
PLEASE NOTE that this file is now outdated, kickstart is called KICKUP, etherload/diskmenu are not embedded within KICKUP but are added to the D81.  

[![precomp](./images/precomp-small.jpg)](./images/precomp.jpg)  
Click the image above for a hi-res JPG, else the [PDF link](./images/precomp.pdf).  

During the pre-compile, ```Ophis``` may generate the following warnings, but these are OK:
```
WARNING: branch out of range, replacing with 16-bit relative branch
```

During the compile of the design (using ISE commands), many warnings are generated and listed in the relevant log-files. It was thought appropriate to hide these warnings from the user during compilation to make it easier to determine what part of the compile it is up to. If compile fails, (or completes), you are strongly encouraged to browse the log-files to examine the output generated during compile.  
There are two sets of log-files:

1. log files are generated by ISE commands, including *.XRPT, *.syr, *.log, etc, and
1. log files are generated by the ```./compile.sh``` script, ie: ```compile-<date><time>_N.log```, where N is one of the six stages of ISE compile.


## Modifying the design using ISE

Open ISE, and then ```Project -> Open``` and browse to the ```$GIT_ROOT$/mega65-core/ise147pn``` directory. Then select one of the sub-directories referring to the target you desire. Then select the ```"mega65*.xise"``` project file.

Within ISE, you should be able to double-click on the ```"Generate Programming File"``` and a bit-stream should be created and located in the following directory:
```$GIT_ROOT$/mega65-core/ise147pn/mega65-*/working/container.bit```

NOTE that use of the ISEv14.7 Project Navigator should only be used as:  
* a glorified text editor, and
* understanding the component heirachy, and
* synthesizing and making use of the click-and-locate error/warnings.

NOTE that every compile of a bitstream that is destined for the FPGA, should be compiled using ```./compile.sh``` script, because this script ensures that the pre-compiled files are generated correctly.

## Programming the FPGA via USB

To get the bitstream onto the FPGA, you can use either the USB-Stick or the SD-card. See next section for sdcard.  

To load the bitstream into the Nexys 4 DDR board via USB stick:

1. you need a USB stick formatted as FAT32
1. copy the bitstream to the root directory of the USB stick
```
$GIT_ROOT$/mega65-core> cp *.bit /media/sdc1
```

1. power OFF nexys board
1. place USB stick into the USB_HOST header
1. set jumper JP2 to USB
1. set jumper MODE to USB/SD
1. power ON nexys

Upon powerup, the bitstream is copied from USB into FPGA, then the FPGA executes it.

## Programming the FPGA via sdcard

Alternatively, the bitstream can be put onto an SD-card and that SD-card inserted into the Nexys 4 board. If you choose to use this method, just follow the above instructions re the use of the USB-stick, but change the "jumper JP2 to SD".  

## Appendix A - installing cbmconvert

Get into the normal toplevel directory:  
```
$> cd $GIT_ROOT
$GIT_ROOT$>
```
Download the source files:  
```
$GIT_ROOT$> wget http://www.zimmers.net/anonftp/pub/cbm/crossplatform/converters/unix/cbmconvert-2.1.2.tar.gz
```
Unzip source files:  
```
$GIT_ROOT$> tar xvfz cbmconvert-2.1.2.tar.gz
```
The ```cbmconvert-2.1.2``` directory will be created with the source code contained in it  
To make things clean, move the zip-file into the created directory:  
```
$GIT_ROOT$> mv cbmconvert-2.1.2.tar.gz cbmconvert-2.1.2
```
Change directory into the cbmconvert subdirectory:  
```
$GIT_ROOT$>cd cbmconvert-2.1.2
$GIT_ROOT/cbmconvert-2.1.2$>
```
Make the executables:  
```
$GIT_ROOT/cbmconvert-2.1.2$> make -f Makefile.unix
```
Install the executables so that the cbmconvert program can be run from any directory:  
```
$GIT_ROOT/cbmconvert-2.1.2$> sudo make -f Makefile.unix install
```
You should now be able to run the cbmconvert from any directory, lets try it...  
```
$GIT_ROOT/cbmconvert-2.1.2$> cd ..
$GIT_ROOT$> cbmconvert
```

The End.
