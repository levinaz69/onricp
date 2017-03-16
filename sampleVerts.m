function [ samples ] = sampleVerts( Mesh, radius )
% sampleVerts sub samples the vertices of a mesh. Vertices are selected 
% so that no other nodes lie within a pre-determined radius.
% 
% Inputs:
%   Mesh : structured object with fields:
%                   Mesh.vertices: N x 3 vertices of Mesh.
%                   Mesh.faces: M x 3 list of connected vertices.
%   radius : controls the spacing of the vertices.

samples = [];
vertsLeft = Mesh.vertices;
itt = 1;
while size(vertsLeft, 1) > 0
    nVertsLeft = size(vertsLeft, 1);
    
    % pick a sample from remaining points
    vertN = randsample(nVertsLeft, 1);
    vert = vertsLeft(vertN, :);
    
    % Add it to sample set
    samples(itt,:) = vert;
    
    % Remove nearby vertices
    idx = rangesearch(vertsLeft, vert, radius);
    idRemove = idx{1};
    vertsLeft(idRemove, :) = [];
    
    itt = itt + 1;
end
end