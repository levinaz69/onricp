%% leftfoot
sourceFile = 'data/arm_4/template_transformed.ply';
targetFile = 'data/arm_4/total_without_faces_voxel_0.1_mls_0.3_add_faces.ply';
sourceMarker = 'data/arm_4/template_markers_transformed.xyz';
targetMarker = 'data/arm_4/total_without_faces_voxel_0.1_mls_0.3_add_faces_markers.xyz';

Options.useMarker = 1;
Options.normalWeighting = 1;
Options.alphaSet = linspace(1, 0.5, 5);
Options.epsilon = logspace(-3, -5, 5);


%% Init
Source.normals = [];
Target.normals = [];

% Read OBJ
% [Source.vertices, Source.faces, ~, ~, Source.normals] = readOBJ(sourceFile);
% [Target.vertices, Target.faces, ~, ~, Target.normals] = readOBJ(targetFile);

% Read PLY
[Source.vertices, Source.faces] = readPLY(sourceFile);
[Target.vertices, Target.faces] = readPLY(targetFile);

pcSource = pcread(sourceFile);
pcTarget = pcread(targetFile);
Source.normals = pcSource.Normal;
Target.normals = pcTarget.Normal;

% Read markers
if (Options.useMarker)
    Source.markers = load(sourceMarker);
    Target.markers = load(targetMarker);
end


% Options
Options.GPU = 0;
Options.plot = 1;       % ricp & nricp
Options.verbose = 1;

Options.snapTarget = 0;
Options.useNormals = 0;
% Options.normalWeighting = 1;
% Options.useMarker = 1;
Options.ignoreBoundary = 1;     % ricp & nricp
Options.beta = 1;
% %Options.alphaSet = 2.^(15:-1:5);
% Options.alphaSet = linspace(1, 0.1, 5);
% Options.epsilon = logspace(-3, -5, 5);


%% Straightforward
% % Perform rigid ICP
% [~, Options.initX] = ricp(Source, Target, Options);
% 
% % Perform non-rigid ICP
% Options.rigidInit = 0;
% [pointsTransformed, X] = onricp(Source, Target, Options);


%% Normalize 
% Normalize data (scale & translate)
SourceTransformed = Source;
TargetTransformed = Target;

[TargetTransformed.vertices, normalizationMatrix] = normalizePolygon(Target.vertices);
SourceTransformed.vertices = applyTransform(Source.vertices, normalizationMatrix);
if (Options.useMarker)
    SourceTransformed.markers = applyTransform(Source.markers, normalizationMatrix);
    TargetTransformed.markers = applyTransform(Target.markers, normalizationMatrix);
end

% Perform rigid ICP
[~, Options.initX] = ricp(SourceTransformed, TargetTransformed, Options);

% Perform non-rigid ICP
Options.rigidInit = 0;
[pointsNricpTransformed, X] = onricp(SourceTransformed, TargetTransformed, Options);

% Transform to original coordinate system
vertsOutput = applyTransform(pointsNricpTransformed, inv(normalizationMatrix));

% write output
writePLY('data/out.ply', vertsOutput, SourceTransformed.faces, 'ascii');
writePLY('data/outTrans.ply', pointsNricpTransformed, SourceTransformed.faces, 'ascii');
writePLY('data/tarTrans.ply', TargetTransformed.vertices, TargetTransformed.faces, 'ascii');

