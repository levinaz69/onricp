function bound = find_bound(pts, poly)
%  From Iterative Closest Point: 
% http://www.mathworks.com/matlabcentral/fileexchange/27804-iterative-closest-point

% Boundary point determination. Given a set of 3D points and a
% corresponding triangle representation, returns those point indices that
% define the border/edge of the surface.
% Correcting polygon indices and converting datatype 

poly = double(poly);
pts = double(pts);

%Calculating freeboundary points:
TR = triangulation(poly, pts);
FF = freeBoundary(TR);

%Output
bound = FF(:,1);
end