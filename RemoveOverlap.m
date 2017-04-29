function [ Remain, D ] = removeOverlap( Source, Target, Options )
%UNTITLED2 此处显示有关此函数的摘要
%   此处显示详细说明

%% Process
disp('* Remove Overlap Processing...');
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
[IDX, D] = knnsearch(vertsTarget, vertsSource);
knnTime = toc;
fprintf('KNN Time: %fs\n', knnTime);

%[N,edges] = histcounts(D);

% nearest point is not boundary point
if Options.ignoreBoundaryBool
    removedIndicator = (D < Options.overlapDistThreshold) & ~Target.isBoundary(IDX);
elseif Options.ignoreBoundary
    %%%%TODO
else
    removedIndicator = D < Options.overlapDistThreshold;
end

removedIdx = find(removedIndicator);

tic;
[Remain.vertices, Remain.faces] = removeMeshVertices(vertsSource, facesSource, removedIdx);
removeTime = toc;
fprintf('Vertices remove Time: %fs\n', removeTime);

if ~isempty(normalsSource)
    Remain.normals = normalsSource(~removedIndicator, :);
end

if isfield(Source, 'colors') && ~isempty(Source.colors)
    Remain.colors = Source.colors(~removedIndicator, :);
end


% Optionally plot source and target surfaces
if Options.plot == 1
    clf;
    PlotTarget.vertices = Target.vertices;
    PlotTarget.faces = Target.faces;
    p = patch(PlotTarget, 'facecolor', 'b', 'EdgeColor',  'none', ...
              'FaceAlpha', 0.0);
    hold on;
    
    PlotSource.vertices = Remain.vertices;
    PlotSource.faces = Remain.faces;
    h = patch(PlotSource, 'facecolor', 'r', 'EdgeColor',  'none', ...
        'FaceAlpha', 0.5);
    material dull; light; grid on; xlabel('x'); ylabel('y'); zlabel('z');
    view([60,30]); axis equal; axis manual;
    legend('Target', 'Source', 'Location', 'best')
    drawnow;
end

% % write output
% if ~isempty(normalsSource)
%     writePlyVFN(strcat(outputPath, '/outCropped.ply'), vertsRemained, facesRemained, normalsRemained, 'ascii');
% else
%     writePLY(strcat(outputPath, '/outCropped.ply'), vertsRemained, facesRemained, 'ascii');
% end

end

