%% Normalize 
% Normalize data (scale & translate)
SourceTransformed = Source;
TargetTransformed = Target;

[SourceTransformed.vertices, normalizationMatrix] = normalizePolygon(Source.vertices);
TargetTransformed.vertices = applyTransform(Target.vertices, normalizationMatrix);

if (Options.useMarker)
    if (~Options.useMarkerIdx)
        SourceTransformed.markers = applyTransform(Source.markers, normalizationMatrix);
        TargetTransformed.markers = applyTransform(Target.markers, normalizationMatrix);
    else
        SourceTransformed.markers = Source.markers;
        TargetTransformed.markers = Target.markers;
    end
end

% Perform non-rigid ICP
Options.rigidInit = 0;
[vertsNricpTransformed, normalsNricpTransformed, X, colorsNricpTransformed] = onricp(SourceTransformed, TargetTransformed, Options);

% Transform to original coordinate system
vertsOutput = applyTransform(vertsNricpTransformed, inv(normalizationMatrix));

Out.vertices = vertsOutput;
Out.faces = SourceTransformed.faces;
Out.normals = normalsNricpTransformed;
if Options.useColor
    Out.colors = colorsNricpTransformed;
end