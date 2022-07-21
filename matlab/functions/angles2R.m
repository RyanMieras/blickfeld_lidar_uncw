%% CIRNangles2R
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  This function creates a Rotation matrix R that takes real world
%  coordinates and converts them to camera coordinates (Not UV, but rather
%  Xc,Yc, and Zc. The inputs are the pose angles as defined by CIRN,
%  referenced and explained below. The camera axes are defined as Zc
%  positive out of the lens, positive Yc pointing towards the top of the
%  image plane, and positive Xc pointing from right to left if looking from
%  behind the camera. .  The R is created from a ZXZ rotation of these
%  angles in the order of azimuth, tilt, and swing.

% If angles are defined another way (omega,kappa,phi, etc) this function
% will have to be replaced or altered for a new R definition. Note, the R
% should be the same between angle definitions, it is the order of rotations
% and signage to achieve this R that differs.


%  Input:
%  All Values should be in radians.
%  Azimuth is the horizontal direction the camera is pointing and positive CW
%  from World Z Axis.

%  Tilt is the up/down tilt of the camera. 0 is the camera looking nadir,
%  +90 is the camera looking at the horizon right side up. 180 is looking
%  up at the sky and so on.

%  Swing is the side to side tilt of the camera.  0 degrees is a horizontal
%  flat camera. Looking from behind the camera, CCW rotation of the camera
%  would provide a positve swing.



%  Output:
%  R = [3 x 3] rotation matrix to transform World to Camera Coordinates.


%  Required CIRN Functions:
%  None
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [R] = angles2R(alpha,beta,gamma)

%% Section 1: Define R
Rz=[cosd(alpha) -sind(alpha) 0; sind(alpha) cosd(alpha) 0; 0 0 1];
Ry=[ cosd(gamma) 0 sind(gamma) ; 0 1 0; -sind(gamma) 0 cosd(gamma)];
Rx=[1 0 0; 0 cosd(beta) -sind(beta); 0 sind(beta) cosd(beta)];
R=Rx*Ry*Rz';


