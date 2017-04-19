
%% legs_out
sourceFile = 'data/legs_subdiv_290k_appendMarkers/outTrans.ply';
targetFile = 'data/legs_subdiv_290k_appendMarkers/tarTrans.ply';
sourceMarker = 'data/legs_subdiv_290k_appendMarkers/outTrans_markers.idx';
targetMarker = 'data/legs_subdiv_290k_appendMarkers/tarTrans_markers.idx';
Options.useMarkerIdx = 1;

% Options.initX = [0.998260997764286,-0.0522847088556057,0.0272266333312242,-0.168972675954147;0.0511657325828864,0.997877139481508,0.0402899777794133,0.202175028509951;-0.0292753847442638,-0.0388268427778171,0.998817014336456,-0.142880837870657]

% %% legs_subdiv
% sourceFile = 'data/legs_subdiv_290k_appendMarkers/template.ply';
% targetFile = 'data/legs_subdiv_290k_appendMarkers/target.ply';
% sourceMarker = 'data/legs_subdiv_290k_appendMarkers/template_markers.xyz';
% targetMarker = 'data/legs_subdiv_290k_appendMarkers/target_markers.xyz';
% Options.useMarkerIdx = 0;

% %% legs
% sourceFile = 'data/legs/template.ply';
% targetFile = 'data/legs/target.ply';
% 
% % sourceMarker = 'data/legs/template_markers.idx';
% % targetMarker = 'data/legs/target_markers.idx';
% % Options.useMarkerIdx = 1;
% 
% sourceMarker = 'data/legs/template_markers.xyz';
% targetMarker = 'data/legs/target_markers.xyz';
% Options.useMarkerIdx = 0;

%%
Options.useMarker = 1;
Options.normalWeighting = 1;
Options.alphaSet = linspace(1, 0.5, 5);
Options.epsilon = logspace(-3, -5, 5);
Options.beta = 1;

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
% Options.beta = 1;   % marker weight
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
end

% Perform non-rigid ICP
Options.rigidInit = 0;
[vertsNricpTransformed, normalsNricpTransformed, X] = onricp(SourceTransformed, TargetTransformed, Options);

% Transform to original coordinate system
vertsOutput = applyTransform(pointsNricpTransformed, inv(normalizationMatrix));

% write output
writePlyVFN('data/out.ply', vertsOutput, SourceTransformed.faces, normalsNricpTransformed, 'ascii');
writePlyVFN('data/outTrans.ply', vertsNricpTransformed, SourceTransformed.faces, normalsNricpTransformed, 'ascii');
writePlyVFN('data/tarTrans.ply', TargetTransformed.vertices, TargetTransformed.faces, TargetTransformed.normals, 'ascii');

