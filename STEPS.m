clearvars;

subDirName = 'head';

workPath = 'data/template_cut/';
outputPath = strcat(workPath, 'OUTPUT/');
sourceName = 'template';
targetName = 'target';

%% Set file paths
basePath = pwd;
subDirPath = strcat(workPath, '/', subDirName);

sourceFile = strcat(subDirPath, '/', sourceName, '.ply');
% targetFile = strcat(subDirPath, '/', targetName, '.ply');
targetFile = strcat(subDirPath, '/../', targetName, '.ply');
sourceMarker = strcat(subDirPath, '/', sourceName, '_markers.xyz');
targetMarker = strcat(subDirPath, '/', targetName, '_markers.xyz');
sourceFileTrans = strcat(subDirPath, '/', sourceName, '_transformed.ply');
sourceMarkerTrans = strcat(subDirPath, '/', sourceName, '_markers_transformed.xyz');
% targetBoundary = strcat(subDirPath, '/', targetName, '.bd');
targetBoundary = strcat(subDirPath, '/../', targetName, '.bd');


%% Step 1: Set markers
cd(subDirPath);
cmd = strjoin({'..\ManualRegistration', strcat('..\', targetName, '.ply'), strcat(sourceName, '.ply')});
system(cmd);
cd(basePath);


%% Step 2: Similarity transformation
cd(subDirPath);
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
    writePlyVFNC(strcat(outputPath, subDirName, '_out.ply'), Out.vertices, Out.faces, Out.normals, Out.colors, 'binary_little_endian');
else 
    writePlyVFN(strcat(outputPath, subDirName, '_out.ply'), Out.vertices, Out.faces, Out.normals, 'binary_little_endian');
end


%% Step 4: Remove overlaps
Options.overlapDistThreshold = 0.05;
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
    writePlyVFNC(strcat(outputPath, subDirName, '_out_cropped.ply'), OutCropped.vertices, OutCropped.faces, OutCropped.normals, OutCropped.colors, 'binary_little_endian');
else 
    writePlyVFN(strcat(outputPath, subDirName, '_out_cropped.ply'), OutCropped.vertices, OutCropped.faces, OutCropped.normals, 'binary_little_endian');
end

