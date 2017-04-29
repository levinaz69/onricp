function [ pcTransformed, X ] = ricp_matlab( pcSource, pcTarget )

% Do rigid iterative closest point if Options.rigidInit == 1
disp('* Performing matlab rigid ICP...');



[R, t] = icp(vertsTarget', vertsSource', 50, 'Verbose', true, ...
    'EdgeRejection', logical(Options.ignoreBoundary), ...
    'Boundary', bdr');

X = [R, t];
vertsSource = [vertsSource, ones(nVertsSource, 1)];
vertsTransformed = vertsSource*X';

% Update plot
if Options.plot == 1
    set(h, 'Vertices', vertsTransformed);
    drawnow;
end

end