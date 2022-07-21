%--
%Author:       Ryan S. Mieras
%Affiliation:  University of North Carolina Wilmington
%Contact:      mierasr@uncw.edu
%Last Updated: July 2022
%Version:      '9.12.0.1975300 (R2022a) Update 3'
%

clear; clc;

addpath('../functions/');


%% INPUTS

fdir_lidar_bfpc = '..\..\sampleData\sample2\bfpc_files';
fdir_lidar_csv  = '..\..\sampleData\sample2\csv_files';
fdir_save_mat   = '..\..\sampleData\sample2\mat_files';


%% Load & append lidar data, save to .mat file(s)

csv2mat_batch_blickfeld_cube1(fdir_lidar_bfpc, fdir_lidar_csv, fdir_save_mat);

