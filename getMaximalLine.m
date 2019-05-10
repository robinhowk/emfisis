function [chorusAngles, sweeprates, endpoints, maxLength, numPeaks, validChorus] = getMaximalLine(convexHulls, numPeaks, mu1)
  % endpoints are stored in a row for each peak as follows [t1 f1 t2 f2]
  endpoints = zeros(numPeaks, 4);
  chorusAngles = zeros(numPeaks, 1);
  sweeprates = zeros(numPeaks, 1);
  maxLength = zeros(numPeaks, 1);
  curPeak = 1;
  for i = 1:2:numPeaks*2
    t = convexHulls(i, :);
    t = t(t>0);
    f = convexHulls(i+1, :);
    f = f(f>0);
    if ~isempty(t)
      % get pairwise distance of all points defining the hull
      % see https://blogs.mathworks.com/steve/2017/09/29/feret-diameter-introduction/
      dt = t - t';
      df = f - f';
      dist = hypot(dt, df);
      [maxLength(curPeak), ind] = max(dist(:));
      [ind1, ind2] = ind2sub(size(dist), ind);
      curEndpoints = [t(ind1) f(ind1) t(ind2) f(ind2)];
      endpoints(curPeak, :) = curEndpoints;
      % get the slope of the line and multiply by mu to get sweeprate
      slope = (curEndpoints(4) - curEndpoints(2)) / (curEndpoints(3) - curEndpoints(1));
      sweeprates(curPeak) = mu1 * slope;
      chorusAngles(curPeak) = atand(slope);
      curPeak = curPeak + 1;
    end
  end
  
  validChorus = (maxLength > 10) & (abs(chorusAngles) > 15) & (abs(chorusAngles) < 85);
  endpoints = endpoints(validChorus, :);
  chorusAngles = chorusAngles(validChorus);
  sweeprates = sweeprates(validChorus);
  maxLength = maxLength(validChorus);
  numPeaks = numel(maxLength);
end