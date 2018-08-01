function [ detectedElements, chorusPixel, freqVec, psdVec ] = ...
    traceChorus( colIndex, detectedElements, imagefile, spine, fspec, tspec, mu )
%TRACECHORUS 
% colIndex tracks the column index from the original burst
% trace index tracks the column index for the chorus pixel

    % initalize trace variables with 100 points
    [nRows, nCols] = size(detectedElements);
    traceSpread = 15;
    traceIndex = 1;
    prevSum = 1;
    chorusPixel = zeros(nRows, 100);
    freqVec = zeros(1, 100);
    psdVec = zeros(1, 100);
    
    % find frequency where element starts
    fIndex = find(detectedElements(:, colIndex) == 1);
    if numel(fIndex) == 1
        detectedElements(fIndex, colIndex) = 0;
    else
        % each index is assigned a weighted value equal to the sum
        % of surrounding pixels
        fWeighted = zeros(numel(fIndex), 1);
        for i = 1:numel(fIndex)
            fWeighted(i) = sum(sum(spine(fIndex(i)-2:fIndex(i)+2, colIndex-1:colIndex+1)));
        end
        % chose index with highest sum
        [~, maxInd] = max(fWeighted);
        fIndex = fIndex(maxInd);
        % mark nearby pixels in column as visited
        detectedElements(max(fIndex - 5, 1):min(fIndex + 5, nRows), colIndex) = 0;
    end

    % update chorus pixel
    chorusPixel(fIndex, traceIndex) = 1;
    % update current point
    fCur = fspec(fIndex);
    tCur = tspec(colIndex);
    % update previous values
    tPrev = tCur;
    fPrev = fCur;
    tPrevIndex = colIndex;
    fPrevIndex = fIndex;

    % update coordinates
    freqVec(traceIndex) = fCur;
    psdVec(traceIndex) = imagefile(fIndex, colIndex);
    
    % get column sum of subimage
    [subimageDim] = subimageColSum(traceSpread, detectedElements, fIndex, colIndex);
    
    % increment column index
    colIndex = colIndex + 1;
    
    % calculate sum of next column in subimage
    colSum = sum(detectedElements(subimageDim.bottom:subimageDim.top, colIndex));
    
    while (colSum > 0 || prevSum > 0) && colIndex <= nCols
        %  update current time
        tCur = tspec(colIndex);
        % find current frequency
        % find points in given col
        fIndex = find(detectedElements(:,colIndex) == 1);
        % trim points to limits of subimage
        fIndex(fIndex >= subimageDim.bottom & fIndex <= subimageDim.top);
        if numel(fIndex) == 1
            if (abs(fPrevIndex - fIndex) <= 6)
                % fIndex only has one value, save this value
                detectedElements(fIndex, colIndex) = 0;
            else
                fIndex = [];
            end
        else
            % find weighted index for each group of consecutive indices
            fWeightedIndex = zeros(1, 5);
            startIndex = 1;
            nGroup = 1;

            for i = 1:numel(fIndex)
               % part of same element if group ends less than 6 pixels below 
               % or start less than 6 pixels above the previous index
               groupEnd = 0;

                if i == numel(fIndex)
                   % last point found
                   stopIndex = i;
                   groupEnd = 1;
                elseif (fIndex(i + 1) - fIndex(i)) > 1
                   % end of continuous frequencies reached
                   stopIndex = i;
                   groupEnd = 1;
                end
               
                if groupEnd
                    % check if part of main element
                    if abs(fPrevIndex - fIndex(stopIndex)) <= 6 || (abs(fIndex(startIndex) - fPrevIndex) <= 6)
                        % clear group from col
                        detectedElements(fIndex(startIndex:stopIndex), colIndex) = 0;
                        % weigthed frequency index and value for current group
                        psdNorm = max(spine(fIndex(startIndex:stopIndex), colIndex)) ./ spine(fIndex(startIndex:stopIndex), colIndex);
                        fWeightedIndex(nGroup) = round(sum(fIndex(startIndex:stopIndex) .* psdNorm) / sum(psdNorm));
                        nGroup = nGroup + 1;
                        % update counter for next group
                        startIndex = i + 1;
                    else
                        startIndex = i + 1;
                    end
                end
            end
            fWeightedIndex = fWeightedIndex(fWeightedIndex > 0);
            fWeighted = fspec(fWeightedIndex);

            % pick group that best matches the dominant angle in a subimage of
            % the spine
            subimageSpine = spine(subimageDim.bottom:subimageDim.top, subimageDim.left:subimageDim.right);
            radSubimage = radon(subimageSpine);
            [~, maxInd] = max(max(radSubimage));
            subimageSweeprate = mu * tand(90 - maxInd);
            % determine sweeprates for each group
            windowSweeprates = (fWeighted - fPrev) / (tCur - tPrev);
            sweepratesDiff = abs(windowSweeprates - subimageSweeprate);
            [~, minInd] = min(sweepratesDiff);
            fIndex = fWeightedIndex(minInd);

            % check surrounding pixels in detected elements to make sure no
            % artifacts remain
            if sum(sum(detectedElements(fIndex-2:fIndex+2, colIndex-1:colIndex+1))) > 0
                detectedElements(fIndex-2:fIndex+2, colIndex-1) = 0;
            end
        end
        fCur = fspec(fIndex);
        
        if numel(fCur) > 0
            if prevSum == 0
                traceIndex = traceIndex + 2;
            else
                traceIndex = traceIndex + 1;
            end
            
            % add to chorus pixel
            chorusPixel(fIndex, traceIndex) = 1;
            % update coordinates
            % update coordinates
            freqVec(traceIndex) = fCur;
            psdVec(traceIndex) = imagefile(fIndex, colIndex);
            
            % update previous values
            tPrev = tCur;
            fPrev = fCur;
            tPrevIndex = colIndex;
            fPrevIndex = fIndex;
            prevSum = colSum;
            
            % update subimage data
            subimageDim = subimageColSum(traceSpread, detectedElements, fIndex, colIndex);

            % increment counters
            colIndex = colIndex + 1;
            colSum = sum(detectedElements(subimageDim.bottom:subimageDim.top, colIndex));
            
        else
            % if previous column is empty, terminate trace by forcing
            % element sum to 0
            if prevSum == 0
                colSum = 0;
            else
                % no point selected to set prev sum to zero, reflecting
                % empty column
                prevSum = 0;
                colIndex = colIndex + 1;
                colSum = sum(detectedElements(subimageDim.bottom:subimageDim.top, colIndex));
            end
        end
    end
    
    chorusPixel = chorusPixel(:,1:traceIndex);
    freqVec = freqVec(1:traceIndex);
    psdVec = psdVec(1:traceIndex);
end

function subimageDim = subimageColSum(radius, detectedElements, fIndex, tIndex)
    winTop = min((fIndex + radius), size(detectedElements, 1));
    winBottom = max((fIndex - radius), 1);
    winLeft = max((tIndex - radius), 1);
    winRight = min((tIndex + radius), size(detectedElements, 2));
    subimageDim = struct('top', winTop, 'bottom', winBottom', 'left', winLeft', 'right', winRight);
end
