
outputPath = 'data/';
%% File Path
sourceFile = 'data/template_cut/right_arm3/template.ply';
targetFile = 'data/template_cut/total_without_faces_voxel_0.1_mls_0.3_add_faces.ply';
sourceMarker = 'data/template_cut/right_arm3/template_markers.xyz';
targetMarker = 'data/template_cut/right_arm3/pcMerged_markers.xyz';

% targetBoundary = 'data/template_cut/pcMerged.bd';

Options.useMarkerIdx = 0;
Options.ignoreBoundary = 1;     % ricp & nricp
Options.ignoreBoundaryBool = 0;

%% Options
% Options.initX = [0.998260997764286,-0.0522847088556057,0.0272266333312242,-0.168972675954147;0.0511657325828864,0.997877139481508,0.0402899777794133,0.202175028509951;-0.0292753847442638,-0.0388268427778171,0.998817014336456,-0.142880837870657]

Options.useMarker = 1;
Options.normalWeighting = 1;
Options.alphaSet = linspace(1, 0.5, 5);
% Options.alphaSet = 2.^linspace(0, -4, 5);
% Options.alphaSet = 2.^(15:-1:5);
Options.epsilon = logspace(-3, -5, 5);
Options.beta = 1;

Options.GPU = 0;
Options.plot = 0;       % ricp & nricp
Options.verbose = 1;

Options.snapTarget = 0;
Options.useNormals = 0;

%% Init
% Source.normals = [];
% Target.normals = [];
% Read OBJ
% [Source.vertices, Source.faces, ~, ~, Source.normals] = readOBJ(sourceFile);
% [Target.vertices, Target.faces, ~, ~, Target.normals] = readOBJ(targetFile);

% Read PLY
pcSource = pcread(sourceFile);
pcTarget = pcread(targetFile);

Source.vertices = double(pcSource.Location);
Target.vertices = double(pcTarget.Location);
Source.normals = double(pcSource.Normal);
Target.normals = double(pcTarget.Normal);

[~, Source.faces] = readPLY(sourceFile);
Target.faces = [];
if Options.ignoreBoundary
    [~, Target.faces] = readPLY(targetFile);
end

% Read markers
if (Options.useMarker)
    Source.markers = load(sourceMarker);
    Target.markers = load(targetMarker);
end

% Read target boundary
if (Options.ignoreBoundaryBool)
    Target.isBoundary = logical(load(targetBoundary));
end

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

% Perform rigid ICP
if ~isfield(Options, 'initX')
    [~, Options.initX] = ricp(SourceTransformed, TargetTransformed, Options);
    
%     normalization_tform = affine3d(normalizationMatrix);
%     pcSourceTransformed = pctransform(pcSource, normalization_tform);
%     pcTargetTransformed = pctransform(pcTarget, normalization_tform);
%     [~, Options.initX] = ricp_matlab(pcSourceTransformed, pcTargetTransformed);
end

% Perform non-rigid ICP
Options.rigidInit = 0;
[vertsNricpTransformed, normalsNricpTransformed, X] = onricp(SourceTransformed, TargetTransformed, Options);

% Transform to original coordinate system
vertsOutput = applyTransform(vertsNricpTransformed, inv(normalizationMatrix));

% write output
writePlyVFN(strcat(outputPath, '/out.ply'), vertsOutput, SourceTransformed.faces, normalsNricpTransformed, 'ascii');
writePlyVFN(strcat(outputPath, '/tar.ply'), Target.vertices, Target.faces, Target.normals, 'ascii');
writePlyVFN(strcat(outputPath, '/outTrans.ply'), vertsNricpTransformed, SourceTransformed.faces, normalsNricpTransformed, 'ascii');
writePlyVFN(strcat(outputPath, '/tarTrans.ply'), TargetTransformed.vertices, TargetTransformed.faces, TargetTransformed.normals, 'ascii');

