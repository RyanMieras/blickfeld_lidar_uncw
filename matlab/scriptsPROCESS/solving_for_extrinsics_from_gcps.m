%% Load .csv data (with GCPs) and determine extrinsics and rotation 

clear; clc; close all;

%% DATA Inputs
addpath('../functions');

% path to .csv files with LiDAR point cloud frames
fdir = 'C:\Users\mierasr\SynologyDrive\PROJECTS\UF_SENTINEL_BLICKFELD_2022\DATA\LIDAR\2_CONVERTED_CSV\20220623\192.168.26.26_2022-06-23_14-24-18';  % DAY 1
% % % fdir = 'C:\Users\mierasr\SynologyDrive\PROJECTS\UF_SENTINEL_BLICKFELD_2022\DATA\LIDAR\2_CONVERTED_CSV\20220624\20220624_142940\';  % DAY 2
files = dir(fullfile(fdir,'*.csv'));

% path to .txt files with GCP survey locations. If not in .txt file, adjust
% code as needed.
%%% Note %%%
% The order of the loaded in survey points should be the same order that
% the points in the point cloud should be selected.
% Ex. Furthest offshore loaded in 1st, furthest offshore should be selected
% first in the point cloud
% --DAY 1--
fdir_to_survey_pts = 'C:\Users\mierasr\SynologyDrive\PROJECTS\UF_SENTINEL_BLICKFELD_2022\SURVEY\20220623\';
file_name_survey_pts = 'GCPcoordinates_20220623.txt';
% --DAY 2--
% % % fdir_to_survey_pts = 'C:\Users\mierasr\SynologyDrive\PROJECTS\UF_SENTINEL_BLICKFELD_2022\SURVEY\20220624\';
% % % file_name_survey_pts = 'GCPcoordinates_20220624.txt';


% Input for render delay (comes from web GUI)
% If there is no delay, this should be 0
t_offset = 0;

% Input for football offset at z = 0 (should hopefully be 0 after firmware update).
theta_rot = 0;

% Frame number that is being plotted
frame = 1;

% minimum intensity to look for
intensity_min = 4500;

% Extrinsics Known Flag does ...
[extrinsicsKnownsFlag] = [0 0 0 0 0 0];

% Initial Guess of LiDAR Extrinsics
%  extrinsicsInitialGuess = 1x6 Vector representing [x y z azimuth tilt swing] of
%  the LiDAR origin. Include both known and initial guesses of unknown values.
%  x, y, and z should be in the same units and coordinate system of GCP xyz
%  points. Azimuth, tilt, and swing should be in radians.
%
extrinsicsInitialGuess = [374069.77 3283196.53 60 0 0 35];  % DAY 1
% % % extrinsicsInitialGuess = [374069.10 3283195.40 60 0 0 35];  % DAY 2

metadata.filename = files(frame).name;
metadata.daterecorded = '';
metadata.dateprocessed = '';
metadata.personwhoprocessed = '';
metadata.deploymentlocation = '';
metadata.coordinatesystem = '';
metadata.elevation = '';

% Do you want to save the extrinsics data?
savedata = false;

% Path to save data
fdir_out = 'C:\Users\mierasr\SynologyDrive\PROJECTS\UF_SENTINEL_BLICKFELD_2022\DATA\LIDAR\3_MATFILES\20220623\';  % DAY 1
% % % fdir_out = 'C:\Users\mierasr\SynologyDrive\PROJECTS\UF_SENTINEL_BLICKFELD_2022\DATA\LIDAR\3_MATFILES\20220624\';  % DAY 2











%% Loading data

%%% Loading LiDAR .csv file with GCP's visible in scan
% Creating a waitbar to show progress
h_wb = waitbar(0,'Loading files...');
ct = 0; % counter
for i = 1:2%length(files)
    
    % adding to counter
    ct = ct + 1;
    
    % specify the file to be loaded 
    fname = files(i).name;
    
    % This function uses textscan to read the .csv files from Blickfeld
    % Recorder
    scan_tmp = load_cube1_frame_csv_blickfeld_recorder_BULK(fdir, fname);

    % Account for offset between local machine clock and lidar clock
    scan_tmp.date = scan_tmp.date + seconds((t_offset * 10^-3) - 4);

    % Rotation matrix that rotates data below z = 0. This is accounting for
    % the shift a z = 0 that we noticed in our point cloud.
    trig  = [cosd(theta_rot) -sind(theta_rot); sind(theta_rot) cosd(theta_rot)];
    row_vec_x = scan_tmp.x(scan_tmp.z<0)';
    row_vec_y = scan_tmp.y(scan_tmp.z<0)';        
    new_row_vec = [row_vec_x; row_vec_y];
    if ~isempty(new_row_vec)
        new_vals = trig * new_row_vec;

        % Replacing values with new rotated values
        scan_tmp.x(scan_tmp.z<0) = new_vals(1,:);
        scan_tmp.y(scan_tmp.z<0) = new_vals(2,:);
    end

    % creating the cell called 'scan'
    scan{ct} = scan_tmp;

    %cmax_tab(i) = max(scan_tmp.intensity);

    waitbar(i/length(files),h_wb);  

end
close(h_wb);

%%% Loading .txt file
fid = fopen(fullfile(fdir_to_survey_pts,file_name_survey_pts));
survey_pts = textscan(fid,'%s%f%f%f','headerlines',1,'delimiter',',');
closed = fclose(fid);

clear fid closed

enu(:,1)= survey_pts{2};
enu(:,2)= survey_pts{3};
enu(:,3)= survey_pts{4};


%% Identifying targets

gind = find(scan{frame}.intensity > intensity_min);

figure;clf;
scatter3(scan{frame}.x(gind),scan{frame}.y(gind),scan{frame}.z(gind), 5, '.k');
% % % pcshow([scan{frame}.x(gind),scan{frame}.y(gind),scan{frame}.z(gind)], scan{frame}.intensity(gind)); 
hold on; box on;
view([0 0]); xlabel('x'); ylabel('y'); zlabel('z');
axis equal


SS=1;
count=0;
while sum(sum(SS))>0
   SS=rbb3select(scan{frame}.x(gind),scan{frame}.y(gind),scan{frame}.z(gind));
   hold on
   count=count+1;
   
   %save all points
   XX{count}=scan{frame}.x(gind(find(SS)));
   YY{count}=scan{frame}.y(gind(find(SS)));
   ZZ{count}=scan{frame}.z(gind(find(SS)));

   %or for single point
   xp(count)=mean(scan{frame}.x(gind(find(SS))));
   yp(count)=mean(scan{frame}.y(gind(find(SS))));
   zp(count)=mean(scan{frame}.z(gind(find(SS))));
   
end

XX(end) = [];
YY(end) = [];
ZZ(end) = [];
xp(end) = [];
yp(end) = [];
zp(end) = [];

% Plot to make sure correct targets are selected
for i = 1:length(xp)
    scatter3(xp(i), yp(i), zp(i),15, '*r')
end

%% Setting Up Matrix to Rectify and rectifying

% XYZ values in Blickfeld Point Cloud
xyz(:,1) = xp';
xyz(:,2) = yp';
xyz(:,3) = zp';

[extrinsics, extrinsicsError]= extrinsicsSolver(extrinsicsInitialGuess,extrinsicsKnownsFlag,enu,xyz);

[converted_xyz2enu] = xyz2enu(extrinsics,[scan{frame}.x'; scan{frame}.y'; scan{frame}.z']');

clc

[latitude, longitude] = utm2ll(converted_xyz2enu(:,1),converted_xyz2enu(:,2), 17);
% latitude = zeros(1, length(converted_xyz2enu(:,1)));
% longitude = zeros(1, length(converted_xyz2enu(:,1)));
% for i = 1:length(converted_xyz2enu(:,1))
%     [longitude(i), latitude(i), ~] = sp_proj('North Carolina','inverse',...
%         converted_xyz2enu(i,1)', converted_xyz2enu(i,2)','m');
% end

% % % [longitude, latitude, ~] = sp_proj('North Carolina','inverse',...
% % %         converted_xyz2enu(:,1)', converted_xyz2enu(:,2)','m');

% Geoscatter to check
figure(2);clf;
geoscatter(latitude, longitude, 4, converted_xyz2enu(:,3), 'filled');
c = colorbar();
caxis([50 52.5]);
ylabel(c, 'Elevation [m, NAVD88]');
colormap viridis
geobasemap satellite

%% Plot in eastings and northings for now
figure(30);clf;
scatter3(converted_xyz2enu(:,1), converted_xyz2enu(:,2), converted_xyz2enu(:,3), 7, converted_xyz2enu(:,3), 'filled');
box on; grid on;
xlabel('Eastings [m]'); ylabel('Northings [m]'); zlabel('Elevation [m, NAVD88]');
c = colorbar();
ylabel(c, 'Elevation [m, NAVD88]');
caxis([45 50]);
colormap viridis
hold on;
scatter3(enu(:,1), enu(:,2), enu(:,3), 15, '*r')
view([0 90]);


%% Saving Data

checkdir(fullfile(fdir_out));

if savedata == true
    save(fullfile(fdir_out, 'extrinsics'), 'extrinsics');
    save(fullfile(fdir_out, 'extrinsicsError'), 'extrinsicsError');
    save(fullfile(fdir_out, 'converted_xyz2enu'), 'converted_xyz2enu');
    save(fullfile(fdir_out, 'metadata'), 'metadata');
end



%% checkdir function

function checkdir(FDIR, varargin)
%CHECKDIR Check if a directory exists. If not, create one.
%   CHECKDIR(FDIR) checks whether or not the directory specified by the 
%   string FDIR exists. If the directory does not exist, it is created.
%   FDIR may be a relative or absolute path.
%
%   CHECKDIR(FDIR, true) will print an acknowledgment to the command
%   window, with information about whether or not a new directory was 
%   created (mostly a sanity check). 
%
%   If the 2nd input is not included, the default value is 'false' 
%   (i.e., no confirmation will be printed to the command window).
%
%--
%Author:       Ryan S. Mieras
%Affiliation:  U.S. Naval Research Laboratory
%Last Updated: April 2018
%Contact:      ryan.mieras.ctr@nrlssc.navy.mil


% Define default(s)
print_ack = false;


% Parse inputs
if nargin == 2  % user wants to print acknowledgment to command window
    
    print_ack = varargin{1};
    
    if ~islogical(print_ack)
        error('Second input must be class:logical (i.e., true or false).')
    end
    
elseif nargin > 2
    
    error('Too many input arguments!');
    
end


% Check for directory existence, and print info, if necessary
if ~exist(FDIR, 'dir')
    
    mkdir(FDIR);  % create directory
    
    if print_ack
        fprintf('Created new directory: %s\n', FDIR);
    end
    
elseif print_ack && exist(FDIR, 'dir') == 7  % returns value of 7 if it is a folder (see EXIST help)
    
    fprintf('The following directory already exists: %s\n', FDIR);
    
end

    
end  %end CHECKDIR









%% Old BELOW HERE

% figure(1);
% pcshow([scan{frame}.x(gind),scan{frame}.y(gind),...
%     scan{frame}.z(gind)],scan{frame}.intensity(gind));
% xlabel('X'); ylabel('Y'); zlabel('Z');
% view([0 180]);
% button = 32;
% ct = 0;
% while button == 32
%     ct = ct + 1;
%     [x_targetclick(ct),y_targetclick(ct),button] = ginput(1);
% end
% x_targetclick = x_targetclick(1:(end-1));
% y_targetclick = y_targetclick(1:(end-1));
% 
% % Idx = rangesearch(scan{frame}.x(x_targetclick(1)),scan{frame}.x(y_targetclick(1)),r);
% 
% [k,dist] = dsearchn([scan{frame}.x(gind) scan{frame}.z(gind)],[x_targetclick' y_targetclick']);
% 
% figure(2);
% plot3(scan{frame}.x(gind), scan{frame}.x(gind), scan{frame}.z(gind), '.k'); hold on; box on;
% plot3(x_targetclick, y_targetclick*0, y_targetclick, '*g');
% view([0 180]);
% 
% %%
% 
% figure(3);
% pcshow([scan{frame}.x(gind),scan{frame}.y(gind),...
%     scan{frame}.z(gind)],scan{frame}.intensity(gind));
% set(gcf,'color','w');
% set(gca,'color','w');
% 
% b = brush;
% b.Enable = 'on';
% b.Color = 'red';
% 
% %%
% 
% figure(3);
% pcshow([scan{frame}.x(gind),scan{frame}.y(gind),...
%     scan{frame}.z(gind)],scan{frame}.intensity(gind));
% 
% d = datacursormode;

