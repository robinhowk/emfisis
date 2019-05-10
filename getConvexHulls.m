function [convexHulls] = getConvexHulls(peakLabels, numPeaks)
  convexHulls = zeros(2*numPeaks, 99);
  
  for i = 1:numPeaks
    peakMask = peakLabels == i;
    [f, t] = find(peakMask == 1);
    tf = [t';f']';
    % code to check if points are colinear sourced from 
    % https://www.mathworks.com/matlabcentral/answers/438506-can-we-check-points-are-in-straight-line
    pointsAreCollinear = @(tf) rank(tf(2:end,:) - tf(1,:)) == 1;
    % must have more than two points and the points cannot be colinear
    if numel(f) > 1 && ~(pointsAreCollinear(tf))
      k = convhull(t, f);
      convexHulls(2*i, 1:numel(k)) = f(k);
      convexHulls(2*i-1, 1:numel(k)) = t(k);
    end
  end
  
end