function [ vertsTransformed ] = applyTransform( verts, transMat )
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

vertsTransformed = [verts ones(size(verts, 1), 1)] * transMat';
vertsTransformed = vertsTransformed(:, 1:3);

end

