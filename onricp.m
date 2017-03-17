function [ vertsTransformed, X ] = onricp( Source, Target, Options )
% nricp performs an adaptive stiffness variant of non rigid ICP.
%
% This function deforms takes a dense set of landmarks points from a template
% template model and finds a deformation which matches a target shape. 
% The deformations are encouraged to be natural and smooth by means of a 
% stiffness constraint, which is relaxed in increments.
% 
% For details on the stiffness constraint and optimization procedure see: 
% 'Optimal Step Nonrigid ICP Algorithms for Surface Registration', 
% Amberg, Romandhani and Vetter, CVPR, 2007.
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
%       gamm : real valued, weights differences in the rotational and skew
%           part of the deformation against the translational part.
%       epsilon : real values, tolerence for change in transformation.
%       lambda : If using the bi-directional distance metric this weights
%           the contribution of the target -> source term.
%       alphaSet : decreasing vector of real-valued stiffness parameters. 
%           High stiffness parameters force global transformations whereas 
%           low values allow for local deformations.
%       biDirectional : logical, specifies that a bi-directional distance 
%           is used.
%       useNormals : logical, specifies that surface normals are to be used
%           to project the source onto the target surface. If this term is
%           used then the Source input should contain a normals field.
%       plot : logical, specifies that the transformations should be
%           plotted.
%       rigidInit : logical, specifies that rigid ICP should be performed
%           first before allowing non-rigid and non-global deformations.
%
% Outputs:
%   vertsTransformed : N X 3 vertices of transformed source mesh,
%   X : (4N) X 3 stacked matrix of transformations.

% Set default parameters
if ~isfield(Options, 'gamm')
    Options.gamm = 1;
end
if ~isfield(Options, 'beta')
    Options.beta = 1;
end
if ~isfield(Options, 'lambda')
    Options.lambda = 1;
end
if ~isfield(Options, 'epsilon')
    Options.epsilon = 1e-4;
end
if ~isfield(Options, 'alphaSet')
    Options.alphaSet = linspace(100, 10, 20);
end
if ~isfield(Options, 'biDirectional')
    Options.biDirectional = 0;
end
if ~isfield(Options, 'useNormals')
    Options.useNormals = 0;
end
if ~isfield(Options, 'plot')
    Options.plot = 0;
end
if ~isfield(Options, 'rigidInit')
    Options.rigidInit = 1;
end
if ~isfield(Options, 'ignoreBoundary')
    Options.ignoreBoundary = 1;
end
if ~isfield(Options, 'normalWeighting')
    Options.normalWeighting = 1;
end
if ~isfield(Options, 'normalDiffThreshold')
    Options.normalDiffThreshold = pi / 4;
end
if ~isfield(Options, 'useMarker')
    Options.useMarker = 0;
end
if ~isfield(Options, 'GPU')
    Options.GPU = 0;
end
if ~isfield(Options, 'snapTarget')
    Options.snapTarget = 0;
end
if ~isfield(Options, 'verbose')
    Options.verbose = 0;
end
if ~isfield(Options, 'initX')
    Options.initX = [];
end


% Optionally plot source and target surfaces
if Options.plot == 1
    clf;
    PlotTarget.vertices = Target.vertices;
    PlotTarget.faces = Target.faces;
    p = patch(PlotTarget, 'facecolor', 'b', 'EdgeColor',  'none', ...
              'FaceAlpha', 0.5);
    hold on;
    
    PlotSource.vertices = Source.vertices;
    PlotSource.faces = Source.faces;
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

% Optionally get source / target normals
if Options.normalWeighting == 1
    normalsSource = Source.normals;
    normalsTarget = Target.normals;
    N = sparse(nVertsSource, 4 * nVertsSource);
    for j = 1:nVertsSource
        N(j,(4 * j-3):(4 * j)) = [normalsSource(j,:) 1];
    end
end

% Get landmark vertices of source and target
if Options.useMarker == 1
    % Get source markers xyz
    markersSource = Source.markers;
    nMarkersSource = size(markersSource, 1);
    % Get target markers 
    markersTarget = Target.markers;
    
    % Assume markers are xyz coordinates
    markersSourseKnnId = knnsearch(vertsSource, markersSource);
    DL = sparse(nMarkersSource, 4 * nVertsSource);
    for i = 1:nMarkersSource
        knnId = markersSourseKnnId(i);
        DL(i,(4 * knnId-3):(4 * knnId)) = [vertsSource(knnId, :) 1];
    end

    UL = markersTarget;
end

% Get subset of target vertices if Options.biDirectional == 1
if Options.biDirectional == 1
    samplesTarget = sampleVerts(Target, 0.15);
    nSamplesTarget = size(samplesTarget, 1);
end

% Set matrix G (equation (3) in Amberg et al.) 
G = diag([1 1 1 Options.gamm]);

% Set incidence matrix M 
A = triangulation2adjacency(Source.faces, Source.vertices);
M = adjacency2incidence(A)';

% Precompute kronecker product of M and G
kron_M_G = kron(M, G);

% Set matrix D (equation (8) in Amberg et al.)
D = sparse(nVertsSource, 4 * nVertsSource);
for i = 1:nVertsSource
    D(i,(4 * i-3):(4 * i)) = [vertsSource(i,:) 1];
end

% Set weights vector
wVec = ones(nVertsSource,1);

% Get boundary vertex indices on target surface if required.
% Need topological structure of target surface
if Options.ignoreBoundary == 1
    bdr = find_bound(vertsTarget, Target.faces);
end

% Set target points matrix tarU and target weights matrix tarU
% if Options.biDirectional == 1.
if Options.biDirectional == 1
    tarU = samplesTarget;
    tarW = eye(nSamplesTarget);
end;

% Do rigid iterative closest point if Options.rigidInit == 1
if Options.rigidInit == 1
    disp('* Performing rigid ICP...');
    if Options.ignoreBoundary == 0
        bdr = 0;
    end
    [R, t] = icp(vertsTarget', vertsSource', 50, 'Verbose', true, ...
                 'EdgeRejection', logical(Options.ignoreBoundary), ...
                 'Boundary', bdr');
    X = repmat([R'; t'], nVertsSource, 1);
    vertsTransformed = D*X;
    
    % Update plot
    if Options.plot == 1
        set(h, 'Vertices', vertsTransformed);
        drawnow;
    end
else
    % Otherwise initialize transformation matrix X with identity matrices
%     X = repmat([eye(3); [0 0 0]], nVertsSource, 1);
    X = repmat(Options.initX', nVertsSource, 1);
end

% get number of element in the set of stiffness parameters Options.alphaSet
nAlpha = numel(Options.alphaSet);

% Enter outer loop of the non-rigid iterative closest point algorithm. The
% outer loop iterates over stiffness parameters alpha.
disp('* Performing non-rigid ICP...');
nricpTime = tic;
for i = 1:nAlpha
    % Update stiffness
    alpha = Options.alphaSet(i);
    
    % Enter inner loop. For each stiffness setting alternate between 
    % updating correspondences and getting optimal transformations X. 
    % Break the loop when consecutive transformations are similar.
    while true
        % Transform source points by current transformation matrix X
        vertsTransformed = D*X;
        
        % Update plot 
        if Options.plot == 1
            set(h, 'Vertices', full(vertsTransformed));
            drawnow;
        end

        % Determine closest points on target U to transformed source points
        % pointsTransformed.
        tic;    % knnTime
        targetId = knnsearch(vertsTarget, vertsTransformed);
        knnTime = toc;
        U = vertsTarget(targetId,:);
        

        % Optionally give zero weightings to transformations associated
        % with boundary target vertices.
        if Options.ignoreBoundary == 1
            tarBoundary = ismember(targetId, bdr);
            wVec = wVec .* ~tarBoundary;
        end
        
        % Optionally transform surface normals to compare with target and
        % give zero weight if surface and transformed normals do not have
        % similar angles.
        if Options.normalWeighting == 1
            normalsTransformed = N*X;
            corNormalsTarget = normalsTarget(targetId,:);
            crossNormals = cross(corNormalsTarget, normalsTransformed);
            crossNormalsNorm = sqrt(sum(crossNormals.^2,2));
            dotNormals = dot(corNormalsTarget, normalsTransformed, 2);
            angle = atan2(crossNormalsNorm, dotNormals);
            wVec = wVec .* (angle < Options.normalDiffThreshold);
        end
            
        % Update weight matrix
        W = spdiags(wVec, 0, nVertsSource, nVertsSource);
        
        % Get closest points on source tarD to target samples samplesTarget
        if Options.biDirectional == 1
            transformedId = knnsearch(vertsTransformed, samplesTarget);
            tarD = sparse(nSamplesTarget, 4 * nVertsSource);
            for j = 1:nSamplesTarget
                cor = transformedId(j);
                tarD(j,(4 * cor-3):(4 * cor)) = [vertsSource(cor,:) 1];
            end
        end

        % Specify B and C (See equation (12) from paper)
        A = [...
            alpha .* kron_M_G; 
            W * D;
            ];
        B = [...
            zeros(size(M,1)*size(G,1), 3);
            W * U;
            ];
        
        % Concatentate additional terms if Options.useMarker == 1.
        if Options.useMarker == 1
            A = [...
                A;
                Options.beta .* DL
                ];
            B = [...
                B;
                Options.beta .* UL
                ];
        end
        
        % Concatentate additional terms if Options.biDirectional == 1.
        if Options.biDirectional == 1
            A = [...
                A;
                Options.lambda .* tarW * tarD
                ];
            B = [...
                B;
                Options.lambda .* tarW * tarU
                ];
        end

        % Get optimal transformation X and remember old transformation oldX
        oldX = X;
        
        tic;
        %spparms('spumoni',0);
        %spparms('spumoni',2);        % debug
        if Options.GPU
            % GPU
            gd = gpuDevice;
            X = zeros(size(A,2), size(B,2));
            AtA = gpuArray(A' * A);
            for j = 1:size(B,2)
                AtBj = gpuArray(A' * B(:,j));
                Xj = pcg(AtA, AtBj, 1e-12, 1000);
                X(:,j) = gather(Xj);
            end
            wait(gd);
        else
        	% CPU
            % Time consume:
            %   cholmod < spQR (4-5x)
            %   matlab-suitesparse ~= suitesparse-matlab
            
            X = (A' * A) \ (A' * B);    % matlab-cholmod
%             X = A \ B;      % matlab-suitesparseQR 
%             [X, stats] = cholmod2(A' * A, A' * B);  % suitesparse-cholmod
%             [X, info] = spqr_solve(A, B);  % suitesparse-spQR

        end
        lsolverTime = toc;
        
        deltaX = norm(X - oldX);
        
        % print verbose information
        if Options.verbose == 1
            fprintf('alpha = %.2f, dX = %f, knnTime = %fs, lsolverTime = %fs\n', ...
                alpha, deltaX, knnTime, lsolverTime);
        end
        
        if deltaX <= Options.epsilon(i)
            break;
        end
    end
end
nricpTime = toc(nricpTime);
if Options.verbose == 1
    fprintf('\nNon-rigid ICP Time: %fs\n', nricpTime);
end


% Compute transformed points 
vertsTransformed = D*X;

if Options.snapTarget == 1
    % If Options.useNormals == 1 project along surface normals to target
    % surface, otherwise snap to closest points on target.
    if Options.useNormals == 1
        disp('* Projecting transformed points onto target along surface normals...');
        
        % Get template surface normals
        normalsTemplate = Source.normals;
        
        % Transform surface normals with the X matrix
        N = sparse(nVertsSource, 4 * nVertsSource);
        for i = 1:nVertsSource
            N(i,(4 * i-3):(4 * i)) = [normalsTemplate(i,:) 1];
        end
        normalsTransformed = N*X;
        
        % Project normals to target surface
        vertsTransformed = projectNormals(vertsTransformed, Target, ...
            normalsTransformed);
    else
        % Snap template points to nearest vertices on surface
        targetId = knnsearch(vertsTarget, vertsTransformed);
        corTargets = vertsTarget(targetId,:);
        if Options.ignoreBoundary == 1
            tarBoundary = ismember(targetId, bdr);
            wVec = ~tarBoundary;
        end
        vertsTransformed(wVec,:) = corTargets(wVec,:);
    end
end

% Update plot and remove target mesh
if Options.plot == 1
    set(h, 'Vertices', vertsTransformed);
    drawnow;
    pause(2);
%     delete(p);
end
end
