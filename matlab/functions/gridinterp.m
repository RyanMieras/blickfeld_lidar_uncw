function [zg, num_pts] = gridinterp(x, y, z, xg, yg, r, maxpts, alpha)
%GRIDINTERP interpolates scatterd data, z, measured at locations with 
%coordinates (x, y) onto a user-specified grid with coordinates (xg, yg).
%
%USAGE:
%
%   [zg, num_pts] = GRIDINTERP(x, y, z, xg, yg, r, maxpts, alpha)
%
%
%The Euclidian distance is computed from each measured scatter data point 
%to each grid point on the user-specified (xg, yg) grid. At the i^th grid 
%point, (xg_i, yg_i), all measured z-data points within the user-specified 
%search radius, r, are used to compute the grid elevation, zg_i. An 
%inverse-distance weight function to the power of alpha is used to compute
%the elevation at the i^th grid cell, zg_i. The grid spacing MUST be the 
%same in the x- and y-directions.
%
%
%INPUTS:
%
%   x:      [double] The x-coordinate (e.g., Easting in UTM) of the 
%                    measured elevations. Should be a column vector, K x 1,
%                    where K is the total number of measured elevations.
%
%   y:      [double] The y-coordinate (e.g., Northing in UTM) of the 
%                    measured elevations. Should be a column vector, K x 1.
%
%   z:      [double] Measured elevations. Should be a column vector, K x 1.
%
%   xg:     [double] The x-coordinate of the grid onto which the measured
%                    elevation data should be interpolated. Can either be a
%                    meshgrid array, with size M x N, or a column vector,
%                    with size M*N x 1.
%
%   yg:     [double] The x-coordinate of the grid onto which the measured
%                    elevation data should be interpolated. Can either be a
%                    meshgrid array, with size M x N, or a column vector,
%                    with size M*N x 1. Required to be the same size as xg.
%
%   r:      [double] Search radius (i.e., the maximum distance from each 
%                    grid cell that a measured data point can be located 
%                    and still be considered in the inverse-distance 
%                    computation of the elevation at each grid point).
%
%   maxpts: [double] Maximum number of points to consider within the search
%                    radius (i.e., if 100 measured data points are within
%                    the user-specified search radius at the i^th grid point,
%                    but maxpts = 25, only the CLOSEST 25 points will be 
%                    used to compute zg_i @ (xg_i, yg_i). If you want to
%                    use ALL measured data points within the search radius,
%                    use maxpts = Inf.
%
%   alpha:  [double] Power of the inverse-distance-weight function in the 
%                    Euclidian distance. A value of 2 is typically used.
%                    (i.e., alpha = 2 is 'inverse-distance-SQUARED')
%
%
%OUTPUTS:
%   
%   zg:      [double] (same size as xg and yg) Interpolated grid elevations
%                     for the corresponding (xg, yg) grid. If ZERO measured
%                     elevations were found within the user-specified 
%                     search radius, r, at (xg_i, yg_i), a value of NaN is 
%                     assigned to zg_i.
%
%   num_pts: [double] (same size as xg and yg) The number of measured 
%                     scatter data points, num_pts, used to compute the 
%                     grid value, zg_i, at each grid point (xg_i, yg_i).
%
%
%--
%Author:       Ryan S. Mieras
%Affiliation:  U.S. Naval Research Laboratory
%Last Updated: February 2018
%Contact:      ryan.mieras.ctr@nrlssc.navy.mil


% Check that x, y, and z vectors are all the same length
% --> This is something that is always nice to check
len = [length(x), length(y), length(z)];
if len(1) ~= len(2) && len(2) ~= len(3) && len(1) ~= len(3)
    error('The lengths of vectors x, y and z must be the same! \n');
end

% Check if the xg and yg grids were input as vectors or arrays
rs = 0;
if min(size(xg)) > 1  % they are arrays
    [m,n] = size(xg);
    xg = xg(:);
    yg = yg(:); % vectorize them
    rs = 1;
end

% Preallocate size of the output matrix, zg
zg = nan(size(xg));
num_pts = nan(size(xg));

% Use an inverse distance interpolation method to 
% solve for zg_i at (xg_i, yg_i)
for i = 1:length(xg)
    
  % Compute the euclidian distance between (xg_i, yg_i) 
  % and every measured data point (x, y)
    D = sqrt((xg(i) - x).^2 + (yg(i) - y).^2);
    
  % Find all data points that are within the 
  % threshold distance, r, away from (xg_i, yg_i)
    pts = find(D <= r);
    
    if length(pts) > maxpts  % we found more points than we need, let's grab the closest ones!
        
        tmp = [pts D(pts)];
        tmp_sort = sortrows(tmp,2);
        
        pts_cut = tmp_sort(1:maxpts,1);
        pts = pts_cut;  % take only the first maxpts to compute zg_i
        
    end
    
  % Now compute the elevation at the i^th grid point, zg_i
  % using only the points that were found to be within
  % the search radius
    zg(i) = sum(z(pts).*D(pts).^alpha)./sum(D(pts).^alpha);
    
    num_pts(i) = length(pts);
        
end

if rs == 1
    
    zg = reshape(zg,m,n);
    num_pts = reshape(num_pts,m,n);
    
end