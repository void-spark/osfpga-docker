# osfpga-docker [![Build Status](https://travis-ci.com/void-spark/osfpga-docker.svg?branch=master)](https://travis-ci.com/void-spark/osfpga-docker)
My open source FPGA tools building docker file

This includes IceStorm and Icarus Verilog

This is a very basic Docker file + Travis build configuration which builds a open source FPGA tools Docker image.
I use it by volume mounting my source folder into the container, and then running any commands,
but that's just one option.

A new image should be built daily, and available as void-spark/osfpga on Docker hub.
