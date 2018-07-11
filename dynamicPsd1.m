function [ localDeltaPsd ] = dynamicPsd1( subimage, thetavec )
%UNTITLED2 Summary of this function goes here
%   Dynamic psd sliding shift by 1 pixels, psd averaged for each pixel
    snr = 10;
    radsubimage = radon(subimage,thetavec);
    [signalPsd, ind] = max(max(radsubimage));
    totpsd = sum(sum(subimage));
    numPixels = numel(subimage);
    
    [ylen, xlen] = size(subimage);
    if ylen > 0 && xlen > 0
        fmid = (ylen -1)/2 + 1;
        tmid = (xlen -1)/2 + 1;
        m = tand(90 - ind);
        b = fmid - (tmid * m);
        x = 1:xlen;
        y = m*x + b;
        inds = find(y >= 1 & y < ylen + .5);
        if (abs(b) > (ylen / 2) || isempty(inds))
            signalPixels = numel(improfile(subimage, [1 1], [ylen xlen]));
        else
            t1 = x(inds(1));
            t2 = x(inds(end));
            f1 = y(inds(1));
            f2 = y(inds(end));
            spacing = 0.25;
            numSamples = sqrt((t2-t1)^2 + (f2-f1)^2)/spacing;
            t = linspace(t1,t2,numSamples);
            f = linspace(f1,f2,numSamples);
            tf = unique(round([t' f']), 'rows');
            t = tf(:,1);
            f = tf(:,2);
            signalPixels = numel(t);
                
    
        end

        localDeltaPsd = ((totpsd - signalPsd) / (numPixels - signalPixels)) + snr;        
    end

end