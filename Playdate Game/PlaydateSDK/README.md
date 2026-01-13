# Playdate SDK
## Copyright (C) Panic, Inc.

### Introduction

This archive contains the tools you need to build games for Playdate (http://play.date).

Please read the included document _Inside Playdate_ for more detailed information about the SDK and API.
 
### SDK Contents

bin/Playdate Simulator.exe
=======

The Simulator is how you run and test your Playdate application. It is also how you load your application on to the device.

If running Playdate Simulator complains that VCRuntime140.dll is missing or won't launch:

	Download and install the Microsoft Visual C++ Redistributable (x64) for Visual Studio 2015, 2017 and 2019.
	   https://docs.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist

bin/pdc.exe
=======

The Playdate Compiler (pdc) compiles your Lua source files and bundles the compiled code with your art and sound assets into a bundle file called a pdx. To compile your game run

    pdc.exe -sdkpath <path to the SDK> <input folder> <output folder>

e.g.

    pdc.exe -sdkpath c:\PlaydateSDK-10.2 c:\PlaydateSDK-10.2\Examples\2020\Source c:\PlaydateSDK-10.2\Examples\2020\2020.pdx

bin/pdutil.exe
========

pdutil can be used to send text commands to the device firmware. For example, to reboot the device into datadisk mode run

    pdutil.exe <device serial port> datadisk

### Installation of command line tools

If you are developing from the command line, you can run directly from the SDK folder.

Building with Lua
=======

Building Lua applications requires the `pdc` compiler. Full documentation on working with Lua is in "Inside Playdate" which can be found from the Help menu in the Simulator.

Building with C
=======

Building C applications requires various developer tools including `Visual Studio` and `ARM GCC`.  Full documentation on working with C is in "Inside Playdate with C" which can be found the from the Help menu in the Simulator.
 
Examples/
=========

In the "Examples" folder you'll find source code for several sample games that illustrate Playdate best practices.
 
### Questions and feedback

Please contact us if you have questions or feedback about the Playdate SDK via the Playdate Developer forum at http://devforum.play.date.

Or, write to us at info@panic.com.

### Legal information

Playdate fonts are licensed to you under the https://creativecommons.org/licenses/by/4.0/[Creative Commons Attribution 4.0 International (CC BY 4.0) license.]
