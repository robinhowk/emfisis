function [filteredRidges, bwFilteredRidges] = filterRadonAngles(ridges)
  rf = 5;
  rt = 10;
  [numRows, numCols] = size(ridges);
  bwFilteredRidges = zeros(numRows, numCols);
  minValue = min(ridges(:));
  ridges = ridges - minValue;
  for row = 1:numRows
    for col = 1:numCols
      bottom = max((row - rf),1);
      top = min((row + rf),numRows);
      left = max((col - rt),1);
      right = min((col + rt), numCols);
      subimage = ridges(bottom:top, left:right);
      radSubimage = radon(subimage);
      [~, radAngle] = max(max(radSubimage));
      
      if (radAngle > 10 && radAngle < 85) || (radAngle > 100 && radAngle < 185)
        bwFilteredRidges(row, col) = 1;
      end      
    end
  end
  
  filteredRidges = bwFilteredRidges .* ridges;
  bwFilteredRidges = filteredRidges;
  bwFilteredRidges(bwFilteredRidges ~= 0) = 1;
  filteredRidges = filteredRidges + minValue;
    
%   figure;subplot(3,1,1);pcolor(ridges);shading flat;colormap jet;
%   i2=subplot(3,1,2);pcolor(bwFilteredRidges);shading flat;colormap(i2, gray);
%   subplot(3,1,3);pcolor(filteredRidges);shading flat;colormap jet;
%   pause;close;
end