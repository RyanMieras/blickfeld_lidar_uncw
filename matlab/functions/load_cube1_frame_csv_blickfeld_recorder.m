function scan = load_cube1_frame_csv_blickfeld_recorder(fdir,fname)
%
%USAGE:
%   scan = load_cube1_frame_csv_blickfeld_recorder(fdir, fname)
%
%
%INPUTS:
%    fdir: [str/char] path to file to be loaded (absolute or relative)
%
%   fname: [str/char] name of file to be loaded (including the '.csv'
%                     extension)
%
%
%OUTPUT:
%    scan: [struct] structure containing the data within the .csv file that
%                   was loaded, with the following fields (sample data 
%                   sizes and types are shown, where "M" is the number of 
%                   sampled points in the frame written to the .csv file):
%
%          FIELDS
%          ------
%          dateStart: 2022-06-24 14:31:14.000000000
%               time: [Mx1 duration]
%           point_id: [Mx1 single]
%                  x: [Mx1 double]
%                  y: [Mx1 double]
%                  z: [Mx1 double]
%          intensity: [Mx1 single]
%            ambient: [Mx1 single]
%              units: [1×1 struct]
%
%
%NOTES:
%   * UTC timezone is assumed for ".dateStart"
%
%   * The ".dateStart" is determined by the filename in one of two ways:
%       1) Example filename when point cloud stream was logged manually 
%          by clicking "record" in the WebGUI:
%            '192.168.26.26_2022-06-24_10-19-45.bfpc'
%       2) Example filename when point cloud was logged via custom code
%          (python and shell) written by Tanner Jernigan at UNCW
%            '20220624_142856.bfpc'
%     If a date cannot be determined from the file name, a value of "NaT"
%     (not a time) is assigned to the ".dateStart" field.
%
%   * The "distance" field is not included here, to reduce file size,
%     because it is easily computed from 
%
%       >> distance = sqrt(scan.x.^2 + scan.y.^2 + scan.z.^2);
%
%
%--
%Author:       Ryan S. Mieras
%Affiliation:  University of North Carolina Wilmington
%Contact:      mierasr@uncw.edu
%Last Updated: July 2022
%Version:      '9.12.0.1975300 (R2022a) Update 3'
%


% Format of the .csv files
formatSpec = '%f%f%f%f%f32%f32%f32%f32%f';

% Read .csv file
fid = fopen(fullfile(fdir,fname)); % opening file
  data = textscan(fid,formatSpec,'headerlines',1,'delimiter',';');
fclose(fid); % closing file 


% Determine approx. start time based on file name
if strcmp(fname(1:2),'19')  % this is likely a webGUI recording (file starts with 192.168.)
    % Example file name: 192.168.26.26_2022-06-24_10-17-38_frame-98324.csv
    [~, s] = strtok(fname,'_');
    ss = strtok(s,'f');
    datestring = ss(2:end-1);
    scan.dateStart = datetime(datestring,'InputFormat','uuuu-MM-dd_HH-mm-ss');
elseif strcmp(fname(1:2),'20')  % the file was likely recorded with python script (will work until the year 2100)
    % Example file name: 20220624_143114_frame-358.csv
    scan.dateStart = datetime(fname(1:15),'inputformat','yyyyMMdd_HHmmss');
else
    scan.dateStart = NaT;  % unable to determine start time
end
scan.dateStart.Format = 'uuuu-MM-dd HH:mm:ss.SSSSSSSSS';
scan.dateStart.TimeZone = 'UTC';


% Scanner time
scan.time = datetime(data{9} * 10^-9,'ConvertFrom','posixtime'); % multiply by 10^-9 because posixtime needs input in seconds


% Point cloud data
scan.point_id = data{6}; % point id
scan.x = data{1}; % x data
scan.y = data{2}; % y data
scan.z = data{3}; % z data
scan.intensity = data{5}; % intensity
scan.ambient = data{8}; % ambient lighting


% Create units field
scan.units.x         = 'm';
scan.units.y         = 'm';
scan.units.z         = 'm';

