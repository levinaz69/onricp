
%% File path
outputPath = 'data/right_arm3/';
sourceFile = 'data/right_arm3/out.ply';
targetFile = 'data/tar.ply';

%% Read PLY
disp('* Load point cloud/mesh...');
% source
[Target.vertices, Target.faces] = readPLY(targetFile);
pcTarget = pcread(targetFile);
Target.normals = pcTarget.Normal;
% target
[Source.vertices, Source.faces] = readPLY(sourceFile);
pcSource = pcread(sourceFile);
Source.normals = pcSource.Normal;


%% Options
threshold = 0.04;
plot = 1;

%% Process
disp('* Processing...');
vertsSource = Source.vertices;
vertsTarget = Target.vertices;
facesSource = Source.faces;
normalsSource = Source.normals;

%TODO1:
%  Make it more robust by 
%  search for k neighborhoods and 
%  only if all of them in dist threshold 
%  then remove this vert

%IDEA:
%  use boundary condition:
%  if knn is a boundary vert, 
%  do not remove

tic;
[IDX,D] = knnsearch(vertsTarget, vertsSource);
knnTime = toc;
fprintf('KNN Time: %fs\n', knnTime);

[N,edges] = histcounts(D);

removedIndicator = D < threshold;
removedIdx = find(removedIndicator);
tic;
[vertsRemained, facesRemained] = removeMeshVertices(vertsSource, facesSource, removedIdx);
removeTime = toc;
fprintf('Vertices remove Time: %fs\n', removeTime);

if ~isempty(normalsSource)
    normalsRemained = normalsSource(~removedIndicator, :);
end

% Optionally plot source and target surfaces
if plot == 1
    clf;
    PlotTarget.vertices = Target.vertices;
    PlotTarget.faces = Target.faces;
    p = patch(PlotTarget, 'facecolor', 'b', 'EdgeColor',  'none', ...
              'FaceAlpha', 0.0);
    hold on;
    
    PlotSource.vertices = vertsRemained;
    PlotSource.faces = facesRemained;
    h = patch(PlotSource, 'facecolor', 'r', 'EdgeColor',  'none', ...
        'FaceAlpha', 0.5);
    material dull; light; grid on; xlabel('x'); ylabel('y'); zlabel('z');
    view([60,30]); axis equal; axis manual;
    legend('Target', 'Source', 'Location', 'best')
    drawnow;
end

% write output
if ~isempty(normalsSource)
    writePlyVFN(strcat(outputPath, '/outCropped.ply'), vertsRemained, facesRemained, normalsRemained, 'ascii');
else
    writePLY(strcat(outputPath, '/outCropped.ply'), vertsRemained, facesRemained, 'ascii');
end

