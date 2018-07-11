function [ spinesnew, spineSegments, numSegments ] = fitSpines( spines, spect, minSNR )
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here

    minvalue = min(spect(:));
    spect = spect - minvalue;
    
    spines = groupBranchpoints(spines);
    [spineSegments, numSegments, bpoints] = identifySegments(spines);
    % process each spine.
    spinesnew = zeros(size(spines));
    for i = 1:numSegments
        % create mask of current spine
        spineMask = spineSegments == i;
        bpointsLocal = imdilate(spineMask, ones(3)) == 1 & bpoints == 1;
        spineMask(bpointsLocal) = 1;
        [spineMask, len, angle] = processSpine(spineMask, spect, minSNR);

        if abs(angle) > 5 && abs(angle) < 80 && len > 1
            spinesnew = spinesnew + spineMask;
        else
            spineSegments(spineSegments == i) = 0;
        end
    end
    spinesnew(spinesnew > 0) = 1;
end

