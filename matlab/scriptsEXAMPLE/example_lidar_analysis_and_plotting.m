%
% REQUIRED TOOLBOXES:
%   - Computer Vision Toolbox
%
%--
%Author:       Ryan S. Mieras
%Affiliation:  University of North Carolina Wilmington
%Contact:      mierasr@uncw.edu
%Last Updated: July 2022
%Version:      '9.12.0.1975300 (R2022a) Update 3'
%

clear; clc;


%% Load the file containing the "scan" structure

load('20220624_143114_enu.mat');


%% Create pointCloud object

pc = pointCloud([scan.easting, scan.northing, scan.elevation],'intensity',scan.intensity);

% NOTE: the (x,y,z) coordinates are stored in an m x 3 array accessible at
%       'pc.Location' for all pointCloud objects. If you just want the
%       y-coordinate (northing, in this case), you would use 
%       
%         >> y = pc.Location(:,2);
%
%       to extract the 2nd column, containing the y-coordinates.


%% Perform initial/quick (i.e., default settings) denoising

% NOTE: This may take a little bit of time (a minute or less) to run...
%
pc2 = pcdenoise(pc,'PreserveStructure',true);  % preserving structure keeps 
                                            % the number of rows the same
                                            % and NaNs-out the filtered
                                            % data, so that the index
                                            % referneces in the
                                            % .indexFrameStart and
                                            % .indexFrameStop fields remain
                                            % accurate


%% Compare original vs denoised point clouds

figure(1); clf;
pcshowpair(pc,pc2,'markersize',12);
leg = legend('original','denoised');
  set(leg,'textcolor','w','edgecolor','w')
xlabel('easting (m)'); ylabel('northing (m)'); zlabel('elevation (m)');

% NOTE: with the rotation tool selected, you may zoom in/out, and the right-
%       click menu options allow for chaning the rotation from the origin
%       of the graphic to "rotate around a point", which can sometimes make
%       rotation of the point cloud easier to manage. You have to
%       separately select the pan tool (hand) to pan the point cloud around
%       the screen.

% Also, keep in mind that with SUCH A LARGE POINT CLOUD, the plot will
% likely render (i.e., rotate/update orientation) very SLOWLY!!!
%  |
%  |
%  V
% One approach to ease the render delays is to down-sample the point cloud
% (see next section)


%% Down-dample the filtered (de-noised) point cloud

gridStep = 0.10;  % (m) down-sample grid size for averaging
pc3 = pcdownsample(pc2,'gridAverage',gridStep,'PreserveStructure',true);

% NOTE: again, here, we "preserve structure" for the same reason stated 
%       above in the 'pcdenoise' section
%
%       You may also elect to do this separately for EACH FRAME, which is
%       possible (see section below about "plotting n'th frame" to see how
%       to extract single/individual frames from a multi-frame scan.


%% Plot entire (filtered & down-sampled) point cloud

% The down-sampled point cloud will be MUCH EASIER to interact with in the
% figure, with much less lag, and faster response time.

% NOTE: this will plot ALL frames together, on same plot
%
figure(2); clf;
pcshow(pc3,'markersize',12)
caxis([100 3000])  % scale color by this intensity range
xlabel('easting (m)'); ylabel('northing (m)'); zlabel('elevation (m)');
colormap(hot)


% Modify a couple other properties
set(gca,'colorscale','log')  % use log-scale to color the markers
%
% NOTE: The default color scale is 'linear'

set(gcf,'color',[0.7 0.7 0.7]);
set(gca,'visible','off')

%
% +++ PRO TIP! +++
% With the "rotation" tool selected, right-click and select "Rotate Around
% A Point" to make the rotation MUCH EASIER!!! Also zoom in, then use the
% "pan" tool to adjust the location of the point cloud, then use the
% "rotation" tool again, etc. 
%


%% Plot n'th frame

% Specify which frame number to plot
% (Note: the total number of frames is stored in "scan.nFrames")
n = 100;  % there are TWO people in this frame

% Grab start and stop indices (row numbers) that deliniate 
a = scan.indexFrameStart(n);
b = scan.indexFrameStop(n);

% Create separate (new) pointCloud object
pc_frame = pointCloud([scan.easting(a:b), scan.northing(a:b), scan.elevation(a:b)],...
                       'intensity',scan.intensity(a:b));

figure(3); clf;
pcshow(pc_frame,'markersize',10);
caxis([100 3000])  % scale color by this intensity range
xlabel('easting (m)'); ylabel('northing (m)'); zlabel('elevation (m)');
title(['Frame ' num2str(n) ': ' datestr(scan.dateStart)]);
colormap(parula);


%% Animate point cloud over time 

% Get x-, y-, and z-limits in the (easting, northing, elevation) reference
% frame from the properties of the filtered point cloud
xlims = pc2.XLimits;
ylims = pc2.YLimits;
zlims = pc2.ZLimits;

% NOTE: feel free to zoom in/out, and rotate the point cloud while it's
%       playing the animation. It will help to adjust the view.
%
player = pcplayer(xlims,ylims,zlims,'markersize',5);  % creates "player" object for point cloud animation to "show" in
for i = 1:scan.nFrames

    % Create pointCloud object, one frame at a time
    pcc = pointCloud([scan.easting(scan.indexFrameStart(i):scan.indexFrameStop(i)),...
                      scan.northing(scan.indexFrameStart(i):scan.indexFrameStop(i)),...
                      scan.elevation(scan.indexFrameStart(i):scan.indexFrameStop(i))],'Intensity',scan.intensity(scan.indexFrameStart(i):scan.indexFrameStop(i)));

    % Display the next frame in the player
    view(player,pcc.Location)
    
    % Update plot and wait half a second
    drawnow;
    pause(0.5)  % NOTE: decrease this number to playback faster, if you want
    
end


