function showBurstFigure( tspec, fspec, imagefile1, snrMap, ...
  ridges, snrThreshold, spine, tracedElements, chorusElements, ...
  chorusCount, edges, figname )

  summary = figure('visiblity', 'off');
  h1 = subplot(4,2,1);
  imagesc(tspec, fspec, imagefile1);
  colormap(h1, jet);
  c = colorbar;
  title(h1, '(1) Original Spectrogram');
  xlabel(h1, 'Duration of event in seconds');
  ylabel(h1, 'Frequency (Hz)');
  title(c, '10*log10(psd)');
  set(h1, 'YDir', 'normal');
    
  h7 = subplot(4,2,2);
  imagesc(tspec, fspec, snrMap);
  colormap(h7, jet);
  c = colorbar;
  title(h7, '(2) SNR Map');
  xlabel(h7, 'Duration of event (in seconds)');
  ylabel(h7, 'Frequency (Hz)');
  title(c, 'SNR');
  set(h7, 'ydir', 'normal');
  
  h2 = subplot(4,2,3);
  ridges(ridges == min(ridges(:))) = NaN;
  pcolor(tspec, fspec, ridges);
  shading(h2, 'flat');
  colormap(h2, jet);
  c = colorbar;
  title(h2, sprintf('(3) Features with SNR > %d', snrThreshold));
  xlabel(h2, 'Duration of event (in seconds)');
  ylabel(h2, 'Frequency (Hz)');
  title(c, '10*log10(psd)');
  set(h2, 'YDir', 'normal');
    
  h3 = subplot(4,2,4);
  spine(spine == min(spine(:))) = NaN;
  pcolor(tspec, fspec, spine);
  shading(h3, 'flat');
  colormap(h3, jet);
  c = colorbar;
  title(h3, '(4) Detected Spines');
  xlabel(h3, 'Duration of event in seconds');
  ylabel(h3, 'Frequency (Hz)');
  title(c, '10*log10(psd)');
  set(h3, 'YDir', 'normal');
    
  h4 = subplot(4,2,5);
  imagesc(tspec, fspec, tracedElements);
  shading(h4, 'flat');
  colormap(h4, gray);
  colorbar;
  title(h4, '(5) Traces');
  xlabel(h4, 'Duration of event in seconds');
  ylabel(h4, 'Frequency (Hz)');
  set(h4, 'YDir', 'normal');
    
  h5 = subplot(4,2,6);
  imagesc(tspec, fspec, tracedElements);
  shading(h5, 'flat');
  colormap(h5, gray);
  colorbar;
  title(h5, '(6) Traces and Piecewise Fit');
  xlabel(h5, 'Duration of event in seconds');
  ylabel(h5, 'Frequency (Hz)');
  set(h5, 'YDir', 'normal');
  hold on;
  % plot traces over detected spines
  for ind = 1:chorusCount
      segments = chorusElements(ind).piecewiseResults.segments;
      if segments == 1
         t1 = tspec(chorusElements(ind).start.time:chorusElements(ind).stop.time);
         f1 = polyval(chorusElements(ind).piecewiseResults.p1, t1);
         plot(t1, f1, 'r');
      elseif segments == 2
         t1 = tspec(chorusElements(ind).start.time:chorusElements(ind).piecewiseResults.knot1);
         t2 = tspec(chorusElements(ind).piecewiseResults.knot1:chorusElements(ind).stop.time);
         f1 = polyval(chorusElements(ind).piecewiseResults.p1, t1);
         f2 = polyval(chorusElements(ind).piecewiseResults.p2, t2);
         plot(t1, f1, 'r');
         plot(t2, f2, 'r');
      elseif segments == 3
         t1 = tspec(chorusElements(ind).start.time:chorusElements(ind).piecewiseResults.knot1);
         t2 = tspec(chorusElements(ind).piecewiseResults.knot1:chorusElements(ind).piecewiseResults.knot2);
         t3 = tspec(chorusElements(ind).piecewiseResults.knot2:chorusElements(ind).stop.time);
         f1 = polyval(chorusElements(ind).piecewiseResults.p1, t1);
         f2 = polyval(chorusElements(ind).piecewiseResults.p2, t2);
         f3 = polyval(chorusElements(ind).piecewiseResults.p3, t3);
         plot(t1, f1, 'r');
         plot(t2, f2, 'r');
         plot(t3, f3, 'r');
      else
         t1 = tspec(chorusElements(ind).start.time:chorusElements(ind).piecewiseResults.knot1);
         t2 = tspec(chorusElements(ind).piecewiseResults.knot1:chorusElements(ind).piecewiseResults.knot2);
         t3 = tspec(chorusElements(ind).piecewiseResults.knot2:chorusElements(ind).piecewiseResults.knot3);
         t4 = tspec(chorusElements(ind).piecewiseResults.knot3:chorusElements(ind).stop.time);
         f1 = polyval(chorusElements(ind).piecewiseResults.p1, t1);
         f2 = polyval(chorusElements(ind).piecewiseResults.p2, t2);
         f3 = polyval(chorusElements(ind).piecewiseResults.p3, t3);
         f4 = polyval(chorusElements(ind).piecewiseResults.p4, t4);
         plot(t1, f1, 'r');
         plot(t2, f2, 'r');
         plot(t3, f3, 'r');
         plot(t4, f4, 'r');
      end
  end
  hold off;
   
  h8 = subplot(4,2,7);
  imagesc(tspec, fspec, imagefile1);
  shading(h8, 'flat');
  colormap(h8, jet);
  c = colorbar;
  title(h8, '(7) Spectrogram with Traces');
  xlabel(h8, 'Duration of event in seconds');
  ylabel(h8, 'Frequency (Hz)');
  title(c, '10*log10(psd)');
  set(h8, 'YDir', 'normal');
  hold on;
  % plot traces over spectrogram
  for ind = 1:chorusCount
      segments = chorusElements(ind).piecewiseResults.segments;
      if segments == 1
         t1 = tspec(chorusElements(ind).start.time:chorusElements(ind).stop.time);
         f1 = polyval(chorusElements(ind).piecewiseResults.p1, t1);
         plot(t1, f1, 'k');
      elseif segments == 2
         t1 = tspec(chorusElements(ind).start.time:chorusElements(ind).piecewiseResults.knot1);
         t2 = tspec(chorusElements(ind).piecewiseResults.knot1:chorusElements(ind).stop.time);
         f1 = polyval(chorusElements(ind).piecewiseResults.p1, t1);
         f2 = polyval(chorusElements(ind).piecewiseResults.p2, t2);
         plot(t1, f1, 'k');
         plot(t2, f2, 'k');
      elseif segments == 3
         t1 = tspec(chorusElements(ind).start.time:chorusElements(ind).piecewiseResults.knot1);
         t2 = tspec(chorusElements(ind).piecewiseResults.knot1:chorusElements(ind).piecewiseResults.knot2);
         t3 = tspec(chorusElements(ind).piecewiseResults.knot2:chorusElements(ind).stop.time);
         f1 = polyval(chorusElements(ind).piecewiseResults.p1, t1);
         f2 = polyval(chorusElements(ind).piecewiseResults.p2, t2);
         f3 = polyval(chorusElements(ind).piecewiseResults.p3, t3);
         plot(t1, f1, 'k');
         plot(t2, f2, 'k');
         plot(t3, f3, 'k');
      else
         t1 = tspec(chorusElements(ind).start.time:chorusElements(ind).piecewiseResults.knot1);
         t2 = tspec(chorusElements(ind).piecewiseResults.knot1:chorusElements(ind).piecewiseResults.knot2);
         t3 = tspec(chorusElements(ind).piecewiseResults.knot2:chorusElements(ind).piecewiseResults.knot3);
         t4 = tspec(chorusElements(ind).piecewiseResults.knot3:chorusElements(ind).stop.time);
         f1 = polyval(chorusElements(ind).piecewiseResults.p1, t1);
         f2 = polyval(chorusElements(ind).piecewiseResults.p2, t2);
         f3 = polyval(chorusElements(ind).piecewiseResults.p3, t3);
         f4 = polyval(chorusElements(ind).piecewiseResults.p4, t4);
         plot(t1, f1, 'k');
         plot(t2, f2, 'k');
         plot(t3, f3, 'k');
         plot(t4, f4, 'k');
      end
  end
  hold off;
  
  h6 = subplot(4,2,8);
  if chorusCount > 0
      sweeprates = [chorusElements.sweeprate];
  else
      sweeprates = [];
  end
  histogram(sweeprates / 1000, edges);
  axis tight;
  title(h6, '(8) Distribution of Sweeprates');
  xlabel('Sweeprate (KHz / second)');
  ylabel('Total');
    
  % render image maximized to screen
  set(gcf, 'Position', get(0, 'Screensize'));
  
  % save fig
  saveas(summary, figname);
  close all
end

