function [ dist, peaks, peakLabels, numPeaks ] = findDstPeaks( bwRidges, ridges )
%Calculates the distance transform of detected features. The peaks of the
%distance transform are then found.
  peaks = zeros(size(bwRidges));
  [ccLabels, numPeaks] = bwlabel(bwRidges);
  
  % calculate distance transform
  dist = bwdist(~bwRidges);
  dist(dist == 0) = NaN;
  
  % for each column find nonzero pixels. the first index of each non-zero group
  % is saved as the start index of a feature. the last index of a feature
  % is saved as the start index of the next feature - 1 or the last
  % non-zero index
  for i = 1:size(bwRidges,2)
    if nansum(dist(:,i)) > 0
      featureIndexes = find(~isnan(dist(:,i)));
      featureStartInds = [1, (find(diff(featureIndexes) > 5))' + 1];
      featureEndInds = [featureStartInds(2:end) - 1, numel(featureIndexes)];
      featureStartInds = featureIndexes(featureStartInds);
      featureEndInds = featureIndexes(featureEndInds);

      % find the max value for each group
      for j = 1:numel(featureStartInds)
        [maxValue, maxInd] = max(dist(featureStartInds(j):featureEndInds(j), i));
        % check if there is more than one point with the max value. if there
        % is, pick the point with a higher psd value.
        allMaxInds = find(dist(featureStartInds(j):featureEndInds(j), i) == maxValue);
        if numel(allMaxInds) > 1
          maxInds = featureStartInds(j) + allMaxInds - 1;
          [~, maxInd] = max(ridges(maxInds,i));
        end
        peaks(featureStartInds(j) + maxInd - 1, i) = 1;
      end
    end
  end
  
  peakLabels = peaks .* ccLabels;
end

