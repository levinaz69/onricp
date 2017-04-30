%% Meta list
baseDir = 'data';
patchList = {'head', 'legs', 'larm', 'rarm', 'lfoot', 'rfoot'};
modelList = {'FRM_0245', 'FRM_0259'};

%% Generate List
subDirNameList = {};
workPathList = {};
sourceNameList = {};
targetNameList = {};
for model = modelList
    for patch = patchList
        subDirNameList = [subDirNameList, {patch}];
        workPathList = [workPathList, {fullfile(baseDir, model)}];
        sourceNameList = [sourceNameList, {'template'}];
        targetNameList = [targetNameList, {model}];
    end
end

for dirIndex = 1:length(subDirNameList)

    clearvars;

    subDirName = subDirNameList{dirIndex};
    workPath = workPathList{dirIndex};
    sourceName = sourceNameList{dirIndex};
    targetName = targetNameList{dirIndex};


    %% Set file paths
    basePath = pwd;
    subDirPath = strcat(workPath, '/', subDirName);

    outputPath = strcat(workPath, 'OUTPUT/');
    if exist(outputPath, 'dir') ~= 7
        mkdir(outputPath);
    end

    sourceFile = strcat(subDirPath, '/', sourceName, '.ply');
    % targetFile = strcat(subDirPath, '/', targetName, '.ply');
    targetFile = strcat(subDirPath, '/../', targetName, '.ply');

    sourceMarker = strcat(subDirPath, '/', sourceName, '_markers.xyz');
    targetMarker = strcat(subDirPath, '/', targetName, '_markers.xyz');

    sourceTransName = strcat(sourceName, '_transformed');
    sourceMarkerTransName = strcat(sourceName, '_markers_transformed');
    sourceFileTrans = strcat(subDirPath, '/', sourceTransName, '.ply');
    sourceMarkerTrans = strcat(subDirPath, '/', sourceMarkerTransName, '.xyz');

    % targetBoundary = strcat(subDirPath, '/', targetName, '.bd');
    targetBoundary = strcat(subDirPath, '/../', targetName, '.bd');


    %% Step 1: Set markers
    cd(fullfile(basePath, workPath, subDirName));
    cmd = strjoin({fullfile(basePath, 'bin', 'ManualRegistration'), strcat('..\', targetName, '.ply'), strcat(sourceName, '.ply')});
    system(cmd);
    cd(basePath);


    %% Step 2: Similarity transformation
    cd(fullfile(basePath, workPath, subDirName));
    cmd = strjoin({fullfile(basePath, 'bin', 'LandmarkTransform'), strcat(sourceName, '_markers.xyz'), strcat(targetName, '_markers.xyz'), strcat(sourceName, '.ply')});
    system(cmd);
    cd(basePath);
    clear Source;

    %% Step 2+: TPS transformation
    cd(fullfile(basePath, workPath, subDirName));
    cmd = strjoin({fullfile(basePath, 'bin', 'TPSTransform'), strcat(sourceMarkerTransName, '.xyz'), strcat(targetName, '_markers.xyz'), strcat(sourceTransName, '.ply')});
    system(cmd);
    sourceFileTrans = strcat(subDirPath, '/', sourceTransName, '_tpsTransformed.ply');
    sourceMarkerTrans = strcat(subDirPath, '/', sourceMarkerTransName, '_tpsTransformed.xyz');
    cd(basePath);
    clear Source;


    %% Step 3: Non-rigid iterative closest point
    cd(basePath);
    %%%% Options BEGIN
    % Options.alphaSet = linspace(1, 0.5, 5);
    Options.alphaSet = 2.^linspace(0, -4, 5);
    % Options.alphaSet = 2.^(15:-1:5);
    Options.betaSet = linspace(1, 0, 5);
    Options.epsilonSet = logspace(-3, -5, 5);

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
    cd(basePath);

    %%%%
    Options.overlapDistThreshold = 0.05;
    Options.plot = 0;

    [OutCropped, knnDist] = removeOverlap(Out, Target, Options);

    if Options.plot
        [N,edges] = histcounts(knnDist);
        edgeLabels = cell(1, length(edges(2:end)));
        for i = 1:length(edges(2:end))
            edgeLabels{i} = num2str(edges(1 + i));
        end
        figure; pie(N, edges(2:end), edgeLabels);
    end

    % Write output
    if isfield(OutCropped, 'colors')
        writePlyVFNC(strcat(outputPath, subDirName, '_out_cropped.ply'), OutCropped.vertices, OutCropped.faces, OutCropped.normals, OutCropped.colors, 'binary_little_endian');
    else 
        writePlyVFN(strcat(outputPath, subDirName, '_out_cropped.ply'), OutCropped.vertices, OutCropped.faces, OutCropped.normals, 'binary_little_endian');
    end

end