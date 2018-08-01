function [spineSegments, numSegments, bpoints] = identifySegments(spines)

    % remove spurs of size one next to a branch point
    spurs = bwmorph(spines, 'spur');
    spurs = spines & ~spurs;
    bpoints = bwmorph(spines, 'branchpoints');
    [fs, ts] = find(spurs == 1);
    [fb, tb] = find(bpoints == 1);

    for i = 1:numel(fs)
        distb = sqrt( (fs(i) - fb) .^ 2 + (ts(i) - tb) .^ 2);
        n = find(distb == 1);
        if numel(n) == 1
            spines(fs(i), ts(i)) = 0;
        end
    end

    % recalculate branch points
    bpoints = bwmorph(spines, 'branchpoints');
    apoints = imdilate(bpoints, ones(3)) - bpoints;
    apoints(apoints == 1 & spines == 0) = 0;
    segments = spines & ~bpoints;
    segments = segments & ~apoints;
    [spineSegments, ~] = bwlabel(segments);
    
    for i = 1:numel(fb)
        label = spineSegments(fb(i), tb(i));
        spine = spineSegments == label;
        spineSegments(spine) = 0;
    end
    
    [spineSegments, numSegments] = bwlabel(spineSegments);
    segments(spineSegments > 0) = 0;
    
    
    [f, t] = find(apoints == 1);
    for i = 1:numel(f)
        segments(f(i), t(i)) = 1;
        [spineLabels, ~] = bwlabel(segments);
        label = spineLabels(f(i), t(i));
        spine = find(spineLabels == label);

        if sum(sum(spineSegments(spine))) == 0
            numSegments = numSegments + 1;
            spineSegments(spine) = numSegments;
        else
            label = unique(spineSegments(spine));
            label = min(label(label > 0));
%            label = max(label, min(label2(label2 > 0)))
           spineSegments(spine) = label;
        end

        segments(f(i), t(i)) = 0;
    end     
end