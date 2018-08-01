function [ spineMask, len, angle ] = processSpine( spineMask, spect, minSNR  )
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
    [numrows, numcols] = size(spineMask);
    spineInd = find(spineMask == 1);
    
    if numel(spineInd) <= 1
        spineMask(spineInd) = 0;
        len = 1;
        angle = 0;
        return
    end
    
    % fit line to spine
    [f, t] = find(spineMask == 1);
    if numel(f) <= 4
        ptemp = polyfit(t,f,1);
        p = zeros(1,4);
        p(3:4) = ptemp;
        fp = polyval(p, t);
        fpi = round(fp);
        inflectPt = [];
    else
        p = polyfit(t, f, 3);
        fp = polyval(p, t);
        fpi = round(fp);
        % find inflection points of best fit line
        syms x;
        px = p(1)*x^3 + p(2)*x^2 + p(3)*x + p(1);
        p1= diff(px);
        
        inflectPt = round(double(solve(p1, 'MaxDegree', 3)));
        inflectPt = inflectPt(imag(inflectPt) == 0 & inflectPt > t(1) & inflectPt < t(end));
    end
    
    % create mask from line of best fit
    signalMask = zeros(size(spineMask));
    for i = 1:numel(fpi)
        if fpi(i) > 0 && fpi(i) <= numrows && t(i) > 0 && t(i) <= numcols
            signalMask(fpi(i), t(i)) = 1; 
        end
    end
    
    % determine snr of spine based on best fit line (ideal spine)
    signal = signalMask .* spect;
    signalPsd = sum(signal(:));
    spinePsd = spineMask .* spect;
%     figure;i1=subplot(1,1,1);imagesc(spineMask);set(i1, 'ydir', 'normal');colormap autumn;hold on;
%             plot(t, f, 'b*');
%     plot(t, fp, 'black', 'linewidth', 1);
    spinePsd = sum(spinePsd(:));
    noisePsd = abs(spinePsd - signalPsd);
    snr = 10*log10(signalPsd / noisePsd);
%     gof = sum((f - fp) .^ 2) / numel(f);
 
    len = zeros(1, numel(inflectPt) + 1);
    angles = zeros(1, numel(inflectPt) + 1);
    
    % calculate f values along every t value. It is possible the original
    % spines skipped a column. This will fill in any gaps
    tnew = min(t):max(t);
    if min(tnew) == max(tnew) || numel(tnew) == 1
        len(i) = 1;
        angles(i) = 0;
    else
        f = polyval(p, tnew);
        % select values at endpoints and infection points
        t = [min(t), inflectPt', max(t)];
        % calculate length and angle of each segment
        for i = 1:numel(t) - 1
            t1 = t(i);
            t2 = t(i+1);
            f1 = f(t1 == tnew);
            f2 = f(t2 == tnew);
            len(i) = sqrt((t2 - t1)^2 + (f2 - f1)^ 2);
            angles(i) = atand((f2 - f1) / (t2 - t1));
        end
    end
    [~, maxInd] = max(len);
    len = sum(len);
    angle = angles(maxInd);
    
    if snr < minSNR %|| gof > 1.5
       spineMask(spineInd) = 0;
    end
end

