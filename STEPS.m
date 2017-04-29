clearvars;

workPath = 'data/template_cut/head';
sourceName = 'template';
targetName = 'target';

%% Set file paths
basePath = pwd;

sourceFile = strcat(workPath, '/', sourceName, '.ply');
% targetFile = strcat(workPath, '/', targetName, '.ply');
targetFile = strcat(workPath, '/../', targetName, '.ply');
sourceMarker = strcat(workPath, '/', sourceName, '_markers.xyz');
targetMarker = strcat(workPath, '/', targetName, '_markers.xyz');
sourceFileTrans = strcat(workPath, '/', sourceName, '_transformed.ply');
sourceMarkerTrans = strcat(workPath, '/', sourceName, '_markers_transformed.xyz');
% targetBoundary = strcat(workPath, '/', targetName, '.bd');
targetBoundary = strcat(workPath, '/../', targetName, '.bd');


%% Step 1: Set markers
cd(workPath);
cmd = strjoin({'..\ManualRegistration', strcat('..\', targetName, '.ply'), strcat(sourceName, '.ply')});
system(cmd);
cd(basePath);


%% Step 2: Similarity transformation
cd(workPath);
cmd = strjoin({'..\LandmarkTransform', strcat(sourceName, '_markers.xyz'), strcat(targetName, '_markers.xyz'), strcat(sourceName, '.ply')});
system(cmd);
cd(basePath);
clear Source;


%% Step 3: Non-rigid iterative closest point
%%%% Options BEGIN
Options.alphaSet = linspace(1, 0.5, 5);
% Options.alphaSet = 2.^linspace(0, -4, 5);
% Options.alphaSet = 2.^(15:-1:5);
Options.epsilon = logspace(-3, -5, 5);
Options.beta = 1;

Options.useColor = 1;
Options.useMarker = 1;
Options.useMarkerIdx = 0;
Options.ignoreBoundary = 0;
Options.ignoreBoundaryBool = 1;
Options.normalWeighting = 1;
Options.verbose = 1;
Options.plot = 0;
%%%% Options END

readData

runOnricp

% Write output
if isfield(Out, 'colors')
    writePlyVFNC(strcat(workPath, '/out.ply'), Out.vertices, Out.faces, Out.normals, Out.colors, 'binary_little_endian');
else 
    writePlyVFN(strcat(workPath, '/out.ply'), Out.vertices, Out.faces, Out.normals, 'binary_little_endian');
end


%% Step 4: Remove overlaps
Options.overlapDistThreshold = 0.06;
Options.plot = 1;

[OutCropped, knnDist] = removeOverlap(Out, Target, Options);

[N,edges] = histcounts(knnDist);
edgeLabels = cell(1, length(edges(2:end)));
for i = 1:length(edges(2:end))
    edgeLabels{i} = num2str(edges(1 + i));
end
figure; pie(N, edges(2:end), edgeLabels);

% Write output
if isfield(OutCropped, 'colors')
    writePlyVFNC(strcat(workPath, '/outCropped.ply'), OutCropped.vertices, OutCropped.faces, OutCropped.normals, OutCropped.colors, 'binary_little_endian');
else 
    writePlyVFN(strcat(workPath, '/outCropped.ply'), OutCropped.vertices, OutCropped.faces, OutCropped.normals, 'binary_little_endian');
end

