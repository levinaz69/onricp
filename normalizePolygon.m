function [ vertsTransformed, normalizationMatrix ] = normalizePolygon( verts )
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here


bBox = boundingBox3d(verts);

bBoxSize = bBox([2 4 6]) - bBox([1 3 5]);
center = (bBox([2 4 6]) + bBox([1 3 5])) ./ 2;
scale = max(bBoxSize);

normalizationMatrix = [eye(3) ./ scale .* 2, zeros(3,1); zeros(1,3), 1] * ...
                    [eye(3), -center'; zeros(1,3), 1];
vertsTransformed = [verts ones(size(verts, 1), 1)] * normalizationMatrix';
vertsTransformed = vertsTransformed(:, 1:3);

end

