function [ polySrc, polyTgt ] = PlotSrcTgt( Source, Target )
%UNTITLED4 此处显示有关此函数的摘要
%   此处显示详细说明
    clf;
    PlotTarget.vertices = Target.vertices;
    PlotTarget.faces = Target.faces;
    polyTgt = patch(PlotTarget, 'facecolor', 'b', 'EdgeColor',  'none', ...
              'FaceAlpha', 0.0);
    hold on;
    
    PlotSource.vertices = Source.vertices;
    PlotSource.faces = Source.faces;
    polySrc = patch(PlotSource, 'facecolor', 'r', 'EdgeColor',  'none', ...
        'FaceAlpha', 0.5);
    material dull; light; grid on; xlabel('x'); ylabel('y'); zlabel('z');
    view([60,30]); axis equal; axis manual;
    legend('Target', 'Source', 'Location', 'best')
    drawnow;

end

