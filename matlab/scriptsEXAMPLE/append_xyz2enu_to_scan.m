
clear; clc;

load('extrinsics.mat');
load('20220624_143114.mat');

scan.dateFrameStart = scan.time(scan.indexFrameStart) + scan.dateStart;

enu = xyz2enu(extrinsics,[scan.x, scan.y, scan.z]);

scan.easting = enu(:,1);
scan.northing = enu(:,2);
scan.elevation = enu(:,3);

scan.units.easting   = 'm, UTM Zone 17N';
scan.units.northing  = 'm, UTM Zone 17N';
scan.units.elevation = 'm, MSL';

save('20220624_143114_enu.mat','scan')

