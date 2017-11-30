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

    % targetFile = strcat(subDirPath, '/', targetName, '.ply');
    targetFile = strcat(subDirPath, '/../', targetName, '.ply');

	outFile = strcat(outputPath, subDirName, '_out.ply')

    % targetBoundary = strcat(subDirPath, '/', targetName, '.bd');
    targetBoundary = strcat(subDirPath, '/../', targetName, '.bd');
	
    pcTarget = pcread(targetFile);
    Target.vertices = double(pcTarget.Location);
    Target.normals = double(pcTarget.Normal);
	
	if (Options.ignoreBoundaryBool)
        isBoundary = textread(targetBoundary,'%u',-1, 'headerlines',11);
        Target.isBoundary = logical(isBoundary);
    end
	
	%% Read data
	pcOut = pcread(outFile);
    Out.vertices = double(pcOut.Location);
    Out.normals = double(pcOut.Normal);
	Out.colors = pcOut.Color;
	%[~, Out.faces] = readPLY(outFile);
	
	

    %% Step 4: Remove overlaps
    cd(basePath);

    %%%%
    Options.overlapDistThreshold = 0.05;
    Options.plot = 1;

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