function [ chorusElements, tracedElements, chorusCount ] = traceBurst( detectedElements, spine, imagefile, fspec, tspec, mu, ridges, errorLog, filename)
%TRACECHORUS Summary of this function goes here
%   Detailed explanation goes here

    % initialize variables
    [nRows, nCols] = size(detectedElements);
    chorusCount = 0;
    tracedElements = zeros(size(detectedElements));
    chorusElements = struct();
    endpoints = zeros(20, 4);
    ridgesZero = ridges - min(ridges(:));

    for iCol = 1:nCols
        colSum = sum(detectedElements(:, iCol));
        % when colSum is greater than 0, the begining of an element has
        % been found
        while colSum > 0
            [ detectedElements, chorusPixel, freqVec, psdVec ] = traceChorus( iCol, detectedElements, imagefile, spine, fspec, tspec, mu );
            
            [freqIndex, timeIndex] = find(chorusPixel > 0);
            timeIndexShifted = timeIndex + iCol - 1;
            time = tspec(timeIndexShifted);
            freq = fspec(freqIndex)';
            
            deltaF = abs(freq(end) - freq(1));
            deltaFMax = max(freq) - min(freq);
            
            if deltaF > 171 && (deltaF / deltaFMax) > 0.7 && deltaFMax > 240
                [sweeprate, chorusAngle, p1, p2, p3, p4, r2, knot1, knot2, knot3, segments, lenSegments] = piecewise_regression(time, freq, mu);
                % shift knots to correct index
                if segments == 2
                    knot1 = timeIndex(knot1);
                elseif segments == 3
                    knot1 = timeIndex(knot1);
                    knot2 = timeIndex(knot2);
                elseif segments == 4
                    knot1 = timeIndex(knot1);
                    knot2 = timeIndex(knot2);
                    knot3 = timeIndex(knot3);
                end

                totalLen = sum(lenSegments);
                
                % find psd sum - sums all the selected pixels and
                % the surrounding pixels above and below, from the original
                % image
                psdSum = 0;
                psdSumLog = 0;
                psdSumPixel = 0;
                for i = 1:length(time)
                   psdSum = psdSum + sum(imagefile(freqIndex(i)-2:freqIndex(i)+2, timeIndexShifted(i)));
                   psdSumLog = psdSumLog + sum(ridgesZero(freqIndex(i)-2:freqIndex(i)+2, timeIndexShifted(i)));
                   psdSumPixel = psdSumPixel + ridgesZero(freqIndex(i), timeIndexShifted(i));
                end
                avgPsdLog = psdSumLog / length(time);
                avgPsdPixel = psdSumPixel / length(time);
                
                if abs(chorusAngle) > 20 && abs(chorusAngle) < 80 && ~isnan(r2) && r2 > 0.96 && totalLen > 240 && avgPsdPixel > 19 && avgPsdLog > 49 %&& totalLen < (1.75 * deltaFMax)
                    
                    subimageRidges = ridgesZero(min(freqIndex):max(freqIndex), timeIndexShifted);
                    subimageSpine = spine(min(freqIndex):max(freqIndex), timeIndexShifted);
                    radRidges = radon(subimageRidges);
                    radSpine = radon(subimageSpine);
                    [~, maxRadRidges] = max(max(radRidges));
                    [~, maxRadSpine] = max(max(radSpine));
                    sliceRidges = radRidges(:, maxRadRidges);
                    [maxSliceRidgesVal, maxSliceRidgesInd] = max(sliceRidges);
                    rmsSliceRidges = rms(sliceRidges(max(maxSliceRidgesInd-5, 1):min(maxSliceRidgesInd+5, numel(sliceRidges))) / maxSliceRidgesVal);
                    thetaRidges = 90 - maxRadRidges;
                    thetaSpine = 90 - maxRadSpine;
                    
                    if abs(chorusAngle - thetaRidges) < 30 && abs(chorusAngle - thetaSpine) < 20  %&& rmsSliceRidges < 0.5
                       
                        % increment number of elemens found
                        chorusCount = chorusCount + 1;
                        
                        % if negative sweeprate, add to error log
%                         if chorusAngle < 0
%                             fprintf(errorLog, 'negative angle\t%s\t%d\t%.02f\t%.02f\t%d\r\n', filename, chorusCount, sweeprate, chorusAngle, timeIndexShifted(1));
%                         end

                        % update endpoints
                        endpoints(chorusCount, :) = [timeIndexShifted(1), freqIndex(1), timeIndexShifted(end), freqIndex(end)];
                        
                        % calculate psd sum from original spectrogram using
                        % lines from piecewise fit
                        psdLine = 0;
                        
                        if segments == 1
                            f1 = polyval(p1, tspec(timeIndexShifted));
                            length(f1)
                            length(timeIndexShifted)
                            for i = 1:length(f1)
                               ind = find(fspec > f1(i),1);
                               if abs(fspec(ind) - f1(i)) < abs(fspec(ind-1) - f1(i))
                                   psdLine = psdLine + imagefile(ind, timeIndexShifted(1) + i - 1);
                               else
                                   psdLine = psdLine + imagefile(max(1, ind-1), timeIndexShifted(1) + i - 1);
                               end
                            end
                        elseif segments == 2
                            f1 = polyval(p1, tspec(timeIndexShifted(1):knot1 + timeIndexShifted(1) - 1));
                            f2 = polyval(p2, tspec(knot1 + timeIndexShifted(1) - 1:knot2 + timeIndexShifted(end)));
                            for i = 1:length(f1)
                                ind = find(fspec > f1(i),1);
                                if abs(fspec(ind) - f1(i)) < abs(fspec(ind-1) - f1(i))
                                    psdLine = psdLine + imagefile(ind, timeIndexShifted(1) + i - 1);
                                else
                                    psdLine = psdLine + imagefile(ind-1, timeIndexShifted(1) + i - 1);
                                end
                            end
                            
                            for i = 2:length(f2)
                                ind = find(fspec > f2(i),1);
                                if abs(fspec(ind) - f2(i)) < abs(fspec(ind-1) - f2(i))
                                    psdLine = psdLine + imagefile(ind, knot1 + timeIndexShifted(1) - 1 + i);
                                else
                                    psdLine = psdLine + imagefile(ind-1, knot1 + timeIndexShifted(1) - 1 + i);
                                end
                            end
                        elseif segments == 3
                            f1 = polyval(p1, tspec(timeIndexShifted(1):knot1 + timeIndexShifted(1) - 1));
                            f2 = polyval(p2, tspec(knot1 + timeIndexShifted(1) - 1:knot2 + timeIndexShifted(1) - 1));
                            f3 = polyval(p3, tspec(knot2 + timeIndexShifted(1) - 1:timeIndexShifted(end)));
                            
                            for i = 1:length(f1)
                                ind = find(fspec > f1(i),1);
                                if abs(fspec(ind) - f1(i)) < abs(fspec(ind-1) - f1(i))
                                    psdLine = psdLine + imagefile(ind, timeIndexShifted(1) + i - 1);
                                else
                                    psdLine = psdLine + imagefile(ind-1, timeIndexShifted(1) + i - 1);
                                end
                            end
                            
                            for i = 2:length(f2)
                                ind = find(fspec > f2(i),1);
                                if abs(fspec(ind) - f2(i)) < abs(fspec(ind-1) - f2(i))
                                    psdLine = psdLine + imagefile(ind, knot1 + timeIndexShifted(1) - 1 + i);
                                else
                                    psdLine = psdLine + imagefile(ind-1, knot1 + timeIndexShifted(1) - 1 + i);
                                end
                            end
                            
                            for i = 2:length(f3)
                                ind = find(fspec > f3(i),1);
                                if abs(fspec(ind) - f3(i)) < abs(fspec(ind-1) - f3(i))
                                    psdLine = psdLine + imagefile(ind, knot2 + timeIndexShifted(1) - 1 + i);
                                else
                                    psdLine = psdLine + imagefile(ind-1, knot2 + timeIndexShifted(1) - 1 + i);
                                end
                            end
                        end
                        
                        % update struct of chorus elemnts
                         % create struct and add to array of elements
                        chorusElements(chorusCount).start = struct('time', timeIndexShifted(1), 'freq', freqIndex(1), 'branch_point', 0);
                        chorusElements(chorusCount).stop = struct('time', timeIndexShifted(end), 'freq', freqIndex(end), 'branch_point', 0);
                        chorusElements(chorusCount).chorusPixel = chorusPixel;
                        chorusElements(chorusCount).sweeprate = sweeprate;
                        chorusElements(chorusCount).chorusAngle = chorusAngle;
                        chorusElements(chorusCount).piecewiseResults = struct('p1', p1, 'p2', p2, 'p3', p3, 'p4', p4, ...
                                                                                    'r2', r2, ...
                                                                                    'knot1', knot1 + timeIndexShifted(1) - 1, ...
                                                                                    'knot2', knot2 + timeIndexShifted(1) - 1, ...
                                                                                    'knot3', knot3 + timeIndexShifted(1) - 1, ...
                                                                                    'segments', segments, ...
                                                                                    'lenSegments', lenSegments);
                        chorusElements(chorusCount).psdSum = psdSum;
                        chorusElements(chorusCount).freq = freqVec;
                        chorusElements(chorusCount).psd = psdVec;
                        chorusElements(chorusCount).psdSumLine = psdLine;
                        % add element to traced elements, value stored is
                        % chorus element number
                        tempChorusPixel = chorusPixel;
                        tempChorusPixel(chorusPixel == 1) = chorusCount;
                        tracedElements(:, timeIndexShifted(1):timeIndexShifted(end)) = tracedElements(:, timeIndexShifted(1):timeIndexShifted(end)) + tempChorusPixel;                    
                    end
                end
            end % element saved
            colSum = sum(detectedElements(:, iCol));
        end
    end

% endpoints = endpoints(1:chorusCount, :);
% % set values in traced elements to 1
% tracedElementsBw = tracedElements;
% tracedElementsBw(tracedElements > 0) = 1;
% density = sum(tracedElementsBw);
% highDensity = find(density >= 3);
% % stores column index for high density areas that have a branch point
% doubleCount = [];
% 
% % check endpoints
% for i = 1:size(endpoints, 1)
%    % check start coordinate
%    tEndpoints = endpoints(i,1);
%    fEndpoints = endpoints(i,2);
%    left = max(tEndpoints - 4, 1);
%    right = min(tEndpoints + 4, nCols);
%    bottom = max(fEndpoints - 4, 1);
%    top = min(fEndpoints + 4, nRows);
%    if ~isnan(find(tracedElements(bottom:top, left:right) > 0 & tracedElements(bottom:top, left:right) ~= i))
%        chorusElements(i).start.branch_point = 1;
%        if any(highDensity == tEndpoints)
%            doubleCount = [doubleCount, tEndpoints];
%        end
%    end
%    
%    % check end coordinate
%    tEndpoints = endpoints(i,3);
%    fEndpoints = endpoints(i,4);
%    left = max(tEndpoints - 4, 1);
%    right = min(tEndpoints + 4, nCols);
%    bottom = max(fEndpoints - 4, 1);
%    top = min(fEndpoints + 4, nRows);
%    if ~isnan(find(tracedElements(bottom:top, left:right) > 0 & tracedElements(bottom:top, left:right) ~= i))
%        chorusElements(i).stop.branch_point = 1;
% %        fprintf('Branch point, stop %d\n', i);
%        if any(highDensity == tEndpoints)
%            doubleCount = [doubleCount, tEndpoints, i];
%        end
%    end
% end
% 
% clearedElements = [];
% for i = 1:size(doubleCount,1)
%     % if element has not been cleared
%     if ~any(clearedElements == doubleCount(i))
%         % find other elements in the region
%         id = tracedElements(:, doubleCount(i)) > 0;
%         id = tracedElements(id, doubleCount(i));
%         % find element with max 
%         elementSums = zeros(1, length(id));
%         for j = 1:length(id)
%             elementSums(j) = chorusElements(id(j)).psdSum;
%         end
%         [~, max_ind] = max(elementSums);
%         % only keep max entry
%         id(max_ind) = [];
%         for j = 1:length(id)
%             tracedElementsBw(tracedElements == id(j)) = 0;
%             tracedElements(tracedElements(:) == id(j)) = 0;
%         end
%         chorusElements(id) = [];
%         clearedElements = [clearedElements; id];
%     end
% end
% 
% chorusCount = chorusCount - numel(clearedElements);
% 
% if ~isempty(find(density >= 3, 1))
%     fprintf(errorLog, filename, 'high density\r\n');
% end

tracedElements(tracedElements > 0) = 1;
end