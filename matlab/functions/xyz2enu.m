function  enu = xyz2enu(extrinsics,xyz)

% Determine Transformation Matrix
[~, R, ~] = makeP(extrinsics) ;

enu = transpose(R'*xyz');

enu(:,1) = enu(:,1) + extrinsics(1);
enu(:,2) = enu(:,2) + extrinsics(2);
enu(:,3) = enu(:,3) + extrinsics(3);
