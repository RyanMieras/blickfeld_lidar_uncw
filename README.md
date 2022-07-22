# blickfeld_lidar_uncw

Repository of tools for collecting, processing, and/or analyzing LiDAR point cloud data with the Blickfeld Cube 1 (or Cube 1 Outdoor) LiDAR scanner

https://www.blickfeld.com/lidar-sensor-products/cube-1/


matlab/
-------
Data management, processing, and analysis MATLAB code (scripts and functions) and examples for data converted from .bfpc (binary) to .csv (ASCII) files using the Blickfeld Recorder Windows application


runfiles/
---------
Codes to operate a Blickfeld Cube 1 (or Cube 1 Outdoor) LiDAR scanner autonomously on a linux (e.g., a Raspberry Pi) machine, as well as additional custom code beyond the "blickfeld-scanner-lib" 'examples/python/' codes --> https://github.com/Blickfeld/blickfeld-scanner-lib/tree/master/examples/python


sampleData/
-----------
Folder containing sets of sample data that are used in some of the MATLAB example and processing scripts ('matlab/scriptsEXAMPLE' and 'matlab/scriptsPROCESS')
