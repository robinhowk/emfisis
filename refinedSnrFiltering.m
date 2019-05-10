function [refinedSnrMap, refinedFeatures, bwRidges] = refinedSnrFiltering(ridges, bwRidges, r)
  [labels, numLabels] = bwlabel(bwRidges);
  refinedSnrMap = nan(size(ridges));
  [numrows, numcols] = size(ridges);
  
  for i = 1:numLabels
    cc = labels == i;
    curRidges = cc .* ridges;
    [f, t] = find(cc == 1);
    if max(t) - min(t) > 35
      bwRidges = bwRidges - cc;
      for row = min(f):max(f)
        for col = min(t):max(t)
          curval = curRidges(row, col);
          if curval ~= 0
            bottom = max((row - r),1);
            top = min((row + r),numrows);
            left = max((col - r),1);
            right = min((col + r), numcols);
            subimage = ridges(bottom:top, left:right);

            ind = find(subimage(:) == curval, 1, 'first');
            noiseImage = subimage;
            noiseImage(ind) = nan;
            noise = nanmedian(noiseImage(:));
            snr = max(curval - noise, 0);
            refinedSnrMap(row, col) = snr;
          end
        end
      end
    end
  end
  
  refinedSnrMap(refinedSnrMap < 50) = nan;
  bwRidges(~isnan(refinedSnrMap)) = 1;
  refinedFeatures = bwRidges .* ridges;
  refinedFeatures(refinedFeatures == 0) = -100;
%   figure;subplot(3,1,1);pcolor(ridges);colormap jet;shading flat;colorbar;
%   subplot(3,1,2);pcolor(refinedSnrMap);colormap jet;shading flat;colorbar;
%   ax = gca;
%   c1 = ax.CLim;
%   refinedSnrMap(refinedSnrMap < 50) = nan;
%   subplot(3,1,3);pcolor(refinedSnrMap);colormap jet;shading flat;colorbar;caxis(c1);
%   pause;close;
end