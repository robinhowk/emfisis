function [ spines, chorusCount, chorusElements ] = selectSpines( spines, numSpines, tspec, fspec, imagefile, spect, mu )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
% figure;i1 = subplot(1,1,1);imagesc(spines);set(i1, 'ydir', 'normal');colormap autumn;hold on;
    deltaT = tspec(1);
    deltaF = fspec(1);
%     minSlope = tand(10);
%     maxSlope = tand(80);
    chorusElements = struct();
    chorusCount = 0;
    spect = spect - min(spect(:));
%     [spineLabels, numSpines] = bwlabel(spines);
    for i = 1:numSpines
        [f, t] = find(spines == i);
        if numel(f) > 0
            p = polyfit(t, f, 1);
            fp = polyval(p, t);
            angle = atand(p(1));
            gof = sum((f - fp) .^ 2) / numel(f);
    %             plot(t, fp, 'k');
            [~, first] = min(t);
            [~, last] = max(t);
            tdiff = (t(first) - t(last)) * deltaT;
            fdiff = (fp(first) - fp(last)) * deltaF;
            l = sqrt(tdiff ^ 2 + fdiff ^ 2);
            psdSum = 0;
            for j = 1:numel(f)
                psdSum = psdSum + spect(f(j), t(j));
            end

            % whenever there are multiple frequency samples for the same time,
            % replace with single value - will be average eventually
            if length(t) ~= length(unique(t))
                [~, ind] = unique(t);
                t = t(ind);
                f = f(ind);
            end

            spineMask = spines == i;
    %         if any threshold is not met, remove spine
            if psdSum < 100 || ...
                    numel(t) <= 3 || ...
                    gof > 5 || ...
                    angle < 5 || ...
                    angle > 85
    %                     (numel(f) < 15 && gof > .2) || ...
    %                     (numel(f) >= 15 && numel(f) < 30 && gof > .4)
    %                     (numel(f) >= 50 && gof > 1.25)
                spines(spineMask) = 0;
            elseif numel(f) < 100
                % save spine info
                chorusCount = chorusCount + 1;
                chorusElements(chorusCount).time = t;
                chorusElements(chorusCount).freq = f;
                chorusElements(chorusCount).sweeprate = angle * mu;
                chorusElements(chorusCount).chorusAngle = angle;
                psdVec = zeros(size(f'));
                for j = 1:numel(f)
                    psdVec(j) = imagefile(f(j), t(j));
                end
                [psdSum, l, gof, atand(p(1)), numel(f)]
                chorusElements(chorusCount).psd = psdVec;
            end
        end
    end
    spines(spines > 0) = 1;
end

