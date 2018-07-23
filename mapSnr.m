function [ snrMap ] = mapSnr( spect, fullSpect, snrThreshold, method )
%Finds the SNR for each pixel based on an extracted noise sample
%   Detailed explanation goes here

    [numRows, numCols] = size(spect);

    spect0 = spect - min(spect(:));
    span = 25;
    if method == 1
        % find stretch of 25 columns with minimum std deviation
        minStd = Inf;
        minInd = 0;
        for i = 1:numCols - span
            stdWindow = std2(spect(:, i:i+span));
            if stdWindow < minStd
               minStd = stdWindow;
               minInd = i;
            end
        end
        left = minInd;
        right = minInd + span;
        stdNoise = minStd;
    else
        stdNoise = std2(fullSpect(200:300, :));
    end
    
    % calculate SNR for entire burst
    snrMap = 10*log10(spect0 / stdNoise);

    % threshold SNR
%     snrThreshold = max(floor(max((snrMap(:)))) - 2, 8);
    spectThreshold = spect;
    spectThreshold(snrMap < snrThreshold) = NaN;

    % set negative snr values to NaN
    snrMap(snrMap < 0) = NaN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    figure;
    set(gcf, 'Position', get(0, 'Screensize'));
    % plot spectrogram
    i1 = subplot(3,1,1);
    imagesc(spect);
    set(i1, 'ydir', 'normal', 'fontsize', 15);
    colormap jet;
    title('(a) Original Spectrogram');
    colorbar;
    caxis([-158 -30]);

    if method == 1
        % plot extents of noise sample
        hold on;
        line([left left], [1 numRows], 'color', 'black');
        line([right right], [1 numRows], 'color', 'black');
        hold off;
    end
    
%     % plot columnwise std deviation of spect
%     i2 = subplot(2,2,3);
%     colMean = abs(mean(spect));
%     colStd = std(spect);
%     rcol = colMean ./ colStd;
%     rcol = rcol ./ max(rcol);
%     plot(rcol);
%     axis tight;
%     set(i2, 'fontsize', 15);
%     title('(b) Feature Location Approximation');
%     
%     if method == 1
%         % plot extents of noise sample
%         hold on;
%         line([left left], [0 1], 'color', 'black');
%         line([right right], [0 1], 'color', 'black');
%         hold off;
%     end
    
    % plot SNR Map
    i3 = subplot(3,1,2);
    pcolor(snrMap);
    set(i3, 'ydir', 'normal', 'fontsize', 15);
    colormap jet;
    shading flat;
    title('(b) SNR Map');
    colorbar;
    
    % plot SNR above threshold
    i4 = subplot(3,1,3);
    pcolor(spectThreshold);
    set(i4, 'ydir', 'normal', 'fontsize', 15);
    colormap jet;
    shading flat;
    title(sprintf('(c) Features With SNR > %d', snrThreshold));
    colorbar;
    caxis([-158 -30]);
end

