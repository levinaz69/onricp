%% Meta list
baseDir = 'data/2017-12/';
patchList = {'head2', 'legs2', 'larm', 'rarm', 'lfoot', 'rfoot','left_hand','right_hand'};
modelList = {'0093'};

%% Generate List
subDirNameList = {};
workPathList = {};
sourceNameList = {};
targetNameList = {};
for model = modelList
    for patch = patchList
        subDirNameList = [subDirNameList, patch];
        workPathList = [workPathList, fullfile(baseDir, model)];
        sourceNameList = [sourceNameList, 'template'];
        targetNameList = [targetNameList, 'target'];
    end
end


for dirIndex = 1:length(subDirNameList)

    subDirName = subDirNameList{dirIndex};
    workPath = workPathList{dirIndex};
    sourceName = sourceNameList{dirIndex};
    targetName = targetNameList{dirIndex};


    %% Set file paths
    basePath = pwd;
    subDirPath = strcat(workPath, '/', subDirName);

    outputPath = strcat(workPath, '/OUTPUT/');
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

    %% Step 4: Remove overlaps
    cd(basePath);
    
    Options.ignoreBoundary = 0;
    Options.ignoreBoundaryBool = 1;
    Options.useColor = 1;
    Options.useMarker = 1;
    
    readData
    
    outFile = strcat(outputPath, subDirName, '_out.ply');
    pcOut = pcread(outFile);
    Out.vertices = double(pcOut.Location);
    Out.normals = double(pcOut.Normal);
    [~, Out.faces] = readPLY(outFile);
    
    %%%%
    Options.overlapDistThreshold = 2;
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