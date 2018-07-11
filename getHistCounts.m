function [ counts ] = getHistCounts( chorusElements, edges )
    chorusAngles = [chorusElements.chorusAngle];
    sweeprates = [chorusElements.sweeprate];
    
    angleCounts = histcounts(chorusAngles, edges.chorusAngles);
    sweeprateCounts = histcounts(sweeprates / 1000, edges.sweeprates);

    counts = struct('chorusAngles', angleCounts, 'sweeprates', sweeprateCounts);
end

