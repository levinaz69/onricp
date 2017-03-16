function [projections] = projectNormals(sourceVertices, Target, normals)
% projectNormals takes a set of vertices and their surface normals and
% projects them to a target surface.
%
% Inputs:
%   sourceVertices: N x 3 vertices of source surface.
%   Target: Structured object with fields - 
%                   Target.vertices: V x 3 vertices of template model
%                   Target.faces: D x 3 list of connected vertices.
%   normals: N x 3 surface normals of sourceVertices.

% Get number of source vertices
nVerticesSource = size(sourceVertices, 1);

% Pre-allocate space for projections
projections = zeros(nVerticesSource, 3);

% Loop over source vertices projecting onto the target surface
for i=1:nVerticesSource
    
    % Get vertex and normal
    vertex = sourceVertices(i,:);
    normal = normals(i,:);
    
    % Define line in direction normal that passes through vertex
    line = createLine3d(vertex, normal(1), normal(2), normal(3));
    
    % Compute the intersection of the line and the source surface
    intersection = intersectLineMesh3d(line, Target.vertices, Target.faces); 
    
    % If multiple intersections choose the one closest to the source vertex
    if ~isempty(intersection)
        [~,I] = min(sqrt(sum((intersection - ...
            repmat(vertex,size(intersection,1),1)).^2, 2)));
        projections(i,:) = intersection(I,:);
    else
        % If no intersections just keep the source vertex position
        projections(i,:) = vertex;
    end
end
end