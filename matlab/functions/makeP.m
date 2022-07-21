%%intrinsicsExtrinsicsToP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  This function creates a camera P matrix from a specified camera
%  extrinsics and intrinsics. Note, output P is normalized for homogenous
%  coordinates.


%  Input:
%  intrinsics = 1x11 Intrinsics Vector Formatted as in A_formatIntrinsics

%  extrinsics = 1x6 Vector representing [ x y z azimuth tilt swing] of the camera.
%  XYZ should be in the same units as xyz points to be converted and azimith,
%  tilt, and swing should be in radians.


%  Output:
%  P= [3 x 4] transformation matrix to convert XYZ coordinates to distorted
%  UV coordinates.

%  K=  [ 3 x 3] K matrix to convert XYZc Coordinates to distorted UV coordinates

%  R = [3 x 3] Matrix to rotate XYZ world coordinates to Camera Coordinates XYZc

%  IC =[ 4 x3] Translation matrix to translate XYZ world coordinates to Camera Coordinates XYZc



%  Required CIRN Functions:
%  None
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [P, R, IC] = makeP(extrinsics )








%% Section 2: Format EO into Rotation Matrix R
% Here, a rotation matrix from World XYZ to Camera (subscript C, not UV) is
% needed. The following code uses CIRN defined angles to formulate an R
% matrix. However, if a user would like to define R differently with
% different angles, this is where that modifcation would occur. Any R that
% converts World to XYZc would work correctly.

alpha= extrinsics(4);
beta=extrinsics(5);
gamma=extrinsics(6);
[R] = angles2R(alpha,beta,gamma);




%% Section 3: Format EO into Translation Matrix
ce=extrinsics(1);
cn=extrinsics(2);
cu=extrinsics(3);

IC = [eye(3) [-ce -cn -cu]'];





%% Section 4: Combine K, Rotation, and Translation Matrix into P
P = R*IC;




