%% Read data
% if exist, not change

% if ~exist('Source', 'var')
    pcSource = pcread(sourceFileTrans);
    Source.vertices = double(pcSource.Location);
    Source.normals = double(pcSource.Normal);
    
    [~, Source.faces] = readPLY(sourceFileTrans);
    
% end

% if ~exist('Target', 'var')
    pcTarget = pcread(targetFile);
    Target.vertices = double(pcTarget.Location);
    Target.normals = double(pcTarget.Normal);

    Target.faces = [];
    if Options.ignoreBoundary
        [~, Target.faces] = readPLY(targetFile);
    end

    % Read target boundary
    if (Options.ignoreBoundaryBool)
        isBoundary = textread(targetBoundary,'%u',-1, 'headerlines',11);
        Target.isBoundary = logical(isBoundary);
    end
    
% end


if (Options.useColor)
    Target.colors = pcTarget.Color;
end

if (Options.useMarker)
    Source.markers = load(sourceMarkerTrans);
    Target.markers = load(targetMarker);
end

