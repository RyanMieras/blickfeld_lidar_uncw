%% xyzToDistUV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function computes the distorted UV coordinates (UVd)  that
% correspond to a set of world xyz points for a given camera EO and IO
% specified by extrinsics and intrinsics respectively. Function also
% produces a flag variable to indicate if the UVd point is valid.


%  Input:
%  intrinsics = 1x11 Intrinsics Vector Formatted as in A_formatIntrinsics

%  extrinsics = 1x6 Vector representing [ x y z azimuth tilt swing] of the camera.
%  XYZ should be in the same units as xyz points to be converted and azimuth,
%  tilt, and swing should be in radians.

%  xyz = Px3 list of world coordinates of P points to be transformed to UV
%  coordinates. Columns represent X,Y, and Z coordinates.


%  Output:
%  UVd= 2Px1 list of distorted UV coordinates for specified xyz world
%  coordinates with 1:P being U and (P+1):2P being V coordinates. It is
%  formatted as a 2Px1 vector so it can be used in an nlinfit solver in
%  extrinsicsSolver.

%  flag= Px1 vector marking if the UVd coordinate is valid(1) or not(0)


%  Required CIRN Functions:
%  intrinsicsExtrinsics2P
%  distortUV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function  [xyz] = enu2xyz(extrinsics,enu)

% Determine Transformation Matrix
[P, R, IC] = makeP(extrinsics) ;

xyz = R*IC*[enu'; ones(1,size(enu,1))];

xyz=[xyz(1,:)'; xyz(2,:)'; xyz(3,:)'];



