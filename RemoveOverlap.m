threshold = 0.001;
plot = 1;

%% File path
sourceFile = 'data/outTrans.ply';
targetFile = 'data/tarTrans.ply';

% Read PLY
[Source.vertices, Source.faces] = readPLY(sourceFile);
[Target.vertices, Target.faces] = readPLY(targetFile);

pcSource = pcread(sourceFile);
pcTarget = pcread(targetFile);
Source.normals = pcSource.Normal;
Target.normals = pcTarget.Normal;


%% Process
vertsSource = Source.vertices;
vertsTarget = Target.vertices;
facesSource = Source.faces;
normalsSource = Source.normals;

[IDX,D] = knnsearch(vertsTarget, vertsSource);
% [N,edges] = histcounts(D);

removedIndicator = D < threshold;
removedIdx = find(removedIndicator);
[vertsRemained, facesRemained] = removeMeshVertices(vertsSource, facesSource, removedIdx);

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
    writePlyVFN('data/outCropped.ply', vertsRemained, facesRemained, normalsRemained, 'ascii');
else
    writePLY('data/outCropped.ply', vertsRemained, facesRemained, 'ascii');
end

