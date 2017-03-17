function [ vertsTransformed, X ] = ricp( Source, Target, Options )
% ricp performs a rigid ICP.
%
% Inputs:
%   Source: structured object with fields - 
%       Source.vertices: V x 3 vertices of template model
%       Source.faces: F x 3 list of connected vertices.
%       Source.normals: (Optional) FV x 3 list of surface normals. Make
%           sure to set Options.normals = 1 if using normals.
% 
%   Target : stuctured object as above for target model.
% 
%   Options : structured object with fields:
%       ignoreBoundary : logical, whether get boundary vertex indices on
%           target surface. need topological structure of target surface.
%       plot : logical, specifies that the transformations should be
%           plotted.
% Outputs:
%   vertsTransformed : N X 3 vertices of transformed source mesh,
%   X : 4 X 3 stacked matrix of transformations.

% Set default parameters
if ~isfield(Options, 'plot')
    Options.plot = 0;
end
if ~isfield(Options, 'ignoreBoundary')
    Options.ignoreBoundary = 1;
end


% Optionally plot source and target surfaces
if Options.plot == 1
    clf;
    PlotTarget = rmfield(Target, 'normals');
    p = patch(PlotTarget, 'facecolor', 'b', 'EdgeColor',  'none', ...
              'FaceAlpha', 0.5);
    hold on;
    
    PlotSource = rmfield(Source, 'normals');
    h = patch(PlotSource, 'facecolor', 'r', 'EdgeColor',  'none', ...
        'FaceAlpha', 0.5);
    material dull; light; grid on; xlabel('x'); ylabel('y'); zlabel('z');
    view([60,30]); axis equal; axis manual;
    legend('Target', 'Source', 'Location', 'best')
    drawnow;
end


% Get source vertices 
vertsSource = Source.vertices;
nVertsSource = size(vertsSource, 1);

% Get target vertices
vertsTarget = Target.vertices;

% Get boundary vertex indices on target surface if required.
% Need topological structure of target surface
if Options.ignoreBoundary == 1
    bdr = find_bound(vertsTarget, Target.faces);
else
    bdr = 0;
end

% Do rigid iterative closest point if Options.rigidInit == 1
disp('* Performing rigid ICP...');
[R, t] = icp(vertsTarget', vertsSource', 50, 'Verbose', true, ...
    'EdgeRejection', logical(Options.ignoreBoundary), ...
    'Boundary', bdr');

X = [R, t];
vertsSource = [vertsSource, ones(nVertsSource, 1)];
vertsTransformed = vertsSource*X;

% Update plot
if Options.plot == 1
    set(h, 'Vertices', vertsTransformed);
    drawnow;
end

end